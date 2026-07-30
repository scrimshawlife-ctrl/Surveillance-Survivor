#!/usr/bin/env bash

# Launch an installed simulator app with bounded retries.
#
# Sets:
#   SIMCTL_LAUNCH_OUTPUT  successful simctl output, or the final failure output
#   SIMCTL_LAUNCH_STATUS final simctl exit status
#
# Usage: simctl_launch_with_retry <simulator-udid> <bundle-id> <attempts> <delay-seconds> [launch-args...]
simctl_launch_with_retry() {
  local simulator_id="$1"
  local bundle_identifier="$2"
  local attempts="$3"
  local delay_seconds="$4"
  local attempt=1
  shift 4

  SIMCTL_LAUNCH_OUTPUT=""
  SIMCTL_LAUNCH_STATUS=1

  if ! [[ "$attempts" =~ ^[1-9][0-9]*$ ]]; then
    echo "Simulator launch attempts must be a positive integer, got: $attempts" >&2
    return 64
  fi
  if ! [[ "$delay_seconds" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    echo "Simulator launch retry delay must be a non-negative number, got: $delay_seconds" >&2
    return 64
  fi

  while (( attempt <= attempts )); do
    if SIMCTL_LAUNCH_OUTPUT="$(xcrun simctl launch "$simulator_id" "$bundle_identifier" "$@" 2>&1)"; then
      SIMCTL_LAUNCH_STATUS=0
      printf '%s\n' "$SIMCTL_LAUNCH_OUTPUT"
      return 0
    else
      SIMCTL_LAUNCH_STATUS=$?
    fi

    echo "simctl launch attempt ${attempt}/${attempts} failed (exit ${SIMCTL_LAUNCH_STATUS})" >&2
    if [[ -n "$SIMCTL_LAUNCH_OUTPUT" ]]; then
      printf '%s\n' "$SIMCTL_LAUNCH_OUTPUT" >&2
    else
      echo "simctl launch produced no diagnostic output." >&2
    fi

    if (( attempt < attempts )); then
      echo "Retrying simulator launch in ${delay_seconds}s..." >&2
      xcrun simctl terminate "$simulator_id" "$bundle_identifier" >/dev/null 2>&1 || true
      sleep "$delay_seconds"
    fi
    ((attempt += 1))
  done

  echo "simctl launch exhausted ${attempts} attempts." >&2
  return "$SIMCTL_LAUNCH_STATUS"
}
