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

    for name in ("conversions.json", "rounding.json", "layout.json"):
        path = output / name
        print(f"{name}: {path.stat().st_size} bytes")


if __name__ == "__main__":
    main()
