#!/usr/bin/env bash
# Prints the UDID of an available iPhone simulator on the newest installed iOS runtime, so CI never
# hard-codes a device name a new runner image might not have.
set -euo pipefail
xcrun simctl list devices available --json \
  | jq -r '[.devices | to_entries[] | select(.key | test("iOS")) | .value[]
            | select(.name | startswith("iPhone"))] | last | .udid'
