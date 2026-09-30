#!/usr/bin/env bash
# Build the DocC archives of HexagonKit and HexagonKitUI, with the examples of
# Snippets/ inlined.
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
# HexagonKitUI takes another path to its symbol graph: the graph of the host,
# macOS, has no UIKit part, so both modules are compiled for iOS with
# Scripts/compile-platform.sh and the graph is extracted from those modules.
# Without -emit-extension-block-symbols DocC would drop every extension of a
# type of another module, which is most of HexagonKitUI, without a warning.
#
# Everything the script produces lands in .build/docs, which is ignored by git.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$ROOT/.build/docs"
SYMBOLS="$WORK/symbol-graphs"
OUTPUT="$WORK/HexagonKit.doccarchive"
UI_MODULES="$WORK/ios-modules"
UI_SYMBOLS="$WORK/ui-symbol-graphs"
UI_OUTPUT="$WORK/HexagonKitUI.doccarchive"

rm -rf "$WORK"
mkdir -p "$SYMBOLS" "$UI_SYMBOLS"

# The graphs are dumped for every module of the package, the module of the
# tests included, which exists only once the tests are built.
swift build --package-path "$ROOT" --build-tests
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
# One line of each snippet file has to reach both the landing page and the text
# artifact: a slice that DocC cannot find is dropped without an error.
for marker in "distance(to: target)" "WrappedHexagon(radius: 2)"; do
  for file in "$ARTICLE" "$WORK/snippets.md"; do
    if ! grep -qF "$marker" "$file"; then
      echo "the snippet line '$marker' did not reach $file" >&2
      exit 1
    fi
  done
done

bash "$ROOT/Scripts/compile-platform.sh" "$ROOT" "$UI_MODULES" arm64-apple-ios15.0 iphoneos

# The members SwiftUI synthesizes for a shape or a view would add hundreds of
# pages that are not part of HexagonKitUI.
xcrun swift-symbolgraph-extract \
  -module-name HexagonKitUI \
  -target arm64-apple-ios15.0 \
  -sdk "$(xcrun --sdk iphoneos --show-sdk-path)" \
  -I "$UI_MODULES" \
  -minimum-access-level public \
  -skip-synthesized-members \
  -emit-extension-block-symbols \
  -output-dir "$UI_SYMBOLS"

xcrun snippet-extract \
  --output "$UI_SYMBOLS/snippets.symbols.json" \
  --module-name HexagonKitUI \
  "$ROOT/Snippets/Drawing.swift"

xcrun docc convert "$ROOT/Sources/HexagonKitUI/HexagonKitUI.docc" \
  --fallback-display-name HexagonKitUI \
  --fallback-bundle-identifier io.github.denizztret.HexagonKitUI \
  --additional-symbol-graph-dir "$UI_SYMBOLS" \
  --output-path "$UI_OUTPUT" \
  --warnings-as-errors

UI_ARTICLE="$UI_OUTPUT/data/documentation/hexagonkitui.json"
UI_PAGES="$UI_OUTPUT/data/documentation/hexagonkitui"
if [ ! -f "$UI_ARTICLE" ]; then
  echo "the landing page $UI_ARTICLE was not produced" >&2
  exit 1
fi
# The extensions of the types of other modules are most of HexagonKitUI.
for page in "hexagonkit/hexlayout/frame(of:).json" "cgpoint/init(_:).json"; do
  if [ -z "$(find "$UI_PAGES" -path "*/$page" | head -1)" ]; then
    echo "the page $page of an extension was not produced" >&2
    exit 1
  fi
done
# One line of each slice of the example of HexagonKitUI, since its landing page
# shows all three.
for marker in "layout.hex(at: CGPoint(x: 30, y: 12))" \
  "context.stroke(layout.path(of: cells), with: .color(.gray))" ".hexCell(hex)"; do
  for file in "$UI_ARTICLE" "$WORK/snippets.md"; do
    if ! grep -qF "$marker" "$file"; then
      echo "the snippet line '$marker' did not reach $file" >&2
      exit 1
    fi
  done
done

echo "documentation: $OUTPUT"
echo "documentation of HexagonKitUI: $UI_OUTPUT"
echo "snippets as text: $WORK/snippets.md"
echo "the snippets reached both landing pages and the text artifact"
