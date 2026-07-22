#!/usr/bin/env bash
set -euo pipefail

allow_empty=false
if [[ "${1:-}" == "--allow-empty" ]]; then
  allow_empty=true
  shift
fi

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 [--allow-empty] <asset-root>" >&2
  exit 64
fi

asset_root="$1"
expected_names=(
  player_idle_down player_idle_left player_idle_up player_idle_right
  player_walk_down player_walk_left player_walk_up player_walk_right
  lpr_intact lpr_damaged lpr_destroyed
  suspicion_tier_0 suspicion_tier_1 suspicion_tier_2
  suspicion_tier_3 suspicion_tier_4 suspicion_tier_5
  blind_spot_decal
)

if [[ ! -d "$asset_root" ]]; then
  if [[ "$allow_empty" == true ]]; then
    echo "No visual asset root at $asset_root; production asset intake remains pending."
    exit 0
  fi
  echo "Missing visual asset root: $asset_root" >&2
  exit 66
fi

png_files=()
while IFS= read -r -d '' file; do
  png_files+=("$file")
done < <(find "$asset_root" -type f -name '*.png' -print0)

if [[ ${#png_files[@]} -eq 0 ]]; then
  if [[ "$allow_empty" == true ]]; then
    echo "No visual PNG assets attached under $asset_root; production asset intake remains pending."
    exit 0
  fi
  echo "No PNG assets found under $asset_root" >&2
  exit 65
fi

player_dimensions=""
lpr_dimensions=""

for file in "${png_files[@]}"; do
  name="$(basename "$file" .png)"
  is_expected=false
  for expected in "${expected_names[@]}"; do
    if [[ "$name" == "$expected" ]]; then
      is_expected=true
      break
    fi
  done

  if [[ "$is_expected" != true ]]; then
    echo "Unexpected runtime PNG name: $file" >&2
    exit 65
  fi

  metadata="$(sips -g pixelWidth -g pixelHeight -g space -g hasAlpha "$file")"
  width="$(awk '/pixelWidth:/{print $2}' <<< "$metadata")"
  height="$(awk '/pixelHeight:/{print $2}' <<< "$metadata")"
  color_space="$(awk '/space:/{print $2}' <<< "$metadata")"
  alpha="$(awk '/hasAlpha:/{print $2}' <<< "$metadata")"

  if [[ -z "$width" || -z "$height" || "$color_space" != "sRGB" ]]; then
    echo "Invalid dimensions or non-sRGB PNG: $file" >&2
    exit 65
  fi
  if [[ "$alpha" != "yes" ]]; then
    echo "Runtime sprite must contain alpha transparency: $file" >&2
    exit 65
  fi

  dimensions="${width}x${height}"
  if [[ "$name" == player_* ]]; then
    if [[ -n "$player_dimensions" && "$player_dimensions" != "$dimensions" ]]; then
      echo "Player frame dimensions must match: expected $player_dimensions, found $dimensions in $file" >&2
      exit 65
    fi
    player_dimensions="$dimensions"
  elif [[ "$name" == lpr_* ]]; then
    if [[ -n "$lpr_dimensions" && "$lpr_dimensions" != "$dimensions" ]]; then
      echo "LPR state dimensions must match: expected $lpr_dimensions, found $dimensions in $file" >&2
      exit 65
    fi
    lpr_dimensions="$dimensions"
  fi
done

echo "Validated ${#png_files[@]} visual runtime PNG asset(s) under $asset_root."
