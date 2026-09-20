#!/usr/bin/env bash
# Build the DocC archive of HexagonKit, with the examples of Snippets/ inlined.
#
#   bash Scripts/build-docs.sh
#
# The chain is the one that was proved to work end to end (doc-009):
#   swift package dump-symbol-graph -> xcrun snippet-extract -> xcrun docc convert
# `xcodebuild docbuild` is not used: it reports success and silently drops the
# snippets.
#
# The same snippet-extract output also feeds Scripts/snippets-to-markdown.py,
# which writes the examples as plain Markdown. That is the text artifact agents
# read: a DocC page is a web application and a plain fetch of it returns an
# empty shell.
#
# Everything the script produces lands in .build/docs, which is ignored by git.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$ROOT/.build/docs"
SYMBOLS="$WORK/symbol-graphs"
OUTPUT="$WORK/HexagonKit.doccarchive"

rm -rf "$WORK"
mkdir -p "$SYMBOLS"

swift package --package-path "$ROOT" dump-symbol-graph

CORE_GRAPH="$(find "$ROOT/.build" -path '*symbolgraph*' -name 'HexagonKit.symbols.json' | head -1)"
if [ -z "$CORE_GRAPH" ]; then
  echo "symbol graph of HexagonKit not found under $ROOT/.build" >&2
  exit 1
fi
cp "$CORE_GRAPH" "$SYMBOLS/"

xcrun snippet-extract \
  --output "$SYMBOLS/snippets.symbols.json" \
  --module-name HexagonKit \
  "$ROOT"/Snippets/*.swift

python3 "$ROOT/Scripts/snippets-to-markdown.py" \
  "$SYMBOLS/snippets.symbols.json" \
  "$WORK/snippets.md"

xcrun docc convert "$ROOT/Sources/HexagonKit/HexagonKit.docc" \
  --fallback-display-name HexagonKit \
  --fallback-bundle-identifier io.github.denizztret.HexagonKit \
  --additional-symbol-graph-dir "$SYMBOLS" \
  --output-path "$OUTPUT" \
  --warnings-as-errors

ARTICLE="$OUTPUT/data/documentation/hexagonkit.json"
if [ ! -f "$ARTICLE" ]; then
  echo "the landing page $ARTICLE was not produced" >&2
  exit 1
fi
if ! grep -q "distance(to: target)" "$ARTICLE"; then
  echo "the text of Snippets/HexBasics.swift did not reach $ARTICLE" >&2
  exit 1
fi

if ! grep -q "distance(to: target)" "$WORK/snippets.md"; then
  echo "the text of Snippets/HexBasics.swift did not reach $WORK/snippets.md" >&2
  exit 1
fi

echo "documentation: $OUTPUT"
echo "snippets as text: $WORK/snippets.md"
echo "the snippet reached both the landing page and the text artifact"
