#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
PPB_SWIFTLINT=$(command -v swiftlint || true)
if [[ -z "$PPB_SWIFTLINT" && -x /opt/homebrew/bin/swiftlint ]]; then
  PPB_SWIFTLINT=/opt/homebrew/bin/swiftlint
fi
if [[ -z "$PPB_SWIFTLINT" ]]; then
  echo 'SwiftLint is required. Install it with: brew install swiftlint' >&2
  exit 1
fi
# SourceKitten needs the framework directory, not Xcode 27's swift-6.2/macosx directory.
PPB_FRAMEWORKS="$(xcode-select -p)/Toolchains/XcodeDefault.xctoolchain/usr/lib"
if [[ ! -d "$PPB_FRAMEWORKS/sourcekitdInProc.framework" ]]; then
  PPB_FRAMEWORKS=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib
fi
if [[ -d "$PPB_FRAMEWORKS/sourcekitdInProc.framework" ]]; then
  export DYLD_FRAMEWORK_PATH="$PPB_FRAMEWORKS${DYLD_FRAMEWORK_PATH:+:$DYLD_FRAMEWORK_PATH}"
fi
"$PPB_SWIFTLINT" lint --no-cache --strict --quiet
