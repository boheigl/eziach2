#!/usr/bin/env python3
"""Puts the discant's printed parts on the Bambu Lab X2D's plate as 3MF files any slicer
opens, with ../key_proto/plate.py's writer: each part lying as printed (print.scad).

    python3 plate.py BUILD_DIR      reads BUILD_DIR/print_<part>.stl, writes
                                    BUILD_DIR/holder_test.3mf  the gauge's holder corner and
                                                               the bass's inner holders with
                                                               their latches (lock, detent),
                                                               to try the plate's fits first
"""
import os, sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "key_proto"))
from plate import write_3mf     # noqa: E402

HOLDER_TEST = [("holder_test", 1, [(128, 140)]),
               ("inner_lock", 1, [(108, 110)]),       # the playing position's latch
               ("inner_detent", 1, [(148, 110)])]     # the stored position's

if __name__ == "__main__":
    build = sys.argv[1] if len(sys.argv) > 1 else "../build/discant"
    write_3mf(os.path.join(build, "holder_test.3mf"), HOLDER_TEST, build, "Discant holder test")
