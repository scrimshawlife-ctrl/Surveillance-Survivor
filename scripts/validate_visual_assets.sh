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
  env_tile_asphalt env_tile_downtown env_tile_gated env_tile_campus env_tile_warehouse
  env_parallax_skyline env_obstacle_retail_mass
  env_prop_sheet_municipal env_prop_sheet_retail env_decal_sheet
  wichita_terrain_asphalt_arterial_01 wichita_terrain_prairie_edge_01
  wichita_skyline_parallax_01
  wichita_landmark_river_monument_distant_01 wichita_landmark_grain_elevator_midground_01
  wichita_landmark_aircraft_hangar_01 wichita_landmark_bridge_span_01
  wichita_prop_tornado_siren_01
  wichita_overlay_radar_sweep_01 wichita_overlay_storm_alert_01 wichita_overlay_aircraft_shadow_01
  wichita_decal_runway_stripe_01 wichita_decal_grain_dust_01
  louisville_terrain_brick_arterial_01 louisville_terrain_historic_street_01
  louisville_skyline_parallax_01
  louisville_landmark_twin_spires_distant_01 louisville_landmark_riverfront_floodwall_01
  louisville_landmark_bourbon_warehouse_01 louisville_landmark_victorian_facade_01
  louisville_prop_wrought_iron_gate_01
  louisville_overlay_map_redaction_01 louisville_overlay_hidden_camera_glint_01 louisville_overlay_river_haze_01
  louisville_decal_bourbon_stain_01 louisville_decal_wet_brick_01
  dayton_terrain_gateway_approach_01 dayton_terrain_industrial_corridor_01
  dayton_skyline_parallax_01
  dayton_landmark_early_flight_distant_01 dayton_landmark_riverscape_fountain_midground_01
  dayton_landmark_factory_sawtooth_01 dayton_landmark_navigation_lab_01
  dayton_prop_neighborhood_gateway_01
  dayton_overlay_copied_route_01 dayton_overlay_checkpoint_pulse_01 dayton_overlay_fountain_mist_01
  dayton_decal_gateway_scrape_01 dayton_decal_test_lane_stripe_01
  tulsa_terrain_route_arterial_01 tulsa_terrain_oilfield_access_01
  tulsa_skyline_parallax_01
  tulsa_landmark_deco_tower_distant_01 tulsa_landmark_industrial_watchman_midground_01
  tulsa_landmark_oil_derrick_01 tulsa_landmark_pumpjack_01
  tulsa_prop_motel_sign_frame_01
  tulsa_overlay_behavioral_crude_flow_01 tulsa_overlay_neon_glow_01 tulsa_overlay_refinery_haze_01
  tulsa_decal_pipeline_leak_01 tulsa_decal_route_marking_01
  oakland_terrain_port_service_01 oakland_terrain_warehouse_yard_01
  oakland_skyline_parallax_01
  oakland_landmark_port_crane_distant_01 oakland_landmark_container_stack_midground_01
  oakland_landmark_lake_shoreline_01 oakland_landmark_transit_viaduct_01
  oakland_prop_mural_wall_01
  oakland_overlay_borrowed_jurisdiction_01 oakland_overlay_contract_renewal_01 oakland_overlay_marine_haze_01
  oakland_decal_container_rust_01 oakland_decal_rail_crossing_01
  san_francisco_terrain_steep_arterial_01 san_francisco_terrain_hill_stair_01
  san_francisco_skyline_parallax_01
  san_francisco_landmark_bridge_distant_01 san_francisco_landmark_victorian_midground_01
  san_francisco_landmark_cable_track_01 san_francisco_landmark_comms_tower_01
  san_francisco_prop_av_shell_01
  san_francisco_overlay_fog_band_01 san_francisco_overlay_prediction_haze_01 san_francisco_overlay_improper_search_01
  san_francisco_decal_cable_groove_01 san_francisco_decal_damp_asphalt_01
  columbus_terrain_capitol_approach_01 columbus_terrain_jurisdiction_patchwork_01
  columbus_skyline_parallax_01
  columbus_landmark_ohio_statehouse_distant_01 columbus_landmark_scioto_riverfront_01
  columbus_landmark_short_north_arch_01 columbus_landmark_hearing_chamber_midground_01
  columbus_prop_public_comment_podium_01
  columbus_overlay_jurisdiction_split_01 columbus_overlay_statewide_share_01 columbus_overlay_hearing_reschedule_01
  columbus_decal_capitol_stripe_01 columbus_decal_agency_boundary_01
  new_york_terrain_avenue_grid_01 new_york_terrain_brownstone_street_01
  new_york_skyline_parallax_01
  new_york_landmark_suspension_bridge_distant_01 new_york_landmark_subway_entrance_01
  new_york_landmark_scaffold_shed_01 new_york_landmark_rooftop_water_tower_01
  new_york_prop_digital_signage_panel_01
  new_york_overlay_borough_phase_01 new_york_overlay_omnigaze_fusion_01 new_york_overlay_subway_steam_01
  new_york_decal_scaffold_shadow_01 new_york_decal_wet_asphalt_01
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
