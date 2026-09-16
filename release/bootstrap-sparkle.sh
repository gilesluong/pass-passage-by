#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
PPB_DOWNLOAD=$(mktemp /tmp/ppb-sparkle.XXXXXX)
trap 'rm -f "$PPB_DOWNLOAD"' EXIT
curl --fail --location --proto '=https' --tlsv1.2 'https://github.com/sparkle-project/Sparkle/releases/download/2.10.0/Sparkle-for-Swift-Package-Manager.zip' -o "$PPB_DOWNLOAD"
PPB_SHA=$(shasum -a 256 "$PPB_DOWNLOAD" | cut -d ' ' -f 1)
test "$PPB_SHA" = '17e28312b8e18ab7cdbbe09a6fb28cc55a5479ec6c371dbc07cdecd2a14fd959'
mkdir -p Vendor/Sparkle-2.10.0
ditto -x -k "$PPB_DOWNLOAD" Vendor/Sparkle-2.10.0
