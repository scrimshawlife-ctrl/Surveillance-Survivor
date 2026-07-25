import Foundation

/// Logical names for visual resources. Runtime systems should reference assets
/// through this namespace rather than embedding catalog strings throughout code.
enum GameAssetName {
    enum Player {
        static let idleDown = "player_idle_down"
        static let idleLeft = "player_idle_left"
        static let idleUp = "player_idle_up"
        static let idleRight = "player_idle_right"
        static let walkDown = "player_walk_down"
        static let walkLeft = "player_walk_left"
        static let walkUp = "player_walk_up"
        static let walkRight = "player_walk_right"

        static var all: [String] {
            [idleDown, idleLeft, idleUp, idleRight, walkDown, walkLeft, walkUp, walkRight]
        }

        /// Multi-frame tails used by `PlayerAtlasManifest` (base name is frame 1).
        static var multiFrameExtras: [String] {
            [
                "\(idleDown)_2", "\(idleLeft)_2", "\(idleUp)_2", "\(idleRight)_2",
                "\(walkDown)_2", "\(walkDown)_3", "\(walkDown)_4",
                "\(walkLeft)_2", "\(walkLeft)_3", "\(walkLeft)_4",
                "\(walkUp)_2", "\(walkUp)_3", "\(walkUp)_4",
                "\(walkRight)_2", "\(walkRight)_3", "\(walkRight)_4"
            ]
        }
    }

    enum LPRCamera {
        static let intact = "lpr_intact"
        static let damaged = "lpr_damaged"
        static let destroyed = "lpr_destroyed"

        static var all: [String] { [intact, damaged, destroyed] }
    }

    enum SuspicionTierIcon {
        static func name(for tier: Int) -> String {
            "suspicion_tier_\(min(5, max(0, tier)))"
        }

        static var all: [String] { (0...5).map { name(for: $0) } }
    }

    enum Environment {
        static let blindSpotDecal = "blind_spot_decal"

        // Seamless ground tiles (256²) — district biomes
        static let tileAsphalt = "env_tile_asphalt"
        static let tileDowntown = "env_tile_downtown"
        static let tileGated = "env_tile_gated"
        static let tileCampus = "env_tile_campus"
        static let tileWarehouse = "env_tile_warehouse"

        static let parallaxSkyline = "env_parallax_skyline"
        static let obstacleRetailMass = "env_obstacle_retail_mass"
        static let propSheetMunicipal = "env_prop_sheet_municipal"
        static let propSheetRetail = "env_prop_sheet_retail"
        static let decalSheet = "env_decal_sheet"

        static var terrainTiles: [String] {
            [tileAsphalt, tileDowntown, tileGated, tileCampus, tileWarehouse]
        }

        static var environmentPackage: [String] {
            terrainTiles + [
                parallaxSkyline, obstacleRetailMass,
                propSheetMunicipal, propSheetRetail, decalSheet
            ]
        }
    }

    /// City-specific packs (optional). Naming: `{city}_{role}_{variant}_{nn}`.
    enum Wichita {
        // Runtime presentation assets only (identity/palette boards live under docs/).
        static let terrainArterial = "wichita_terrain_asphalt_arterial_01"
        static let terrainPrairieEdge = "wichita_terrain_prairie_edge_01"
        static let skyline = "wichita_skyline_parallax_01"
        static let landmarkMonument = "wichita_landmark_river_monument_distant_01"
        static let landmarkGrainElevator = "wichita_landmark_grain_elevator_midground_01"
        static let landmarkHangar = "wichita_landmark_aircraft_hangar_01"
        static let landmarkBridge = "wichita_landmark_bridge_span_01"
        static let propTornadoSiren = "wichita_prop_tornado_siren_01"
        static let overlayRadarSweep = "wichita_overlay_radar_sweep_01"
        static let overlayStormAlert = "wichita_overlay_storm_alert_01"
        static let overlayAircraftShadow = "wichita_overlay_aircraft_shadow_01"
        static let decalRunwayStripe = "wichita_decal_runway_stripe_01"
        static let decalGrainDust = "wichita_decal_grain_dust_01"

        static var all: [String] {
            [
                terrainArterial, terrainPrairieEdge, skyline,
                landmarkMonument, landmarkGrainElevator, landmarkHangar, landmarkBridge,
                propTornadoSiren, overlayRadarSweep, overlayStormAlert, overlayAircraftShadow,
                decalRunwayStripe, decalGrainDust
            ]
        }
    }

    enum Guard {
        static let `default` = "guard_default"
    }

    enum Boss {
        static let `default` = "boss_default"
    }

    enum Projectile {
        static let `default` = "projectile_default"
    }

    enum Deployable {
        static let mirrorArray = "deployable_mirror_array"
        static let signalFlood = "deployable_signal_flood"
    }

    enum Marketing {
        static let keyArt = "key_art_promo_banner"
        static let conceptIllustration = "concept_illustration_cinematic"
    }

    /// Names the intake contract treats as optional glyph replacements.
    static var optionalSuspicionTier: [String] { SuspicionTierIcon.all }

    /// Attached optional entity sprites (shape fallback if a build omits them).
    static var optionalEntitySprites: [String] {
        [Guard.default, Boss.default]
    }

    /// Attached combat projection sprites (shape fallback if a build omits them).
    static var optionalCombatSprites: [String] {
        [Projectile.default, Deployable.mirrorArray, Deployable.signalFlood]
    }

    /// City pack — Louisville (Derby Day Data Dragnet). Docs boards are not runtime.
    enum Louisville {
        static let terrainBrickArterial = "louisville_terrain_brick_arterial_01"
        static let terrainHistoricStreet = "louisville_terrain_historic_street_01"
        static let skyline = "louisville_skyline_parallax_01"
        static let landmarkTwinSpires = "louisville_landmark_twin_spires_distant_01"
        static let landmarkRiverfront = "louisville_landmark_riverfront_floodwall_01"
        static let landmarkWarehouse = "louisville_landmark_bourbon_warehouse_01"
        static let landmarkVictorian = "louisville_landmark_victorian_facade_01"
        static let propIronGate = "louisville_prop_wrought_iron_gate_01"
        static let overlayMapRedaction = "louisville_overlay_map_redaction_01"
        static let overlayHiddenCameraGlint = "louisville_overlay_hidden_camera_glint_01"
        static let overlayRiverHaze = "louisville_overlay_river_haze_01"
        static let decalBourbonStain = "louisville_decal_bourbon_stain_01"
        static let decalWetBrick = "louisville_decal_wet_brick_01"

        static var all: [String] {
            [
                terrainBrickArterial, terrainHistoricStreet, skyline,
                landmarkTwinSpires, landmarkRiverfront, landmarkWarehouse, landmarkVictorian,
                propIronGate, overlayMapRedaction, overlayHiddenCameraGlint, overlayRiverHaze,
                decalBourbonStain, decalWetBrick
            ]
        }
    }

    /// City pack — Dayton (Gateway City: Every Camera Counts). Docs boards are not runtime.
    enum Dayton {
        static let terrainGatewayApproach = "dayton_terrain_gateway_approach_01"
        static let terrainIndustrialCorridor = "dayton_terrain_industrial_corridor_01"
        static let skyline = "dayton_skyline_parallax_01"
        static let landmarkEarlyFlight = "dayton_landmark_early_flight_distant_01"
        static let landmarkFountain = "dayton_landmark_riverscape_fountain_midground_01"
        static let landmarkFactory = "dayton_landmark_factory_sawtooth_01"
        static let landmarkNavigationLab = "dayton_landmark_navigation_lab_01"
        static let propNeighborhoodGateway = "dayton_prop_neighborhood_gateway_01"
        static let overlayCopiedRoute = "dayton_overlay_copied_route_01"
        static let overlayCheckpointPulse = "dayton_overlay_checkpoint_pulse_01"
        static let overlayFountainMist = "dayton_overlay_fountain_mist_01"
        static let decalGatewayScrape = "dayton_decal_gateway_scrape_01"
        static let decalTestLaneStripe = "dayton_decal_test_lane_stripe_01"

        static var all: [String] {
            [
                terrainGatewayApproach, terrainIndustrialCorridor, skyline,
                landmarkEarlyFlight, landmarkFountain, landmarkFactory, landmarkNavigationLab,
                propNeighborhoodGateway, overlayCopiedRoute, overlayCheckpointPulse, overlayFountainMist,
                decalGatewayScrape, decalTestLaneStripe
            ]
        }
    }

    /// City pack — Tulsa (The Petroleum Panopticon). Docs boards are not runtime.
    enum Tulsa {
        static let terrainRouteArterial = "tulsa_terrain_route_arterial_01"
        static let terrainOilfieldAccess = "tulsa_terrain_oilfield_access_01"
        static let skyline = "tulsa_skyline_parallax_01"
        static let landmarkDecoTower = "tulsa_landmark_deco_tower_distant_01"
        static let landmarkIndustrialWatchman = "tulsa_landmark_industrial_watchman_midground_01"
        static let landmarkOilDerrick = "tulsa_landmark_oil_derrick_01"
        static let landmarkPumpjack = "tulsa_landmark_pumpjack_01"
        static let propMotelSignFrame = "tulsa_prop_motel_sign_frame_01"
        static let overlayBehavioralCrudeFlow = "tulsa_overlay_behavioral_crude_flow_01"
        static let overlayNeonGlow = "tulsa_overlay_neon_glow_01"
        static let overlayRefineryHaze = "tulsa_overlay_refinery_haze_01"
        static let decalPipelineLeak = "tulsa_decal_pipeline_leak_01"
        static let decalRouteMarking = "tulsa_decal_route_marking_01"

        static var all: [String] {
            [
                terrainRouteArterial, terrainOilfieldAccess, skyline,
                landmarkDecoTower, landmarkIndustrialWatchman, landmarkOilDerrick, landmarkPumpjack,
                propMotelSignFrame, overlayBehavioralCrudeFlow, overlayNeonGlow, overlayRefineryHaze,
                decalPipelineLeak, decalRouteMarking
            ]
        }
    }

    /// City pack — Oakland (The Sanctuary Scanner). Docs boards are not runtime.
    enum Oakland {
        static let terrainPortService = "oakland_terrain_port_service_01"
        static let terrainWarehouseYard = "oakland_terrain_warehouse_yard_01"
        static let skyline = "oakland_skyline_parallax_01"
        static let landmarkPortCrane = "oakland_landmark_port_crane_distant_01"
        static let landmarkContainerStack = "oakland_landmark_container_stack_midground_01"
        static let landmarkLakeShoreline = "oakland_landmark_lake_shoreline_01"
        static let landmarkTransitViaduct = "oakland_landmark_transit_viaduct_01"
        static let propMuralWall = "oakland_prop_mural_wall_01"
        static let overlayBorrowedJurisdiction = "oakland_overlay_borrowed_jurisdiction_01"
        static let overlayContractRenewal = "oakland_overlay_contract_renewal_01"
        static let overlayMarineHaze = "oakland_overlay_marine_haze_01"
        static let decalContainerRust = "oakland_decal_container_rust_01"
        static let decalRailCrossing = "oakland_decal_rail_crossing_01"

        static var all: [String] {
            [
                terrainPortService, terrainWarehouseYard, skyline,
                landmarkPortCrane, landmarkContainerStack, landmarkLakeShoreline, landmarkTransitViaduct,
                propMuralWall, overlayBorrowedJurisdiction, overlayContractRenewal, overlayMarineHaze,
                decalContainerRust, decalRailCrossing
            ]
        }
    }

    /// City pack — San Francisco (Fog of Probable Cause). Docs boards are not runtime.
    enum SanFrancisco {
        static let terrainSteepArterial = "san_francisco_terrain_steep_arterial_01"
        static let terrainHillStair = "san_francisco_terrain_hill_stair_01"
        static let skyline = "san_francisco_skyline_parallax_01"
        static let landmarkBridge = "san_francisco_landmark_bridge_distant_01"
        static let landmarkVictorian = "san_francisco_landmark_victorian_midground_01"
        static let landmarkCableTrack = "san_francisco_landmark_cable_track_01"
        static let landmarkCommsTower = "san_francisco_landmark_comms_tower_01"
        static let propAVShell = "san_francisco_prop_av_shell_01"
        static let overlayFogBand = "san_francisco_overlay_fog_band_01"
        static let overlayPredictionHaze = "san_francisco_overlay_prediction_haze_01"
        static let overlayImproperSearch = "san_francisco_overlay_improper_search_01"
        static let decalCableGroove = "san_francisco_decal_cable_groove_01"
        static let decalDampAsphalt = "san_francisco_decal_damp_asphalt_01"

        static var all: [String] {
            [
                terrainSteepArterial, terrainHillStair, skyline,
                landmarkBridge, landmarkVictorian, landmarkCableTrack, landmarkCommsTower,
                propAVShell, overlayFogBand, overlayPredictionHaze, overlayImproperSearch,
                decalCableGroove, decalDampAsphalt
            ]
        }
    }

    /// City pack — Columbus (The Six-Hundred-Eye Statehouse). Docs boards are not runtime.
    enum Columbus {
        static let terrainCapitolApproach = "columbus_terrain_capitol_approach_01"
        static let terrainJurisdictionPatchwork = "columbus_terrain_jurisdiction_patchwork_01"
        static let skyline = "columbus_skyline_parallax_01"
        static let landmarkOhioStatehouse = "columbus_landmark_ohio_statehouse_distant_01"
        static let landmarkSciotoRiverfront = "columbus_landmark_scioto_riverfront_01"
        static let landmarkShortNorthArch = "columbus_landmark_short_north_arch_01"
        static let landmarkHearingChamber = "columbus_landmark_hearing_chamber_midground_01"
        static let propPublicCommentPodium = "columbus_prop_public_comment_podium_01"
        static let overlayJurisdictionSplit = "columbus_overlay_jurisdiction_split_01"
        static let overlayStatewideShare = "columbus_overlay_statewide_share_01"
        static let overlayHearingReschedule = "columbus_overlay_hearing_reschedule_01"
        static let decalCapitolStripe = "columbus_decal_capitol_stripe_01"
        static let decalAgencyBoundary = "columbus_decal_agency_boundary_01"

        static var all: [String] {
            [
                terrainCapitolApproach, terrainJurisdictionPatchwork, skyline,
                landmarkOhioStatehouse, landmarkSciotoRiverfront, landmarkShortNorthArch, landmarkHearingChamber,
                propPublicCommentPodium, overlayJurisdictionSplit, overlayStatewideShare, overlayHearingReschedule,
                decalCapitolStripe, decalAgencyBoundary
            ]
        }
    }

    /// City pack — New York City (The Five-Borough Omnigaze). Docs boards are not runtime.
    enum NewYork {
        static let terrainAvenueGrid = "new_york_terrain_avenue_grid_01"
        static let terrainBrownstoneStreet = "new_york_terrain_brownstone_street_01"
        static let skyline = "new_york_skyline_parallax_01"
        static let landmarkSuspensionBridge = "new_york_landmark_suspension_bridge_distant_01"
        static let landmarkSubwayEntrance = "new_york_landmark_subway_entrance_01"
        static let landmarkScaffoldShed = "new_york_landmark_scaffold_shed_01"
        static let landmarkRooftopWaterTower = "new_york_landmark_rooftop_water_tower_01"
        static let propDigitalSignagePanel = "new_york_prop_digital_signage_panel_01"
        static let overlayBoroughPhase = "new_york_overlay_borough_phase_01"
        static let overlayOmnigazeFusion = "new_york_overlay_omnigaze_fusion_01"
        static let overlaySubwaySteam = "new_york_overlay_subway_steam_01"
        static let decalScaffoldShadow = "new_york_decal_scaffold_shadow_01"
        static let decalWetAsphalt = "new_york_decal_wet_asphalt_01"

        static var all: [String] {
            [
                terrainAvenueGrid, terrainBrownstoneStreet, skyline,
                landmarkSuspensionBridge, landmarkSubwayEntrance, landmarkScaffoldShed, landmarkRooftopWaterTower,
                propDigitalSignagePanel, overlayBoroughPhase, overlayOmnigazeFusion, overlaySubwaySteam,
                decalScaffoldShadow, decalWetAsphalt
            ]
        }
    }

    /// City pack — Los Angeles (Thirty-Five Hundred Eyes, No One in Charge). Docs boards are not runtime.
    enum LosAngeles {
        static let terrainFreewayArterial = "los_angeles_terrain_freeway_arterial_01"
        static let terrainSunbleachedLot = "los_angeles_terrain_sunbleached_lot_01"
        static let skyline = "los_angeles_skyline_parallax_01"
        static let landmarkObservatoryHills = "los_angeles_landmark_observatory_hills_distant_01"
        static let landmarkStudioBacklot = "los_angeles_landmark_studio_backlot_01"
        static let landmarkGatedCommunityGate = "los_angeles_landmark_gated_community_gate_01"
        static let landmarkPortLogistics = "los_angeles_landmark_port_logistics_distant_01"
        static let propParkingBooth = "los_angeles_prop_parking_booth_01"
        static let overlayPrivateOperatorMesh = "los_angeles_overlay_private_operator_mesh_01"
        static let overlayContractVoid = "los_angeles_overlay_contract_void_01"
        static let overlayMarineLayerHaze = "los_angeles_overlay_marine_layer_haze_01"
        static let decalFadedLanePaint = "los_angeles_decal_faded_lane_paint_01"
        static let decalStudioSpikeMark = "los_angeles_decal_studio_spike_mark_01"

        static var all: [String] {
            [
                terrainFreewayArterial, terrainSunbleachedLot, skyline,
                landmarkObservatoryHills, landmarkStudioBacklot, landmarkGatedCommunityGate, landmarkPortLogistics,
                propParkingBooth, overlayPrivateOperatorMesh, overlayContractVoid, overlayMarineLayerHaze,
                decalFadedLanePaint, decalStudioSpikeMark
            ]
        }
    }

    /// City pack — Atlanta (Flock's Nest). Docs boards are not runtime.
    enum Atlanta {
        static let terrainFreewayTrench = "atlanta_terrain_freeway_trench_01"
        static let terrainBeltlineLoop = "atlanta_terrain_beltline_loop_01"
        static let skyline = "atlanta_skyline_parallax_01"
        static let landmarkAirportTerminal = "atlanta_landmark_airport_terminal_distant_01"
        static let landmarkCorporateCampus = "atlanta_landmark_corporate_campus_01"
        static let landmarkDataCenterCathedral = "atlanta_landmark_data_center_cathedral_01"
        static let landmarkFilmLotSoundstage = "atlanta_landmark_film_lot_soundstage_01"
        static let landmarkHOASubdivisionGate = "atlanta_landmark_hoa_subdivision_gate_01"
        static let overlayNationwideMesh = "atlanta_overlay_nationwide_mesh_01"
        static let overlayNetworkEcho = "atlanta_overlay_network_echo_01"
        static let overlayPublicPrivateState = "atlanta_overlay_public_private_state_01"
        static let decalBeltlineStripe = "atlanta_decal_beltline_stripe_01"
        static let decalHOABoundary = "atlanta_decal_hoa_boundary_01"

        static var all: [String] {
            [
                terrainFreewayTrench, terrainBeltlineLoop, skyline,
                landmarkAirportTerminal, landmarkCorporateCampus, landmarkDataCenterCathedral,
                landmarkFilmLotSoundstage, landmarkHOASubdivisionGate,
                overlayNationwideMesh, overlayNetworkEcho, overlayPublicPrivateState,
                decalBeltlineStripe, decalHOABoundary
            ]
        }
    }

    /// Optional environment package (shape/world fallback if a build omits them).
    static var optionalEnvironment: [String] {
        Environment.environmentPackage + Wichita.all + Louisville.all + Tulsa.all + Dayton.all + Oakland.all + SanFrancisco.all + Columbus.all + NewYork.all + LosAngeles.all + Atlanta.all
    }

    /// Names reserved for later art families (shape fallback until attached).
    /// P0 projectile/deployable stills are no longer reserved — see `optionalCombatSprites`.
    static var reservedFuture: [String] {
        []
    }
}
