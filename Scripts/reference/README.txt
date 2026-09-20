Pinned copy of the reference implementation of the Red Blob Games hexagon guide.

Source:   https://www.redblobgames.com/grids/hexagons/codegen/output/lib.py
Fetched:  2026-09-20
License:  CC0 (see the first line of lib.py)
Checksum: lib.py.sha256, verified by Scripts/generate-fixtures.py on every run.

The file is never edited. Updating it is a deliberate change of its own: replace
lib.py, recompute lib.py.sha256, regenerate the fixtures and review the diff.

Scripts/generate-fixtures.py runs this file and writes the reference fixtures of
the test target. It rounds with hex_round() of this very file, replacing one
thing only: the scalar round(). The built-in round() of Python rounds halves to
even, and HexagonKit rounds halves away from zero, as the C++ and Rust ports of
the guide do. The generator verifies the replacement on every point that does
not sit on an exact half: there the untouched reference has to give the same
answer.
