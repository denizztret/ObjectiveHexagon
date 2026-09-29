#!/usr/bin/env python3
"""Generate the reference fixtures of HexagonKit from the pinned lib.py.

The script runs the pinned reference implementation of the Red Blob Games guide
(Scripts/reference/lib.py, CC0) and writes deterministic JSON files into
Tests/HexagonKitTests/Fixtures/.

Rounding is computed by hex_round() of the pinned reference itself, with one
controlled substitution: the scalar round(). The built-in round() of Python
rounds halves to even, which is one of three incompatible rules used by the
language ports of the guide; HexagonKit follows the C++/Rust rule, halves away
from zero. Everything else -- the two-step structure, the strict comparisons and
the order in which a component is recomputed -- stays the reference code.

The substitution is checked: on every interior point, where no component lands
on an exact half, the result has to agree with the untouched reference.

Usage:
    python3 Scripts/generate-fixtures.py [--output-dir DIR]

Lines follow hex_linedraw() of the reference step by step, with its hex_lerp()
and the same hex_round(), but nudge both ends by (1e-6, 2e-6, -3e-6), the
offset the text of the guide recommends, instead of the (1e-6, 1e-6, -2e-6) of
lib.py; HexagonKit draws its lines that way. The function is checked twice:
with the nudge of lib.py it has to reproduce hex_linedraw() of the untouched
reference on every pair of the hexagon it covers, and with the nudge of the
text it has to pass test_hex_linedraw.

The samples of long lines are picked where a rewrite that is equal in exact
arithmetic -- the parameter as index / N, the interpolation as a + (b - a) * t,
a derived s, or the nudge added after the interpolation -- rounds to another
hex, so the fixture catches an implementation that drifts from this order of
operations. The pseudo-random numbers come from a fixed linear congruential
generator, not from the random module, so every run and every Python version
writes the same file.

The output is byte-for-byte reproducible: no timestamps, sorted keys, fixed
separators, trailing newline.
"""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REFERENCE = ROOT / "Scripts" / "reference" / "lib.py"
CHECKSUM = ROOT / "Scripts" / "reference" / "lib.py.sha256"
DEFAULT_OUTPUT = ROOT / "Tests" / "HexagonKitTests" / "Fixtures"

CONVERSION_RANGE = 50
ROUNDING_DENOMINATOR = 12
ROUNDING_RANGE = 3
LAYOUT_RANGE = 15
LINE_RANGE = 6
LINE_NUDGE = (1e-06, 2e-06, -3e-06)
REFERENCE_LINE_NUDGE = (1e-06, 1e-06, -2e-06)
LINE_SENSITIVE_SAMPLES = 400
LINE_RANDOM_SAMPLES = 100
LINE_SEED = 20260929


def load_reference() -> tuple[object, str]:
    """Import the pinned lib.py and verify its checksum."""
    digest = hashlib.sha256(REFERENCE.read_bytes()).hexdigest()
    expected = CHECKSUM.read_text().split()[0]
    if digest != expected:
        sys.exit(
            f"checksum mismatch for {REFERENCE}:\n  expected {expected}\n  actual   {digest}"
        )
    spec = importlib.util.spec_from_file_location("hexagonkit_reference", REFERENCE)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module, digest


def round_half_away_from_zero(value: float) -> int:
    """Round to the nearest integer, halves away from zero.

    Mirrors Double.rounded(.toNearestOrAwayFromZero) of Swift exactly.
    """
    floor = math.floor(value)
    fraction = value - floor
    if fraction > 0.5:
        return int(floor) + 1
    if fraction < 0.5:
        return int(floor)
    return int(floor) + 1 if value > 0 else int(floor)


_MISSING = object()


def hex_round(lib, q: float, r: float, s: float) -> tuple[int, int, int]:
    """Run hex_round() of the pinned reference with the HexagonKit rule for halves.

    hex_round() of lib.py calls the bare name round(). Binding that name in the
    module of the reference makes it resolve to the module global before the
    built-in, so only the scalar rounding changes; the two-step algorithm, the
    strict comparisons and the tie order stay exactly as the reference wrote
    them. The binding is removed again right after the call.
    """
    previous = getattr(lib, "round", _MISSING)
    lib.round = round_half_away_from_zero
    try:
        rounded = lib.hex_round(lib.Hex(q, r, s))
    finally:
        if previous is _MISSING:
            del lib.round
        else:
            lib.round = previous
    return rounded.q, rounded.r, rounded.s


def reference_hex_round(lib, q: float, r: float, s: float) -> tuple[int, int, int]:
    """Run hex_round() of the pinned reference untouched, halves to even."""
    rounded = lib.hex_round(lib.Hex(q, r, s))
    return rounded.q, rounded.r, rounded.s


def is_exact_half(value: float) -> bool:
    doubled = value * 2.0
    return doubled == math.floor(doubled) and int(doubled) % 2 != 0


def write_json(path: Path, payload: dict) -> None:
    text = json.dumps(payload, sort_keys=True, separators=(",", ":"), allow_nan=False)
    path.write_text(text + "\n", encoding="utf-8")


def build_conversions(lib, digest: str) -> dict:
    rows = []
    for q in range(-CONVERSION_RANGE, CONVERSION_RANGE + 1):
        for r in range(-CONVERSION_RANGE, CONVERSION_RANGE + 1):
            cube = lib.Hex(q, r, -q - r)
            odd_r = lib.roffset_from_cube(lib.ODD, cube)
            even_r = lib.roffset_from_cube(lib.EVEN, cube)
            odd_q = lib.qoffset_from_cube(lib.ODD, cube)
            even_q = lib.qoffset_from_cube(lib.EVEN, cube)
            double_width = lib.rdoubled_from_cube(cube)
            double_height = lib.qdoubled_from_cube(cube)
            rows.append(
                [
                    q,
                    r,
                    odd_r.col,
                    odd_r.row,
                    even_r.col,
                    even_r.row,
                    odd_q.col,
                    odd_q.row,
                    even_q.col,
                    even_q.row,
                    double_width.col,
                    double_width.row,
                    double_height.col,
                    double_height.row,
                ]
            )
    return {
        "columns": [
            "q",
            "r",
            "oddR.column",
            "oddR.row",
            "evenR.column",
            "evenR.row",
            "oddQ.column",
            "oddQ.row",
            "evenQ.column",
            "evenQ.row",
            "doubleWidth.column",
            "doubleWidth.row",
            "doubleHeight.column",
            "doubleHeight.row",
        ],
        "range": CONVERSION_RANGE,
        "rows": rows,
        "source": "Scripts/reference/lib.py",
        "sourceSHA256": digest,
    }


def build_rounding(lib, digest: str) -> dict:
    interior = []
    boundary = []
    limit = ROUNDING_RANGE * ROUNDING_DENOMINATOR
    for qi in range(-limit, limit + 1):
        for ri in range(-limit, limit + 1):
            q = qi / ROUNDING_DENOMINATOR
            r = ri / ROUNDING_DENOMINATOR
            s = -q - r
            rounded = hex_round(lib, q, r, s)
            row = [qi, ri, rounded[0], rounded[1]]
            if is_exact_half(q) or is_exact_half(r) or is_exact_half(s):
                boundary.append(row)
            else:
                untouched = reference_hex_round(lib, q, r, s)
                if untouched != rounded:
                    sys.exit(
                        "the rule for halves changed an interior point: "
                        f"({q}, {r}, {s}) -> {rounded}, reference {untouched}"
                    )
                interior.append(row)
    return {
        "boundary": boundary,
        "columns": ["qNumerator", "rNumerator", "hex.q", "hex.r"],
        "denominator": ROUNDING_DENOMINATOR,
        "interior": interior,
        "range": ROUNDING_RANGE,
        "rule": "nearest, halves away from zero",
        "source": "Scripts/reference/lib.py",
        "sourceSHA256": digest,
    }


def build_layout(lib, digest: str) -> dict:
    layouts = [
        ("pointy", 10.0, 10.0, 0.0, 0.0),
        ("flat", 10.0, 10.0, 0.0, 0.0),
        ("pointy", 10.0, 15.0, 35.0, 71.0),
        ("flat", 10.0, 15.0, 35.0, 71.0),
        ("pointy", 7.5, 4.25, -120.5, 33.25),
        ("flat", 7.5, 4.25, -120.5, 33.25),
    ]
    cases = []
    for orientation, size_x, size_y, origin_x, origin_y in layouts:
        matrix = lib.layout_pointy if orientation == "pointy" else lib.layout_flat
        layout = lib.Layout(matrix, lib.Point(size_x, size_y), lib.Point(origin_x, origin_y))
        hexes = []
        centers = []
        for q in range(-LAYOUT_RANGE, LAYOUT_RANGE + 1):
            for r in range(-LAYOUT_RANGE, LAYOUT_RANGE + 1):
                cube = lib.Hex(q, r, -q - r)
                point = lib.hex_to_pixel(layout, cube)
                fractional = lib.pixel_to_hex_fractional(layout, point)
                back = hex_round(lib, fractional.q, fractional.r, fractional.s)
                if back != (q, r, -q - r):
                    sys.exit(f"layout round trip failed for {orientation} {q} {r}: {back}")
                hexes.append([q, r])
                centers.append([point.x, point.y])
        cases.append(
            {
                "centers": centers,
                "hexes": hexes,
                "orientation": orientation,
                "originX": origin_x,
                "originY": origin_y,
                "sizeX": size_x,
                "sizeY": size_y,
            }
        )
    return {
        "cases": cases,
        "range": LAYOUT_RANGE,
        "source": "Scripts/reference/lib.py",
        "sourceSHA256": digest,
    }


def hexagon(lib, radius: int) -> list:
    """The hexes within radius of the origin, row by row as HexShape lists them."""
    return [
        lib.Hex(q, r, -q - r)
        for r in range(-radius, radius + 1)
        for q in range(max(-radius, -r - radius), min(radius, -r + radius) + 1)
    ]


def line_hex(lib, a, b, index: int, nudge=LINE_NUDGE) -> tuple[int, int, int]:
    """Sample `index` of the line from a to b: hex_linedraw() of the reference,
    one step of its loop, with the given nudge and the HexagonKit rule for halves."""
    n = lib.hex_distance(a, b)
    a_nudge = lib.Hex(a.q + nudge[0], a.r + nudge[1], a.s + nudge[2])
    b_nudge = lib.Hex(b.q + nudge[0], b.r + nudge[1], b.s + nudge[2])
    step = 1.0 / max(n, 1)
    sample = lib.hex_lerp(a_nudge, b_nudge, step * index)
    return hex_round(lib, sample.q, sample.r, sample.s)


def line(lib, a, b, nudge=LINE_NUDGE) -> list:
    return [line_hex(lib, a, b, i, nudge) for i in range(lib.hex_distance(a, b) + 1)]


def rewritten_line_hexes(lib, a, b, index: int) -> list:
    """Sample `index` computed by four rewrites that are equal in exact arithmetic."""
    n = max(lib.hex_distance(a, b), 1)
    ends = [(float(h.q), float(h.r), float(h.s)) for h in (a, b)]
    start = [ends[0][k] + LINE_NUDGE[k] for k in range(3)]
    end = [ends[1][k] + LINE_NUDGE[k] for k in range(3)]
    t = 1.0 / n * index
    by_division = [start[k] * (1.0 - index / n) + end[k] * (index / n) for k in range(3)]
    by_difference = [start[k] + (end[k] - start[k]) * t for k in range(3)]
    q, r = (start[k] * (1.0 - t) + end[k] * t for k in range(2))
    nudged_after = [ends[0][k] * (1.0 - t) + ends[1][k] * t + LINE_NUDGE[k] for k in range(3)]
    return [
        hex_round(lib, *by_division),
        hex_round(lib, *by_difference),
        hex_round(lib, q, r, -q - r),
        hex_round(lib, *nudged_after),
    ]


class Congruential:
    """The 64-bit linear congruential generator of Knuth's MMIX."""

    def __init__(self, seed: int) -> None:
        self.state = seed

    def below(self, bound: int) -> int:
        self.state = (self.state * 6364136223846793005 + 1442695040888963407) % 2**64
        return (self.state >> 16) % bound

    def between(self, low: int, high: int) -> int:
        return low + self.below(high - low + 1)


def random_hex(lib, numbers: Congruential):
    """A hex anywhere in the supported coordinate range."""
    limit = 2**30 - 1
    while True:
        q, r = numbers.between(-limit, limit), numbers.between(-limit, limit)
        if abs(q + r) <= limit:
            return lib.Hex(q, r, -q - r)


def sensitive_line_samples(lib, numbers: Congruential) -> tuple[list, list]:
    """Samples of long lines that a rewritten order of operations rounds elsewhere.

    One component of these lines changes by a few units over millions of steps,
    so its samples crawl across the edge between two hexes, and some of them land
    where the last bits of the arithmetic decide the hex.
    """
    limit = 2**30 - 1
    rows = []
    caught = [0, 0, 0, 0]
    while len(rows) < LINE_SENSITIVE_SAMPLES:
        steps = numbers.between(10**6, 2**30)
        drift = numbers.between(1, 5)
        dq, dr = [(steps, -drift), (-steps, drift), (drift, -steps), (-drift, steps)][numbers.below(4)]
        a = random_hex(lib, numbers)
        b = lib.Hex(a.q + dq, a.r + dr, a.s - dq - dr)
        if max(abs(b.q), abs(b.r), abs(b.s)) > limit:
            continue
        n = lib.hex_distance(a, b)
        for low, high in ((a.q, b.q), (a.r, b.r), (a.s, b.s)):
            if low == high or abs(high - low) > 5:
                continue
            for k in range(min(low, high), max(low, high)):
                middle = int((k + 0.5 - low) / (high - low) * n)
                window = int(4e-6 * n / abs(high - low)) + 2
                stride = max(1, window // 400)
                for index in range(max(0, middle - window), min(n, middle + window) + 1, stride):
                    expected = line_hex(lib, a, b, index)
                    rewritten = rewritten_line_hexes(lib, a, b, index)
                    if any(h != expected for h in rewritten):
                        rows.append([a.q, a.r, b.q, b.r, index, expected[0], expected[1]])
                        for i, h in enumerate(rewritten):
                            caught[i] += h != expected
                        break
    return rows[:LINE_SENSITIVE_SAMPLES], caught


def build_lines(lib, digest: str) -> dict:
    cells = hexagon(lib, LINE_RANGE)
    # The function against the reference itself: with the nudge of lib.py it must
    # draw exactly what hex_linedraw() draws. No sample of these lines lands on an
    # exact half, so the rule for halves makes no difference here.
    for a in cells:
        for b in cells:
            ours = line(lib, a, b, REFERENCE_LINE_NUDGE)
            reference = [(h.q, h.r, h.s) for h in lib.hex_linedraw(a, b)]
            if ours != reference:
                sys.exit(f"the line function drifted from hex_linedraw at {a} -> {b}")
    expected = [(0, 0, 0), (0, -1, 1), (0, -2, 2), (1, -3, 2), (1, -4, 3), (1, -5, 4)]
    if line(lib, lib.Hex(0, 0, 0), lib.Hex(1, -5, 4)) != expected:
        sys.exit("the line with the nudge of the text fails test_hex_linedraw")

    lines = []
    for a in cells:
        for b in cells:
            ours = line(lib, a, b)
            if ours != line(lib, a, b, REFERENCE_LINE_NUDGE):
                lines.append([a.q, a.r, b.q, b.r] + [c for h in ours for c in h[:2]])

    numbers = Congruential(LINE_SEED)
    samples, caught = sensitive_line_samples(lib, numbers)
    if min(caught) < 20:
        sys.exit(f"too few samples catch some rewrite of the line: {caught}")
    while len(samples) < LINE_SENSITIVE_SAMPLES + LINE_RANDOM_SAMPLES:
        a, b = random_hex(lib, numbers), random_hex(lib, numbers)
        index = numbers.between(0, lib.hex_distance(a, b))
        hex = line_hex(lib, a, b, index)
        samples.append([a.q, a.r, b.q, b.r, index, hex[0], hex[1]])
    return {
        "lineColumns": ["from.q", "from.r", "to.q", "to.r", "then q and r of every hex"],
        "lines": lines,
        "nudge": list(LINE_NUDGE),
        "range": LINE_RANGE,
        "sampleColumns": ["from.q", "from.r", "to.q", "to.r", "index", "hex.q", "hex.r"],
        "samples": samples,
        "sensitiveSamples": LINE_SENSITIVE_SAMPLES,
        "source": "Scripts/reference/lib.py",
        "sourceSHA256": digest,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate the HexagonKit reference fixtures.")
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT)
    arguments = parser.parse_args()
    output = arguments.output_dir
    output.mkdir(parents=True, exist_ok=True)

    lib, digest = load_reference()
    write_json(output / "conversions.json", build_conversions(lib, digest))
    write_json(output / "rounding.json", build_rounding(lib, digest))
    write_json(output / "layout.json", build_layout(lib, digest))
    write_json(output / "lines.json", build_lines(lib, digest))

    for name in ("conversions.json", "rounding.json", "layout.json", "lines.json"):
        path = output / name
        print(f"{name}: {path.stat().st_size} bytes")


if __name__ == "__main__":
    main()
