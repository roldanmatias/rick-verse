#!/usr/bin/env bash
# Builds static DocC sites for every Core module into Packages/Core/_site (used by `make docs` and docs.yml).
# Usage: build-docs.sh [hosting-base-path]   (in CI: the repository name, for GitHub Pages)
set -euo pipefail
cd "$(dirname "$0")/../Packages/Core"
BASE=${1:-}
rm -rf _site && mkdir -p _site
LINKS=""
for T in Domain Networking DataREST DataGraphQL Presentation; do
  LOWER=$(echo "$T" | tr '[:upper:]' '[:lower:]')
  ARGS=(--disable-indexing --transform-for-static-hosting --output-path "_site/$T")
  if [[ -n "$BASE" ]]; then ARGS+=(--hosting-base-path "$BASE/$T"); fi
  swift package --allow-writing-to-directory "_site/$T" generate-documentation --target "$T" "${ARGS[@]}"
  LINKS="$LINKS<li><a href=\"$T/documentation/$LOWER/\">$T</a></li>"
done
cat > _site/index.html <<HTML
<!doctype html><html><head><meta charset="utf-8"><title>RickVerse docs</title></head>
<body style="font-family:-apple-system,sans-serif;max-width:640px;margin:48px auto">
<h1>RickVerse — Core package</h1><ul>$LINKS</ul></body></html>
HTML
echo "✅ Docs in Packages/Core/_site"
