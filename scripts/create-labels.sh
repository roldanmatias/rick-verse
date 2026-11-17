#!/usr/bin/env bash
# Creates or updates the labels used by labeler.yml, release.yml and contract.yml.
set -euo pipefail
gh label create domain         --color 5319E7 --description "Domain layer"                    --force
gh label create networking     --color 1D76DB --description "Networking module"               --force
gh label create rest           --color 0E8A16 --description "REST data layer"                 --force
gh label create graphql        --color E535AB --description "GraphQL / Apollo data layer"     --force
gh label create presentation   --color FBCA04 --description "ViewModels"                      --force
gh label create app            --color D93F0B --description "iOS app target / SwiftUI"        --force
gh label create ci             --color 000000 --description "CI/CD and tooling"               --force
gh label create docs           --color 0075CA --description "Documentation"                   --force
gh label create dependencies   --color 0366D6 --description "Dependency updates"              --force
gh label create schema-drift   --color B60205 --description "Upstream GraphQL schema changed" --force
gh label create skip-changelog --color CCCCCC --description "Exclude from release notes"      --force
gh label list