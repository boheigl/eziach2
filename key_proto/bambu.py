#!/usr/bin/env python3
"""Turns plate.3mf and fit_test.3mf into Bambu Studio projects for the Bambu Lab X2D in
PETG, sliced, so they open without the "not from Bambu Lab" note and print as they are.

    python3 bambu.py BAMBU BUILD_DIR [NAME ...]

BAMBU is the Bambu Studio AppImage, or "flatpak" for the Flathub app com.bambulab.BambuStudio
[2026-11-22: the AppImage wants ffmpeg 7 and WebKitGTK, which Ubuntu 24.04 lacks]. The
Flatpak's bambu-studio is run directly with its runtime's loader and libraries, not through
`flatpak run`, which needs user namespaces and a D-Bus session (both missing in containers).

Takes the system profiles out of Bambu Studio (its profiles inherit from one
another; the command line wants them whole), lays the spec's settings over the process
(spec.md, Printing), and has Bambu Studio's command line load each 3MF, keep its layout,
slice it and save it as a project: BUILD_DIR/<NAME>_x2d.3mf for each BUILD_DIR/<NAME>.3mf
(default plate and fit_test; ../discant/Makefile passes holder_test).

The command line leaves the plate's printer_model_id empty (the G-code itself names the
X2D); pressing "Slice plate" in Bambu Studio before sending fills it, as for any project.
"""
import glob, json, os, re, subprocess, sys

MACHINE  = "Bambu Lab X2D 0.4 nozzle"
PROCESS  = "0.20mm Standard @BBL X2D"
FILAMENT = "Bambu PETG HF @BBL X2D 0.4 nozzle"
# the spec's settings over the system process [chosen, spec.md]
PROCESS_SET = {
    "wall_loops": "3",
    "top_shell_layers": "5",
    "bottom_shell_layers": "5",
    "sparse_infill_density": "25%",
    "sparse_infill_pattern": "gyroid",
    "enable_support": "0",
    "seam_position": "aligned",
    "enable_prime_tower": "0",       # one filament
    "curr_bed_type": "Textured PEI Plate",
}


def profiles(root):
    idx = {}
    for kind in ("machine", "process", "filament"):
        for f in glob.glob(os.path.join(root, kind, "**", "*.json"), recursive=True):
            try:
                j = json.load(open(f))
            except ValueError:
                continue
            if "name" in j:
                idx[j["name"]] = j
    return idx


def flat(idx, name):
    """The preset with everything it inherits, its own values last."""
    j = idx[name]
    out = flat(idx, j["inherits"]) if j.get("inherits") else {}
    out.update(j)
    return out


def flatpak_files(ref):
    loc = subprocess.run(["flatpak", "info", "--show-location", ref], capture_output=True, text=True, check=True)
    return os.path.join(loc.stdout.strip(), "files")


def studio(bambu, work):
    """The command that runs Bambu Studio, and its BBL profiles' folder."""
    if bambu == "flatpak":
        app = flatpak_files("com.bambulab.BambuStudio")
        meta = open(os.path.join(os.path.dirname(app), "metadata")).read()
        runtime = flatpak_files(re.search(r"^runtime=(.*)/(.*)/(.*)$", meta, re.M).expand(r"\1//\3"))
        libs = ":".join(os.path.join(d, s) for d in (app, runtime) for s in ("lib", "lib/x86_64-linux-gnu"))
        loader = os.path.join(runtime, "lib", "x86_64-linux-gnu", "ld-linux-x86-64.so.2")
        return [loader, "--library-path", libs, os.path.join(app, "bin", "bambu-studio")], \
            os.path.join(app, "share", "BambuStudio", "profiles", "BBL")
    subprocess.run([bambu, "--appimage-extract", "resources/profiles/BBL/*"], cwd=work,
                   check=True, stdout=subprocess.DEVNULL)
    return [bambu], os.path.join(work, "squashfs-root", "resources", "profiles", "BBL")


def main(bambu, build, names=("plate", "fit_test")):
    work = os.path.join(build, ".bambu")          # the extracted profiles and the whole presets
    os.makedirs(work, exist_ok=True)
    run, bbl = studio(bambu, work)
    idx = profiles(bbl)

    machine = flat(idx, MACHINE)
    process = flat(idx, PROCESS)
    filament = flat(idx, FILAMENT)
    process.update(PROCESS_SET)
    # whole presets, marked as the user's own based on the system ones
    for p, name, base in ((machine, MACHINE, MACHINE), (process, PROCESS + " - " + os.path.basename(build).replace("_", " "), PROCESS),
                          (filament, FILAMENT, FILAMENT)):
        p["name"] = name
        p["from"] = "User" if p is process else "system"
        p.pop("inherits", None)
        if p is process:
            p["inherits"] = base
    paths = {}
    for key, p in (("machine", machine), ("process", process), ("filament", filament)):
        paths[key] = os.path.join(work, key + ".json")
        json.dump(p, open(paths[key], "w"), indent=1)

    for src, dst in ((n + ".3mf", n + "_x2d.3mf") for n in names):
        cmd = run + ["--debug", "2",
               "--load-settings", paths["machine"] + ";" + paths["process"],
               "--load-filaments", paths["filament"],
               "--arrange", "0", "--orient", "0",
               "--slice", "0",
               "--outputdir", build, "--export-3mf", dst,
               os.path.join(build, src)]
        print("  BAMBU   ", os.path.join(build, dst), flush=True)
        r = subprocess.run(cmd, capture_output=True, text=True)
        if r.returncode != 0 or not os.path.exists(os.path.join(build, dst)):
            sys.stderr.write(r.stdout[-3000:] + r.stderr[-3000:])
            sys.exit("Bambu Studio failed on %s (exit %d)" % (src, r.returncode))


if __name__ == "__main__":
    main(sys.argv[1] if sys.argv[1] == "flatpak" else os.path.abspath(sys.argv[1]), os.path.abspath(sys.argv[2] if len(sys.argv) > 2 else "../build/key_proto"),
         sys.argv[3:] or ("plate", "fit_test"))
