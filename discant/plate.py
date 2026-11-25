#!/usr/bin/env python3
"""Puts the discant's printed parts on the Bambu Lab X2D's plate as 3MF files any slicer
opens, with ../key_proto/plate.py's writer: each part lying as printed (print.scad).

    python3 plate.py BUILD_DIR      reads BUILD_DIR/print_<part>.stl, writes
                                    BUILD_DIR/holder_test.3mf  the gauge's holder corner and
                                                               the bass's inner holders (the
                                                               cam's, the detent's) with one
                                                               cam lever, to try the fits first
"""
import os, sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "key_proto"))
from plate import write_3mf     # noqa: E402

HOLDER_TEST = [("holder_test", 1, [(128, 140)]),
               ("inner_cam", 1, [(108, 110)]),        # the playing position's, with the cam's shoe
               ("inner_detent", 1, [(148, 110)]),     # the stored position's
               ("lever_one", 1, [(108, 85)])]         # one cam with its arm, for inner_cam

if __name__ == "__main__":
    build = sys.argv[1] if len(sys.argv) > 1 else "../build/discant"
    write_3mf(os.path.join(build, "holder_test.3mf"), HOLDER_TEST, build, "Discant holder test")
