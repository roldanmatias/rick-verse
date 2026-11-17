#!/usr/bin/env bash
# Run from Packages/Core after `swift test --enable-code-coverage`.  Usage: coverage.sh <min-percent>
# Fails below the threshold, and writes a per-module report to the GitHub job summary.
set -euo pipefail
MIN=${1:-80}
JSON="$(swift test --show-codecov-path)"

# Per-module line coverage of our Sources/, excluding generated Apollo code and dependencies in .build/.
REPORT=$(jq -r '
  [.data[0].files[]
   | select(.filename | test("/Sources/") and (test("/Generated/|/\\.build/") | not))
   | {module: (.filename | capture("/Sources/(?<m>[^/]+)/").m), count: .summary.lines.count, covered: .summary.lines.covered}]
  | group_by(.module)
  | map({module: .[0].module, count: (map(.count) | add), covered: (map(.covered) | add)})
  | (map("| \(.module) | \(.count) | \(((.covered / .count) * 1000 | round) / 10)% |") | join("\n")),
    "TOTAL \(((map(.covered) | add) / (map(.count) | add) * 1000 | round) / 10)"
' "$JSON")
TOTAL=$(echo "$REPORT" | awk '/^TOTAL/ {print $2}')
TABLE=$(echo "$REPORT" | grep -v '^TOTAL')

echo "| Module | Lines | Covered |"; echo "|---|---|---|"; echo "$TABLE"; echo "Total: ${TOTAL}%"
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  {
    echo "## 🧪 Core package coverage: **${TOTAL}%** (minimum ${MIN}%)"
    echo; echo "| Module | Lines | Covered |"; echo "|---|---|---|"; echo "$TABLE"
  } >> "$GITHUB_STEP_SUMMARY"
fi

awk -v t="$TOTAL" -v m="$MIN" 'BEGIN { exit !(t >= m) }' \
  || { echo "::error::Line coverage ${TOTAL}% is below the ${MIN}% minimum"; exit 1; }
