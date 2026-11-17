#!/usr/bin/env bash
# Architecture fitness function: fails if a layer imports something the architecture forbids.
# SwiftPM already blocks undeclared module imports. This also covers system frameworks (SwiftUI,
# UIKit) and the app target. Each violation becomes an inline annotation on the PR diff.
set -euo pipefail
cd "$(dirname "$0")/.."
SRC=Packages/Core/Sources
fail=0

forbid() {   # forbid <dir> <regex of module names> <message>
  local hits
  hits=$(grep -RnE "^[[:space:]]*(@testable[[:space:]]+)?import[[:space:]]+($2)([[:space:]]|$)" "$1" \
         --include='*.swift' --exclude-dir=Generated || true)
  if [[ -n "$hits" ]]; then
    while IFS= read -r line; do
      file=${line%%:*}; rest=${line#*:}; lineno=${rest%%:*}
      echo "::error file=$file,line=$lineno::$3"
    done <<< "$hits"
    fail=1
  fi
}

forbid "$SRC/Domain"       "SwiftUI|UIKit|Combine|Networking|DataREST|DataGraphQL|Apollo|ApolloAPI|Presentation" \
       "Domain must not depend on any other layer or UI/networking framework"
forbid "$SRC/Presentation" "SwiftUI|UIKit|Networking|DataREST|DataGraphQL|Apollo|ApolloAPI" \
       "Presentation (ViewModels) may import only Foundation, Observation and Domain"
forbid "$SRC/Networking"   "SwiftUI|UIKit|Domain|DataREST|DataGraphQL|Apollo|ApolloAPI|Presentation" \
       "Networking is generic infrastructure and must not know the Domain"
forbid "$SRC/DataREST"     "SwiftUI|UIKit|DataGraphQL|Apollo|ApolloAPI|Presentation" \
       "DataREST must not depend on GraphQL, Apollo or Presentation"
forbid "$SRC/DataGraphQL"  "SwiftUI|UIKit|DataREST|Presentation" \
       "DataGraphQL must not depend on REST or Presentation"
forbid "RickVerse"         "Apollo|ApolloAPI" \
       "The app must reach GraphQL only through DataGraphQL's public API (ADR 0005)"

if [[ $fail -eq 0 ]]; then echo "✅ Architecture rules respected"; fi
exit $fail
