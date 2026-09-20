# Generated code -- CC0 -- No Rights Reserved -- http://www.redblobgames.com/grids/hexagons/

from __future__ import division
from __future__ import print_function
import collections
import math



Point = collections.namedtuple("Point", ["x", "y"])




_Hex = collections.namedtuple("Hex", ["q", "r", "s"])
def Hex(q, r, s):
    assert not (round(q + r + s) != 0), "q + r + s must be 0"
    return _Hex(q, r, s)

def hex_add(a, b):
    return Hex(a.q + b.q, a.r + b.r, a.s + b.s)

def hex_subtract(a, b):
    return Hex(a.q - b.q, a.r - b.r, a.s - b.s)

def hex_scale(a, k):
    return Hex(a.q * k, a.r * k, a.s * k)

def hex_rotate_left(a):
    return Hex(-a.s, -a.q, -a.r)

def hex_rotate_right(a):
    return Hex(-a.r, -a.s, -a.q)

hex_directions = [Hex(1, 0, -1), Hex(1, -1, 0), Hex(0, -1, 1), Hex(-1, 0, 1), Hex(-1, 1, 0), Hex(0, 1, -1)]
def hex_direction(direction):
    return hex_directions[direction]

def hex_neighbor(hex, direction):
    return hex_add(hex, hex_direction(direction))

hex_diagonals = [Hex(2, -1, -1), Hex(1, -2, 1), Hex(-1, -1, 2), Hex(-2, 1, 1), Hex(-1, 2, -1), Hex(1, 1, -2)]
def hex_diagonal_neighbor(hex, direction):
    return hex_add(hex, hex_diagonals[direction])

def hex_length(hex):
    return (abs(hex.q) + abs(hex.r) + abs(hex.s)) // 2

def hex_distance(a, b):
    return hex_length(hex_subtract(a, b))

def hex_round(h):
    qi = int(round(h.q))
    ri = int(round(h.r))
    si = int(round(h.s))
    q_diff = abs(qi - h.q)
    r_diff = abs(ri - h.r)
    s_diff = abs(si - h.s)
    if q_diff > r_diff and q_diff > s_diff:
        qi = -ri - si
    else:
        if r_diff > s_diff:
            ri = -qi - si
        else:
            si = -qi - ri
    return Hex(qi, ri, si)

def hex_lerp(a, b, t):
    return Hex(a.q * (1.0 - t) + b.q * t, a.r * (1.0 - t) + b.r * t, a.s * (1.0 - t) + b.s * t)

def hex_linedraw(a, b):
    N = hex_distance(a, b)
    a_nudge = Hex(a.q + 1e-06, a.r + 1e-06, a.s - 2e-06)
    b_nudge = Hex(b.q + 1e-06, b.r + 1e-06, b.s - 2e-06)
    results = []
    step = 1.0 / max(N, 1)
    for i in range(0, N + 1):
        results.append(hex_round(hex_lerp(a_nudge, b_nudge, step * i)))
    return results




OffsetCoord = collections.namedtuple("OffsetCoord", ["col", "row"])

EVEN = 1
ODD = -1
def qoffset_from_cube(offset, h):
    parity = h.q & 1
    col = h.q
    row = h.r + (h.q + offset * parity) // 2
    if offset != EVEN and offset != ODD:
        raise ValueError("offset must be EVEN (+1) or ODD (-1)")
    return OffsetCoord(col, row)

def qoffset_to_cube(offset, h):
    parity = h.col & 1
    q = h.col
    r = h.row - (h.col + offset * parity) // 2
    s = -q - r
    if offset != EVEN and offset != ODD:
        raise ValueError("offset must be EVEN (+1) or ODD (-1)")
    return Hex(q, r, s)

def roffset_from_cube(offset, h):
    parity = h.r & 1
    col = h.q + (h.r + offset * parity) // 2
    row = h.r
    if offset != EVEN and offset != ODD:
        raise ValueError("offset must be EVEN (+1) or ODD (-1)")
    return OffsetCoord(col, row)

def roffset_to_cube(offset, h):
    parity = h.row & 1
    q = h.col - (h.row + offset * parity) // 2
    r = h.row
    s = -q - r
    if offset != EVEN and offset != ODD:
        raise ValueError("offset must be EVEN (+1) or ODD (-1)")
    return Hex(q, r, s)

def qoffset_from_qdoubled(offset, h):
    parity = h.col & 1
    return OffsetCoord(h.col, (h.row + offset * parity) // 2)

def qoffset_to_qdoubled(offset, h):
    parity = h.col & 1
    return DoubledCoord(h.col, 2 * h.row - offset * parity)

def roffset_from_rdoubled(offset, h):
    parity = h.row & 1
    return OffsetCoord((h.col + offset * parity) // 2, h.row)

def roffset_to_rdoubled(offset, h):
    parity = h.row & 1
    return DoubledCoord(2 * h.col - offset * parity, h.row)




DoubledCoord = collections.namedtuple("DoubledCoord", ["col", "row"])

def qdoubled_from_cube(h):
    col = h.q
    row = 2 * h.r + h.q
    return DoubledCoord(col, row)

def qdoubled_to_cube(h):
    q = h.col
    r = (h.row - h.col) // 2
    s = -q - r
    return Hex(q, r, s)

def rdoubled_from_cube(h):
    col = 2 * h.q + h.r
    row = h.r
    return DoubledCoord(col, row)

def rdoubled_to_cube(h):
    q = (h.col - h.row) // 2
    r = h.row
    s = -q - r
    return Hex(q, r, s)




Orientation = collections.namedtuple("Orientation", ["f0", "f1", "f2", "f3", "b0", "b1", "b2", "b3", "start_angle"])




Layout = collections.namedtuple("Layout", ["orientation", "size", "origin"])

layout_pointy = Orientation(math.sqrt(3.0), math.sqrt(3.0) / 2.0, 0.0, 3.0 / 2.0, math.sqrt(3.0) / 3.0, -1.0 / 3.0, 0.0, 2.0 / 3.0, 0.5)
layout_flat = Orientation(3.0 / 2.0, 0.0, math.sqrt(3.0) / 2.0, math.sqrt(3.0), 2.0 / 3.0, 0.0, -1.0 / 3.0, math.sqrt(3.0) / 3.0, 0.0)
def hex_to_pixel(layout, h):
    M = layout.orientation
    size = layout.size
    origin = layout.origin
    x = (M.f0 * h.q + M.f1 * h.r) * size.x
    y = (M.f2 * h.q + M.f3 * h.r) * size.y
    return Point(x + origin.x, y + origin.y)

def pixel_to_hex_fractional(layout, p):
    M = layout.orientation
    size = layout.size
    origin = layout.origin
    pt = Point((p.x - origin.x) / size.x, (p.y - origin.y) / size.y)
    q = M.b0 * pt.x + M.b1 * pt.y
    r = M.b2 * pt.x + M.b3 * pt.y
    return Hex(q, r, -q - r)

def pixel_to_hex_rounded(layout, p):
    return hex_round(pixel_to_hex_fractional(layout, p))

def hex_corner_offset(layout, corner):
    M = layout.orientation
    size = layout.size
    angle = 2.0 * math.pi * (M.start_angle - corner) / 6.0
    return Point(size.x * math.cos(angle), size.y * math.sin(angle))

def polygon_corners(layout, h):
    corners = []
    center = hex_to_pixel(layout, h)
    for i in range(0, 6):
        offset = hex_corner_offset(layout, i)
        corners.append(Point(center.x + offset.x, center.y + offset.y))
    return corners




# Tests

def complain(name):
    print("FAIL {0}".format(name))

def equal_hex(name, a, b):
    if not (a.q == b.q and a.s == b.s and a.r == b.r):
        complain(name)

def equal_offsetcoord(name, a, b):
    if not (a.col == b.col and a.row == b.row):
        complain(name)

def equal_doubledcoord(name, a, b):
    if not (a.col == b.col and a.row == b.row):
        complain(name)

def equal_int(name, a, b):
    if not (a == b):
        complain(name)

def equal_hex_array(name, a, b):
    equal_int(name, len(a), len(b))
    for i in range(0, len(a)):
        equal_hex(name, a[i], b[i])

def test_hex_arithmetic():
    equal_hex("hex_add", Hex(4, -10, 6), hex_add(Hex(1, -3, 2), Hex(3, -7, 4)))
    equal_hex("hex_subtract", Hex(-2, 4, -2), hex_subtract(Hex(1, -3, 2), Hex(3, -7, 4)))

def test_hex_direction():
    equal_hex("hex_direction", Hex(0, -1, 1), hex_direction(2))

def test_hex_neighbor():
    equal_hex("hex_neighbor", Hex(1, -3, 2), hex_neighbor(Hex(1, -2, 1), 2))

def test_hex_diagonal():
    equal_hex("hex_diagonal", Hex(-1, -1, 2), hex_diagonal_neighbor(Hex(1, -2, 1), 3))

def test_hex_distance():
    equal_int("hex_distance", 7, hex_distance(Hex(3, -7, 4), Hex(0, 0, 0)))

def test_hex_rotate_right():
    equal_hex("hex_rotate_right", hex_rotate_right(Hex(1, -3, 2)), Hex(3, -2, -1))

def test_hex_rotate_left():
    equal_hex("hex_rotate_left", hex_rotate_left(Hex(1, -3, 2)), Hex(-2, -1, 3))

def test_hex_round():
    a = Hex(0.0, 0.0, 0.0)
    b = Hex(1.0, -1.0, 0.0)
    c = Hex(0.0, -1.0, 1.0)
    equal_hex("hex_round 1", Hex(5, -10, 5), hex_round(hex_lerp(Hex(0.0, 0.0, 0.0), Hex(10.0, -20.0, 10.0), 0.5)))
    equal_hex("hex_round 2", hex_round(a), hex_round(hex_lerp(a, b, 0.499)))
    equal_hex("hex_round 3", hex_round(b), hex_round(hex_lerp(a, b, 0.501)))
    equal_hex("hex_round 4", hex_round(a), hex_round(Hex(a.q * 0.4 + b.q * 0.3 + c.q * 0.3, a.r * 0.4 + b.r * 0.3 + c.r * 0.3, a.s * 0.4 + b.s * 0.3 + c.s * 0.3)))
    equal_hex("hex_round 5", hex_round(c), hex_round(Hex(a.q * 0.3 + b.q * 0.3 + c.q * 0.4, a.r * 0.3 + b.r * 0.3 + c.r * 0.4, a.s * 0.3 + b.s * 0.3 + c.s * 0.4)))

def test_hex_linedraw():
    equal_hex_array("hex_linedraw", [Hex(0, 0, 0), Hex(0, -1, 1), Hex(0, -2, 2), Hex(1, -3, 2), Hex(1, -4, 3), Hex(1, -5, 4)], hex_linedraw(Hex(0, 0, 0), Hex(1, -5, 4)))

def test_layout():
    h = Hex(3, 4, -7)
    flat = Layout(layout_flat, Point(10.0, 15.0), Point(35.0, 71.0))
    equal_hex("layout", h, pixel_to_hex_rounded(flat, hex_to_pixel(flat, h)))
    pointy = Layout(layout_pointy, Point(10.0, 15.0), Point(35.0, 71.0))
    equal_hex("layout", h, pixel_to_hex_rounded(pointy, hex_to_pixel(pointy, h)))

def test_offset_roundtrip():
    for q in range(-2, 3):
        for r in range(-2, 3):
            cube = Hex(q, r, -q - r)
            equal_hex("conversion_roundtrip odd-q", cube, qoffset_to_cube(ODD, qoffset_from_cube(ODD, cube)))
            equal_hex("conversion_roundtrip odd-r", cube, roffset_to_cube(ODD, roffset_from_cube(ODD, cube)))
            equal_hex("conversion_roundtrip even-q", cube, qoffset_to_cube(EVEN, qoffset_from_cube(EVEN, cube)))
            equal_hex("conversion_roundtrip even-r", cube, roffset_to_cube(EVEN, roffset_from_cube(EVEN, cube)))
    for col in range(-2, 3):
        for row in range(-2, 3):
            offset = OffsetCoord(col, row)
            equal_offsetcoord("conversion_roundtrip odd-q", offset, qoffset_from_cube(ODD, qoffset_to_cube(ODD, offset)))
            equal_offsetcoord("conversion_roundtrip odd-r", offset, roffset_from_cube(ODD, roffset_to_cube(ODD, offset)))
            equal_offsetcoord("conversion_roundtrip even-q", offset, qoffset_from_cube(EVEN, qoffset_to_cube(EVEN, offset)))
            equal_offsetcoord("conversion_roundtrip even-r", offset, roffset_from_cube(EVEN, roffset_to_cube(EVEN, offset)))

def test_offset_from_cube():
    equal_offsetcoord("offset_from_cube odd-r", OffsetCoord(-2, 2), roffset_from_cube(ODD, Hex(-3, 2, 1)))
    equal_offsetcoord("offset_from_cube odd-r", OffsetCoord(1, -1), roffset_from_cube(ODD, Hex(2, -1, -1)))
    equal_offsetcoord("offset_from_cube even-r", OffsetCoord(-2, 2), roffset_from_cube(EVEN, Hex(-3, 2, 1)))
    equal_offsetcoord("offset_from_cube even-r", OffsetCoord(2, -1), roffset_from_cube(EVEN, Hex(2, -1, -1)))
    equal_offsetcoord("offset_from_cube odd-q", OffsetCoord(-2, 2), qoffset_from_cube(ODD, Hex(-2, 3, -1)))
    equal_offsetcoord("offset_from_cube odd-q", OffsetCoord(-1, -2), qoffset_from_cube(ODD, Hex(-1, -1, 2)))
    equal_offsetcoord("offset_from_cube even-q", OffsetCoord(-2, 2), qoffset_from_cube(EVEN, Hex(-2, 3, -1)))
    equal_offsetcoord("offset_from_cube even-q", OffsetCoord(-1, -1), qoffset_from_cube(EVEN, Hex(-1, -1, 2)))

def test_offset_to_cube():
    equal_hex("offset_to_cube odd-r", Hex(-3, 2, 1), roffset_to_cube(ODD, OffsetCoord(-2, 2)))
    equal_hex("offset_to_cube odd-r", Hex(2, -1, -1), roffset_to_cube(ODD, OffsetCoord(1, -1)))
    equal_hex("offset_to_cube even-r", Hex(-3, 2, 1), roffset_to_cube(EVEN, OffsetCoord(-2, 2)))
    equal_hex("offset_to_cube even-r", Hex(2, -1, -1), roffset_to_cube(EVEN, OffsetCoord(2, -1)))
    equal_hex("offset_to_cube odd-q", Hex(-2, 3, -1), qoffset_to_cube(ODD, OffsetCoord(-2, 2)))
    equal_hex("offset_to_cube odd-q", Hex(-1, -1, 2), qoffset_to_cube(ODD, OffsetCoord(-1, -2)))
    equal_hex("offset_to_cube even-q", Hex(-2, 3, -1), qoffset_to_cube(EVEN, OffsetCoord(-2, 2)))
    equal_hex("offset_to_cube even-q", Hex(-1, -1, 2), qoffset_to_cube(EVEN, OffsetCoord(-1, -1)))

def test_offset_to_doubled():
    for col in range(-2, 3):
        for row in range(-2, 3):
            offset = OffsetCoord(col, row)
            equal_doubledcoord("offset_to_doubled loop odd-q", qdoubled_from_cube(qoffset_to_cube(ODD, offset)), qoffset_to_qdoubled(ODD, offset))
            equal_doubledcoord("offset_to_doubled loop even-q", qdoubled_from_cube(qoffset_to_cube(EVEN, offset)), qoffset_to_qdoubled(EVEN, offset))
            equal_doubledcoord("offset_to_doubled loop odd-r", rdoubled_from_cube(roffset_to_cube(ODD, offset)), roffset_to_rdoubled(ODD, offset))
            equal_doubledcoord("offset_to_doubled loop even-r", rdoubled_from_cube(roffset_to_cube(EVEN, offset)), roffset_to_rdoubled(EVEN, offset))
            qdoubled = DoubledCoord(col * 2 + (row & 1), row)
            equal_offsetcoord("offset_from_doubled loop odd-q", qoffset_from_cube(ODD, qdoubled_to_cube(qdoubled)), qoffset_from_qdoubled(ODD, qdoubled))
            equal_offsetcoord("offset_from_doubled loop even-q", qoffset_from_cube(EVEN, qdoubled_to_cube(qdoubled)), qoffset_from_qdoubled(EVEN, qdoubled))
            rdoubled = DoubledCoord(col, row * 2 + (col & 1))
            equal_offsetcoord("offset_from_doubled loop odd-r", roffset_from_cube(ODD, rdoubled_to_cube(rdoubled)), roffset_from_rdoubled(ODD, rdoubled))
            equal_offsetcoord("offset_from_doubled loop even-r", roffset_from_cube(EVEN, rdoubled_to_cube(rdoubled)), roffset_from_rdoubled(EVEN, rdoubled))

def test_offset_from_doubled():
    pass

def test_doubled_roundtrip():
    for q in range(-2, 3):
        for r in range(-2, 3):
            cube = Hex(q, r, -q - r)
            equal_hex("conversion_roundtrip doubled-q", cube, qdoubled_to_cube(qdoubled_from_cube(cube)))
            equal_hex("conversion_roundtrip doubled-r", cube, rdoubled_to_cube(rdoubled_from_cube(cube)))
    for col in range(-2, 3):
        for row in range(-2, 3):
            qdoubled = DoubledCoord(col * 2 + (row & 1), row)
            equal_doubledcoord("conversion_roundtrip doubled-q", qdoubled, qdoubled_from_cube(qdoubled_to_cube(qdoubled)))
            rdoubled = DoubledCoord(col, row * 2 + (col & 1))
            equal_doubledcoord("conversion_roundtrip doubled-r", rdoubled, rdoubled_from_cube(rdoubled_to_cube(rdoubled)))

def test_doubled_from_cube():
    equal_doubledcoord("doubled_from_cube doubled-q", DoubledCoord(1, 5), qdoubled_from_cube(Hex(1, 2, -3)))
    equal_doubledcoord("doubled_from_cube doubled-r", DoubledCoord(4, 2), rdoubled_from_cube(Hex(1, 2, -3)))

def test_doubled_to_cube():
    equal_hex("doubled_to_cube doubled-q", Hex(1, 2, -3), qdoubled_to_cube(DoubledCoord(1, 5)))
    equal_hex("doubled_to_cube doubled-r", Hex(1, 2, -3), rdoubled_to_cube(DoubledCoord(4, 2)))

def test_all():
    test_hex_arithmetic()
    test_hex_direction()
    test_hex_neighbor()
    test_hex_diagonal()
    test_hex_distance()
    test_hex_rotate_right()
    test_hex_rotate_left()
    test_hex_round()
    test_hex_linedraw()
    test_layout()
    test_offset_roundtrip()
    test_offset_from_cube()
    test_offset_to_cube()
    test_offset_to_doubled()
    test_offset_from_doubled()
    test_doubled_roundtrip()
    test_doubled_from_cube()
    test_doubled_to_cube()



if __name__ == '__main__': test_all()

