#!/usr/bin/env bash
# swift-format in strict lint mode, using the repo's .swift-format. Generated Apollo code is skipped.
set -euo pipefail
cd "$(dirname "$0")/.."
find Packages/Core/Sources Packages/Core/Tests RickVerse -name '*.swift' -not -path '*/Generated/*' -print0 \
  | xargs -0 swift format lint --strict
