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
  guard_default boss_default
)

if [[ ! -d "$asset_root" ]]; then
  if [[ "$allow_empty" == true ]]; then
    echo "No visual asset root at $asset_root; production asset intake remains pending."
    exit 0
  fi
  echo "Missing visual asset root: $asset_root" >&2
  exit 66
fi

# Prefer the flat RuntimeSprites export when present. App icons and asset-catalog
# packaging PNGs live under Assets.xcassets and are not runtime sprite contracts.
if [[ -d "$asset_root/RuntimeSprites" ]] && compgen -G "$asset_root/RuntimeSprites/*.png" >/dev/null; then
  asset_root="$asset_root/RuntimeSprites"
fi

png_files=()
while IFS= read -r -d '' file; do
  # App Icon and other catalog packaging assets are not GameAssetName sprites.
  case "$file" in
    *AppIcon.appiconset*|*AppIcon-*.png|*AppIcon.png) continue ;;
  esac
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
validated=0

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
  validated=$((validated + 1))

  metadata="$(sips -g pixelWidth -g pixelHeight -g space -g hasAlpha "$file")"
  width="$(awk '/pixelWidth:/{print $2}' <<< "$metadata")"
  height="$(awk '/pixelHeight:/{print $2}' <<< "$metadata")"
  color_space="$(awk '/space:/{print $2}' <<< "$metadata")"
  alpha="$(awk '/hasAlpha:/{print $2}' <<< "$metadata")"
  # Modern macOS sips reports "RGB" even when the embedded ICC profile is sRGB.
  # Prefer the profile name when present; accept RGB/sRGB as the color model.
  profile_name="$(mdls -name kMDItemProfileName -raw "$file" 2>/dev/null || true)"
  is_srgb=false
  if [[ "$color_space" == "sRGB" || "$color_space" == "RGB" ]]; then
    if [[ -z "$profile_name" || "$profile_name" == "(null)" || "$profile_name" == *sRGB* || "$profile_name" == *IEC61966* ]]; then
      is_srgb=true
    fi
  fi

  if [[ -z "$width" || -z "$height" || "$is_srgb" != true ]]; then
    echo "Invalid dimensions or non-sRGB PNG: $file (space=$color_space profile=$profile_name)" >&2
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

echo "Validated ${validated} visual runtime PNG asset(s) under $asset_root."
