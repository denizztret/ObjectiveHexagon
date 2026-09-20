#!/usr/bin/env python3
"""Turn the JSON of snippet-extract into Markdown for text-only consumers.

The DocC archive is a web application: a plain fetch of one of its pages returns
an empty shell, and the text lives in a JSON that is not documented for outside
readers. Agents need the examples as ordinary text, so the same snippet-extract
output that feeds DocC also feeds this script.

    python3 Scripts/snippets-to-markdown.py <snippets.symbols.json> <output.md>

The script never runs xcrun itself: it reads a file Scripts/build-docs.sh has
already produced. The output is deterministic - snippets and slices are sorted
by name - and the blank lines left behind by the hidden blocks of a snippet are
collapsed to one.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path


def collapse_blank_lines(lines: list[str]) -> list[str]:
    """Drop leading and trailing blank lines and squeeze runs of them into one."""
    result: list[str] = []
    for line in lines:
        if line.strip() == "":
            if result and result[-1] != "":
                result.append("")
        else:
            result.append(line)
    while result and result[-1] == "":
        result.pop()
    return result


def code_block(lines: list[str]) -> str:
    body = "\n".join(collapse_blank_lines(lines))
    return "```swift\n" + body + "\n```"


def render(graph: dict) -> str:
    module = graph.get("module", {}).get("name", "the package")
    parts = [f"# Snippets of {module}", ""]
    parts.append(
        "Compiled examples from Snippets/, extracted from the same symbol graph "
        "that the documentation is built from."
    )
    for symbol in sorted(graph["symbols"], key=lambda s: s["names"]["title"]):
        title = symbol["names"]["title"]
        snippet = symbol["snippet"]
        parts.append("")
        parts.append(f"## {title}")
        parts.append("")
        parts.append(code_block(snippet["lines"]))
        slices = snippet.get("slices") or {}
        for name in sorted(slices):
            start, end = slices[name]
            parts.append("")
            parts.append(f"### {title}: {name}")
            parts.append("")
            parts.append(code_block(snippet["lines"][start:end]))
    return "\n".join(parts) + "\n"


def main() -> None:
    if len(sys.argv) != 3:
        sys.exit("usage: snippets-to-markdown.py <snippets.symbols.json> <output.md>")
    source = Path(sys.argv[1])
    target = Path(sys.argv[2])
    graph = json.loads(source.read_text(encoding="utf-8"))
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(render(graph), encoding="utf-8")
    print(f"{target}: {len(graph['symbols'])} snippets")


if __name__ == "__main__":
    main()
