#!/usr/bin/env bash
# Compile HexagonKit and HexagonKitUI for one Apple platform with swiftc, into
# object files and modules, without xcodebuild: it needs the platform
# components installed, while swiftc needs only the SDK.
#
#   bash Scripts/compile-platform.sh <package> <output> <target triple> <SDK name>
#
# For example, for real watches, where CGFloat is Float:
#   bash Scripts/compile-platform.sh . /tmp/watch arm64_32-apple-watchos8.0 watchos
#
# The files of a module are found in its subfolders too, and warnings are
# errors. The output folder receives HexagonKit.o, HexagonKitUI.o and their
# .swiftmodule files; Scripts/build-docs.sh reads the modules for iOS.
set -euo pipefail

PACKAGE="$1"
OUTPUT="$2"
TRIPLE="$3"
SDK="$(xcrun --sdk "$4" --show-sdk-path)"
mkdir -p "$OUTPUT"

compile() {
  local module="$1"
  local -a files=()
  while IFS= read -r -d '' file; do files+=("$file"); done \
    < <(find "$PACKAGE/Sources/$module" -name '*.swift' -print0 | sort -z)
  xcrun swiftc -parse-as-library -swift-version 6 -wmo -warnings-as-errors \
    -target "$TRIPLE" -sdk "$SDK" -I "$OUTPUT" -module-name "$module" \
    -emit-module -emit-module-path "$OUTPUT/$module.swiftmodule" \
    -c -o "$OUTPUT/$module.o" "${files[@]}"
}

compile HexagonKit
compile HexagonKitUI
