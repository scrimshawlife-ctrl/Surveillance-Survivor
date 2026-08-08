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
  player_idle_down_2 player_idle_left_2 player_idle_up_2 player_idle_right_2
  player_walk_down_2 player_walk_left_2 player_walk_up_2 player_walk_right_2
  player_walk_down_3 player_walk_left_3 player_walk_up_3 player_walk_right_3
  player_walk_down_4 player_walk_left_4 player_walk_up_4 player_walk_right_4
  lpr_intact lpr_damaged lpr_destroyed
  suspicion_tier_0 suspicion_tier_1 suspicion_tier_2
  suspicion_tier_3 suspicion_tier_4 suspicion_tier_5
  blind_spot_decal
  guard_default
  guard_flashlight_cadet guard_radio_guy guard_clipboard_enforcer
  guard_tactical_polo guard_segway_sentinel guard_supervisor_on_break
  boss_default
  # Enemy walk cycles (Batch 6). Frame 1 is the stem above; 2-4 complete the cycle.
  guard_default_2 guard_default_3 guard_default_4
  guard_flashlight_cadet_2 guard_flashlight_cadet_3 guard_flashlight_cadet_4
  guard_radio_guy_2 guard_radio_guy_3 guard_radio_guy_4
  guard_clipboard_enforcer_2 guard_clipboard_enforcer_3 guard_clipboard_enforcer_4
  guard_tactical_polo_2 guard_tactical_polo_3 guard_tactical_polo_4
  guard_segway_sentinel_2 guard_segway_sentinel_3 guard_segway_sentinel_4
  guard_supervisor_on_break_2 guard_supervisor_on_break_3 guard_supervisor_on_break_4
  boss_default_2 boss_default_3 boss_default_4
  projectile_default projectile_redaction projectile_identity projectile_foia
  deployable_mirror_array deployable_mirror_array_inactive deployable_mirror_array_active deployable_mirror_array_expended
  deployable_signal_flood deployable_signal_flood_inactive deployable_signal_flood_active deployable_signal_flood_expended
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
  los_angeles_terrain_freeway_arterial_01 los_angeles_terrain_sunbleached_lot_01
  los_angeles_skyline_parallax_01
  los_angeles_landmark_observatory_hills_distant_01 los_angeles_landmark_studio_backlot_01
  los_angeles_landmark_gated_community_gate_01 los_angeles_landmark_port_logistics_distant_01
  los_angeles_prop_parking_booth_01
  los_angeles_overlay_private_operator_mesh_01 los_angeles_overlay_contract_void_01 los_angeles_overlay_marine_layer_haze_01
  los_angeles_decal_faded_lane_paint_01 los_angeles_decal_studio_spike_mark_01
  atlanta_terrain_freeway_trench_01 atlanta_terrain_beltline_loop_01
  atlanta_skyline_parallax_01
  atlanta_landmark_airport_terminal_distant_01 atlanta_landmark_corporate_campus_01
  atlanta_landmark_data_center_cathedral_01 atlanta_landmark_film_lot_soundstage_01
  atlanta_landmark_hoa_subdivision_gate_01
  atlanta_overlay_nationwide_mesh_01 atlanta_overlay_network_echo_01 atlanta_overlay_public_private_state_01
  atlanta_decal_beltline_stripe_01 atlanta_decal_hoa_boundary_01

  # Weapon VFX and gameplay animation frames. Frame 1 is the bare stem and
  # frames 2..N carry the _N suffix, matching OptionalSpriteFrameCycle. Every
  # name here traces to a stem declared in WEAPON_VFX_ASSET_MANIFEST.json or
  # GAMEPLAY_ANIMATION_MANIFEST.json — none are ad hoc.
  boss_telegraph_primary boss_telegraph_primary_2 boss_telegraph_primary_3
  boss_telegraph_primary_4 boss_telegraph_primary_5 boss_telegraph_primary_6
  boss_telegraph_primary_7 boss_telegraph_primary_8 deploy_identity_transponder
  deploy_identity_transponder_2 deploy_identity_transponder_3 deployable_mirror_array_2
  deployable_mirror_array_3 deployable_signal_flood_2 deployable_signal_flood_3
  fx_blind_spot_active fx_blind_spot_active_2 fx_blind_spot_active_3
  fx_blind_spot_active_4 fx_blind_spot_active_5 fx_blind_spot_active_6
  fx_blind_spot_active_7 fx_blind_spot_active_8 fx_blind_spot_open
  fx_blind_spot_open_10 fx_blind_spot_open_11 fx_blind_spot_open_12
  fx_blind_spot_open_2 fx_blind_spot_open_3 fx_blind_spot_open_4
  fx_blind_spot_open_5 fx_blind_spot_open_6 fx_blind_spot_open_7
  fx_blind_spot_open_8 fx_blind_spot_open_9 fx_camera_destroyed
  fx_camera_destroyed_2 fx_camera_destroyed_3 fx_camera_destroyed_4
  fx_camera_destroyed_5 fx_camera_destroyed_6 fx_camera_destroyed_7
  fx_camera_destroyed_8 fx_camera_disabled fx_camera_disabled_2
  fx_camera_disabled_3 fx_camera_disabled_4 fx_foia_processing
  fx_foia_processing_2 fx_foia_processing_3 fx_foia_processing_4
  fx_foia_processing_5 fx_foia_processing_6 fx_identity_spoof_pulse
  fx_identity_spoof_pulse_2 fx_identity_spoof_pulse_3 fx_identity_spoof_pulse_4
  fx_identity_spoof_pulse_5 fx_identity_spoof_pulse_6 fx_identity_spoof_pulse_7
  fx_identity_spoof_pulse_8 fx_impact_surveillance_hardware fx_impact_surveillance_hardware_2
  fx_impact_surveillance_hardware_3 fx_impact_surveillance_hardware_4 fx_impact_surveillance_hardware_5
  fx_impact_surveillance_hardware_6 fx_kinetic_emission fx_kinetic_emission_2
  fx_kinetic_emission_3 fx_kinetic_emission_4 fx_kinetic_trail
  
  fx_network_severance
  fx_network_severance_2 fx_network_severance_3 fx_network_severance_4
  fx_network_severance_5 fx_network_severance_6 fx_redaction_field
  fx_redaction_field_2 fx_redaction_field_3 fx_redaction_field_4
  fx_redaction_field_5 fx_redaction_field_6 fx_redaction_field_7
  fx_redaction_field_8 lpr_destroy_sequence lpr_destroy_sequence_10
  lpr_destroy_sequence_2 lpr_destroy_sequence_3 lpr_destroy_sequence_4
  lpr_destroy_sequence_5 lpr_destroy_sequence_6 lpr_destroy_sequence_7
  lpr_destroy_sequence_8 lpr_destroy_sequence_9 lpr_scan_loop
  lpr_scan_loop_2 lpr_scan_loop_3 lpr_scan_loop_4
  lpr_scan_loop_5 lpr_scan_loop_6 player_damage
  player_damage_2 player_damage_3 player_damage_4
  player_defeat player_defeat_10 player_defeat_2
  player_defeat_3 player_defeat_4 player_defeat_5
  player_defeat_6 player_defeat_7 player_defeat_8
  player_defeat_9 player_extract player_extract_10
  player_extract_2 player_extract_3 player_extract_4
  player_extract_5 player_extract_6 player_extract_7
  player_extract_8 player_extract_9 projectile_kinetic
  projectile_kinetic_2 projectile_kinetic_3 projectile_redaction_2
  projectile_redaction_3 pulse_signal_flood pulse_signal_flood_2
  pulse_signal_flood_3 pulse_signal_flood_4 pulse_signal_flood_5
  pulse_signal_flood_6 pulse_signal_flood_7 pulse_signal_flood_8
  swarm_foia swarm_foia_2 swarm_foia_3
  fx_mirror_reflect fx_mirror_reflect_2 fx_mirror_reflect_3 fx_mirror_reflect_4 fx_mirror_reflect_5
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
  # `mdls` can emit its lookup failure on stdout for a file that Spotlight has
  # not indexed yet. That is not color-profile evidence; retain the portable
  # sips RGB result in that case.
  if [[ "$profile_name" == *"could not find"* ]]; then
    profile_name=""
  fi
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


# Content density / residual chroma-plate gate (empty wiped sprites fail).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/validate_sprite_content.py" ]]; then
  python3 "$SCRIPT_DIR/validate_sprite_content.py" "$asset_root"
fi

echo "Validated ${validated} visual runtime PNG asset(s) under $asset_root."
