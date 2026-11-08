# FreeCAD (freecad.cmd convert.py): the example bass case's STEP to an STL in the same
# coordinates. The snap cannot read hidden folders: copy the STEP into a plain folder
# of $HOME first and set W to it.
#   ../../../shape/OrderOnShape20260107/BassCase - Part BassCase.step -> bass_case_example.stl
import Part, MeshPart, os
W = os.path.expanduser("~/fcwork_bass")
s = Part.Shape(); s.read(W + "/case.step")
MeshPart.meshFromShape(Shape=s, LinearDeflection=0.02, AngularDeflection=0.1).write(W + "/case.stl")
