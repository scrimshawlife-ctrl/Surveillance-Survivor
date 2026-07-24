# Surveillance Survivor — Audio Asset Production Bible

## Status and authority

- **Authority:** canonical audio-production specification
- **Generator:** ElevenLabs Sound Effects and Music
- **Runtime authority:** `Sources/SurveillanceCore/Resources/Content/audio_events.json`
- **Event map:** `docs/AUDIO_EVENT_MAP.md`
- **Campaign authority:** `docs/TEN_CITY_CAMPAIGN_ROSTER.md`
- **Environment context:** the approved ten-city visual-production sequence
- **Current implementation:** only the 11 stems in `audio_events.json` are runtime-addressable; all other entries below are production requirements or reserved integration targets until code and catalog entries land.

This document is intentionally audit-visible. Any agent auditing the repository must treat it as the source of truth for required audio production, naming, reuse, ElevenLabs prompts, and acceptance criteria.

---

## 1. Audio thesis

The sound of *Surveillance Survivor* is **paranoid slapstick built from municipal infrastructure**. The mix should be tactile, rhythmic, readable, and funny without becoming novelty comedy.

Core materials:

- servo motors, camera shutters, relays, hard drives, fluorescent ballast, radios, turnstiles, gates, road hardware, printers, scanners, HVAC, data-center cooling, warning beacons, aircraft, rail and freeway infrastructure
- bureaucratic percussion: stamps, binders, clipboards, paper cutters, queue barriers, receipt printers, filing cabinets
- city identity: local transit, architecture, weather, industry, landscape, and civic machinery
- musical language: tense electronic percussion, prepared instruments, industrial found sound, restrained regional references, no pastiche or cultural caricature

The player must understand events without looking at the HUD. High-priority cues must remain distinct under dense combat.

---

## 2. ElevenLabs generation rules

Use these requirements on every generation:

1. **No copyrighted melodies, branded sonic logos, celebrity voices, real dispatch recordings, or identifiable public-address announcements.**
2. **No intelligible speech for MVP.** Use abstract radio texture, vocoder fragments, or nonverbal human reactions only when specified.
3. Generate **dry, isolated one-shots** unless the asset is explicitly a loop, ambience, music bed, or stinger.
4. Do not add long mastering tails to one-shots. Preserve clean edit points.
5. Avoid cinematic sub-bass that masks gameplay. Prioritize midrange transient identity.
6. Avoid generic arcade bleeps. The existing event map explicitly rejects placeholder system beeps.
7. Generate at **48 kHz / 24-bit WAV** when ElevenLabs export allows; archive WAV masters, then derive Apple-ready CAF or AAC/M4A delivery files.
8. One-shots: usually 0.15–2.5 seconds. Stingers: 2–8 seconds. Ambience loops: 30–90 seconds. Music loops: 60–150 seconds.
9. Loop assets must have seamless heads and tails and no exposed reverb discontinuity.
10. Render important repeatable sounds in **three variants** (`_v01`–`_v03`) to reduce repetition, but retain the canonical stem as the logical runtime identity.

### Universal negative prompt

Append conceptually to every prompt:

> No speech, no lyrics, no melody quotation, no branded sonic logo, no crowd dialogue, no excessive reverb, no clipping, no stock arcade beep, no horror sting unless requested, no trailer boom, clean isolated production audio.

---

## 3. File, loudness, and metadata standard

### Naming

- Runtime one-shot: `sfx_<system>_<event>.wav`
- UI: `ui_<event>.wav`
- Stinger: `stinger_<city_or_system>_<event>.wav`
- Ambience loop: `amb_<city>_<district>_<layer>_loop.wav`
- Music loop: `music_<city>_<state>_loop.wav`
- Boss phase: `music_<city>_boss_phase_<n>_loop.wav`
- Voice-like nonverbal texture: `vox_<system>_<event>.wav`

Never use `final`, `new`, `copy`, dates, or unnamed exports.

### Target loudness

- One-shot SFX: peak no higher than -1 dBFS; normalize by perceived category, not blindly.
- UI and feedback: approximately -18 to -14 LUFS short-term.
- Combat SFX: approximately -16 to -12 LUFS short-term, with priority managed in runtime.
- Ambience: approximately -30 to -24 LUFS integrated.
- Music: approximately -22 to -18 LUFS integrated before runtime ducking.
- Stingers: approximately -20 to -14 LUFS integrated depending on density.

### Required metadata manifest fields

`asset_id`, `filename`, `logical_stem`, `status`, `category`, `bus`, `city`, `district`, `loop`, `duration_target`, `variant_count`, `prompt`, `negative_prompt`, `source`, `license`, `sample_rate`, `bit_depth`, `lufs`, `true_peak`, `integration_target`, `notes`.

Status enum:

- `RUNTIME_REQUIRED`
- `PRODUCTION_REQUIRED`
- `RESERVED_INTEGRATION`
- `REUSE_EXACT`
- `REUSE_VARIANT`
- `REJECT_DUPLICATE`

---

# 4. Runtime-required event bank

These 11 logical stems already exist in `audio_events.json` and must keep their exact names.

| Asset stem | Type | Target | ElevenLabs prompt |
|---|---|---:|---|
| `sfx_suspicion_tier_up` | feedback one-shot | 0.5–0.9 s | A tense surveillance escalation cue: three fast ascending mechanical relay clicks merging into a sharp camera-lens iris snap and restrained warning pulse, dry, readable, bureaucratic technology rather than arcade UI. |
| `sfx_upgrade_offered` | UI one-shot | 0.8–1.4 s | A strange but inviting upgrade reveal made from a data-shard shimmer, magnetic card reader texture, soft glass resonance, and one upward mechanical flourish; curious, tactical, not magical. |
| `sfx_upgrade_selected` | UI one-shot | 0.4–0.8 s | A decisive equipment-selection confirmation: compact metal latch, clean relay lock, short analog synth resolve, satisfying and controlled, no celebratory fanfare. |
| `sfx_lpr_destroyed` | combat one-shot | 1.0–1.8 s | License-plate camera pole destruction: brittle camera housing crack, servo seizure, electrical spit, metal pole resonance, lens fragments, and a brief dying data chirp; punchy but not explosive. |
| `sfx_weapon_fire` | combat one-shot, 3 variants | 0.15–0.45 s | Compact improvised anti-surveillance weapon discharge: sharp electromagnetic snap, compressed spring mechanism, tiny metallic projectile impulse, minimal low end, rapid-repeat friendly. |
| `sfx_countermeasure_hit` | combat one-shot, 3 variants | 0.25–0.7 s | Countermeasure impact against surveillance hardware: phase-cancel pop, reflective metallic ping, brief digital distortion, and dry electrical crackle; distinct from normal weapon impact. |
| `sfx_player_damaged` | feedback one-shot, 3 variants | 0.35–0.8 s | Player damage feedback without gore: clothing impact, short breathless nonverbal grunt buried low, radio static burst, and a clipped low warning thump; urgent, readable, not brutal. |
| `sfx_player_defeated` | feedback stinger | 2.5–4.5 s | Defeat stinger built from a descending municipal power-down, slowed camera shutter, failed access buzzer texture, distant fluorescent lights extinguishing, and a dry final relay click; bleakly comic, not tragic. |
| `sfx_boss_activated` | boss stinger | 3–6 s | Boss activation: institutional machinery waking up, heavy binder slam, multiple server relays, rotating warning beacon, restrained industrial percussion rise, then a hard synchronized lock; intimidating bureaucratic scale. |
| `sfx_extraction_opened` | stinger | 2–4 s | Blind Spot extraction portal opening: surveillance noise rapidly phase-cancels, radio static folds inward, cool resonant air opens, and one clean cyan-like harmonic bloom appears; relief with urgency. |
| `sfx_extraction_completed` | victory stinger | 4–7 s | Successful extraction: network links disconnect in sequence, camera relays go dark, a warm analog chord rises from the remaining silence, light percussive release, earned and strange rather than heroic blockbuster music. |

---

# 5. Shared gameplay SFX production bank

These are required for full production but need runtime events or projection hooks before shipping.

| Asset | Target | ElevenLabs prompt |
|---|---:|---|
| `sfx_player_footstep_asphalt` | 3 variants, 0.15–0.3 s | Close dry sneaker footstep on rough asphalt, quick top-down action-game readability, no room ambience. |
| `sfx_player_footstep_concrete` | 3 variants | Dry sneaker step on municipal concrete, slightly brighter than asphalt, compact transient. |
| `sfx_player_footstep_gravel` | 3 variants | Fast sneaker step through fine industrial gravel, controlled grit, no exaggerated crunch. |
| `sfx_player_dash` | 3 variants, 0.3–0.6 s | Sudden evasive dash: cloth movement, shoe scrape, short air displacement, faint radio phase smear. |
| `sfx_player_low_health_pulse` | loopable pulse | Restrained low-health feedback: soft irregular heartbeat blended with clipped radio interference and faint fluorescent hum, non-gory, non-musical. |
| `sfx_pickup_data_shard` | 3 variants | Tiny glass-data fragment collected: hard drive tick, crystalline chip, magnetic snap, short upward shimmer. |
| `sfx_upgrade_reroll` | 0.5–1 s | Upgrade reroll: cards or paper forms rapidly shuffled through a scanner, mechanical reset, brief uncertain synth flutter. |
| `sfx_blind_spot_enter` | 0.6–1.2 s | Entering a surveillance Blind Spot: ambient hiss cancels, lens motors stop, cool pressure drop, intimate sudden quiet. |
| `sfx_blind_spot_exit` | 0.6–1.2 s | Leaving a Blind Spot: distant sensors reacquire, relay chain wakes, subtle red warning texture returns. |
| `sfx_suspicion_decay` | subtle one-shot | Suspicion decreasing: one descending filtered relay tone and camera motor relaxing, quiet enough for repeated use. |
| `sfx_suspicion_max` | alarm stinger | Maximum suspicion: layered camera shutters synchronize with road beacon, police-radio-like noise without speech, hard repeating pulse, no siren cliché. |
| `sfx_guard_alert` | 3 variants | Security guard detection: radio squelch, boot stop, flashlight switch, clipped nonverbal acknowledgement, no words. |
| `sfx_guard_attack` | 3 variants | Absurd contract-security attack: tactical fabric, baton or clipboard swing, short equipment rattle, dry impact preparation. |
| `sfx_guard_defeated` | 3 variants | Guard defeat without gore: equipment collapse, radio clatter, clipboard slap, air knocked out, compact. |
| `sfx_projectile_impact_ground` | 3 variants | Small improvised projectile striking asphalt: hard tick, grit spray, minimal tail. |
| `sfx_projectile_impact_metal` | 3 variants | Small projectile ricochet from municipal metal: bright ping, short resonant scrape, controlled. |
| `sfx_camera_scan_begin` | 0.3–0.7 s | LPR scan initiation: lens focus, infrared emitter tick, narrow servo sweep, precise and threatening. |
| `sfx_camera_scan_loop` | seamless 2–4 s | Quiet continuous camera tracking loop: smooth servo movement, subtle data polling, no rhythmic beep. |
| `sfx_camera_scan_lock` | 0.4–0.8 s | Scan lock: lens iris closes, database match relay, short hard confirmation pulse. |
| `sfx_camera_damaged` | 3 variants | Camera takes damage: plastic shell crack, servo misalignment, electrical sputter, less final than destruction. |
| `sfx_camera_network_link` | 0.5–1 s | Two surveillance nodes linking: relay handshake, cable data rush, synchronized lens tick. |
| `sfx_wave_start` | 1.5–3 s | Enemy wave onset: distant parking-lot lights switch on in sequence, radio channels open, industrial percussion begins. |
| `sfx_wave_complete` | 1.5–3 s | Wave cleared: warning infrastructure powers down, loose metal settles, brief relieved analog pulse. |
| `sfx_elite_spawn` | 2–4 s | Elite arrival: unusual municipal machine engages, layered mechanical signature, concise threat reveal. |
| `sfx_boss_phase_change` | 1.5–3 s | Boss phase transition: system reconfiguration, heavy relays, barriers moving, tonal center shifts upward, no trailer boom. |
| `sfx_pause_open` | 0.25–0.5 s | Pause menu opens with a clipped binder tab, muted relay, soft paper stop. |
| `sfx_pause_close` | 0.2–0.4 s | Pause closes: binder tab snaps back, system resumes with tiny motor start. |
| `sfx_button_focus` | 0.1–0.25 s | Tactile UI focus: subtle plastic switch and restrained data tick, accessible but unobtrusive. |
| `sfx_button_confirm` | 0.2–0.45 s | Confirm action: firm office-machine keypress, clean relay closure, no arcade chirp. |
| `sfx_button_cancel` | 0.2–0.45 s | Cancel action: soft mechanical return, downward filtered click, no error buzzer. |

---

# 6. Shared district soundscape layers

Generate these as modular loops so every city can reuse the district grammar without duplicating full mixes.

## Retail Security Zone

| Asset | ElevenLabs prompt |
|---|---|
| `amb_shared_retail_parking_air_loop` | Seamless 60-second open parking-lot ambience: distant arterial traffic, HVAC rooftops, shopping-cart rattle, sodium light hum, sparse wind, no voices, lots of negative space. |
| `amb_shared_retail_security_layer_loop` | Seamless surveillance layer: distant camera servos, parking gate relays, occasional scanner chirp texture without arcade beeps, private security radio noise without speech. |
| `music_shared_retail_pressure_loop` | 90-second seamless minimalist combat bed using muted electronic percussion, parking-gate clacks, rubber tire rhythm, sparse analog bass, tense but open. |

## Smart Downtown

| Asset | ElevenLabs prompt |
|---|---|
| `amb_shared_downtown_canyon_loop` | Dense but speechless city canyon ambience: ventilation, crosswalk mechanism textures without recognizable signals, distant traffic wash, glass reflections represented sonically by bright short echoes. |
| `amb_shared_downtown_network_loop` | Server relays, smart kiosks, transit electrical hum, rooftop equipment, subtle synchronized pulses, seamless and restrained. |
| `music_shared_downtown_pressure_loop` | Fast precise electronic-industrial loop, clipped transit rhythm, glassy mallets, restrained sub pulse, urban compression and surveillance density. |

## Gated Serenity

| Asset | ElevenLabs prompt |
|---|---|
| `amb_shared_gated_suburb_loop` | Quiet affluent suburban ambience: sprinklers, distant pool equipment, ornamental fountain, soft landscaping wind, garage motor far away, no birds dominating. |
| `amb_shared_gated_security_loop` | Private gate motors, keypad relays, golf-cart charger hum, discreet camera tracking, polished and invasive. |
| `music_shared_gated_pressure_loop` | Seamless restrained tension bed made from soft marimba-like gated notes, clipped HOA gate motors, clean bass pulses, pleasant surface with controlling undertone. |

## Civic Innovation Campus

| Asset | ElevenLabs prompt |
|---|---|
| `amb_shared_innovation_campus_loop` | Polished research campus ambience: glass lobby HVAC, prototype motors, solar inverter hum, distant autonomous cart, fiber cabinet fans, no voices. |
| `amb_shared_innovation_test_layer_loop` | Experimental sensor sweeps, calibration clicks, moving test lights translated into rhythmic sound, seamless and technical. |
| `music_shared_innovation_pressure_loop` | Clean modular-synth tension loop with precise laboratory percussion, servo rhythms, glass resonance, optimistic technology turning quietly coercive. |

## Evidence Warehouse

| Asset | ElevenLabs prompt |
|---|---|
| `amb_shared_evidence_warehouse_loop` | Large records-and-logistics warehouse ambience: fluorescent ballast, distant forklift movement without horn, shelving creaks, ventilation, paper and chain-link detail, no speech. |
| `amb_shared_evidence_archive_layer_loop` | Hard drives, barcode scanners abstracted without stock beeps, conveyor relays, file drawers, sealed-door motors, seamless. |
| `music_shared_evidence_pressure_loop` | Tight industrial stealth-combat loop using filing cabinets, chain-link taps, low server pulses, conveyor rhythm, claustrophobic but readable. |

---

# 7. City audio packages

Each city requires four minimum identity assets: exterior ambience, surveillance/mechanic layer, city combat music, and boss music/stinger. Shared district layers should be mixed underneath rather than regenerated.

## 7.1 Wichita — The Panopticon of the Plains

| Asset | ElevenLabs prompt |
|---|---|
| `amb_wichita_city_identity_loop` | Seamless 75-second Wichita prairie-city ambience: broad wind, distant aircraft hangar activity, grain elevator machinery, rail-yard resonance, river bridge wash, far tornado-warning infrastructure, enormous open sky, no voices. |
| `amb_wichita_aircraft_scanner_loop` | Aerial surveillance layer: distant propeller and executive-jet passes, radar sweeps, rotating weather siren motors, zoning barrier relays, subtle and loopable. |
| `music_wichita_combat_loop` | 100-second seamless tense rhythm built from aircraft rivet tools, grain conveyor percussion, radar pulses, dry prairie guitar harmonics used abstractly, wide sparse arrangement. |
| `music_wichita_boss_aviation_commissioner_loop` | Boss loop: armored procurement machinery, binder percussion, radar bass, aircraft warning beacons, escalating restricted-airspace rhythm, bureaucratic aviation menace. |
| `stinger_wichita_restricted_airspace` | Airspace restriction appears: radar lock, flight beacon sequence, heavy zoning gate slam, short 3-second threat stinger. |

## 7.2 Louisville — Derby Day Data Dragnet

| Asset | ElevenLabs prompt |
|---|---|
| `amb_louisville_city_identity_loop` | Seamless Louisville ambience: humid Ohio River air, distant bridge traffic, Victorian brick alley reflections, bourbon warehouse ventilation and wood movement, restrained race-day infrastructure, no crowd speech. |
| `amb_louisville_redaction_loop` | Hidden-camera and redaction layer: concealed lens motors behind ornament, paper blacking marker texture, locked records drawers, intermittent missing-frequency dropouts. |
| `music_louisville_combat_loop` | Seamless tense loop using brushed snare-like race cadence, barrel wood percussion, iron gate rhythm, river-dark synth bass, elegant but secretive. |
| `music_louisville_boss_confidential_coordinates_loop` | Boss loop: blacked-out orchestral fragments, heavy closed doors, paper shredding rhythm, warped ceremonial percussion, map sections disappearing sonically. |
| `stinger_louisville_screen_redacted` | Fast 2–3 second redaction event: paper dragged across glass, audio band abruptly censored, locked cabinet slam. |

## 7.3 Tulsa — The Petroleum Panopticon

| Asset | ElevenLabs prompt |
|---|---|
| `amb_tulsa_city_identity_loop` | Seamless Tulsa ambience: dry roadside air, low refinery hum, distant pumpjack, motel electrical buzz, Art Deco downtown ventilation, storm front far away. |
| `amb_tulsa_behavioral_extraction_loop` | Data extraction layer: pumpjack rhythm fused with server polling, pipeline pressure, valve ticks, motel scanner relays, loopable and mechanical. |
| `music_tulsa_combat_loop` | 100-second seamless combat bed using pumpjack percussion, chrome vibraphone-like hits, restrained Route 66 guitar texture without genre pastiche, pressure-building analog bass. |
| `music_tulsa_boss_golden_watchman_loop` | Monumental boss loop: heavy derrick rhythm, chrome impacts, data pumping, civic fanfare degraded into extraction machinery. |
| `stinger_tulsa_pressure_release` | Pressure hazard release: valve scream, compressed data rush, pipe resonance, sharp cutoff, 2 seconds. |

## 7.4 Dayton — Gateway City: Every Camera Counts

| Asset | ElevenLabs prompt |
|---|---|
| `amb_dayton_city_identity_loop` | Seamless Dayton ambience: Midwestern riverfront, fountain mist, adaptive-reuse factories, research-lab ventilation, distant small aircraft, neighborhood gate motors. |
| `amb_dayton_gateway_network_loop` | Checkpoint layer: chained gate arms, route sensors, bicycle-like mechanical ticks, paper-airplane swarms represented by fast flutter, path memory pulses. |
| `music_dayton_combat_loop` | Seamless combat music from factory presses, bicycle chain rhythms, fountain droplets, early-flight wire tension, precise checkpoint pulse. |
| `music_dayton_boss_gateway_optimization_loop` | Boss loop: repeated gate sequences, copied rhythmic paths, industrial research synth, forced corridor tension, increasingly rigid repetition. |
| `stinger_dayton_route_copied` | Previous movement path copied: footsteps echo in reverse, gate relay locks, short synthetic duplicate trail. |

## 7.5 Oakland — The Sanctuary Scanner

| Asset | ElevenLabs prompt |
|---|---|
| `amb_oakland_city_identity_loop` | Seamless Oakland ambience: port crane motors, container-yard resonance, BART-like elevated transit without branding, Lake Merritt water and birds restrained, freeway underpass, distant hills. |
| `amb_oakland_borrowed_jurisdiction_loop` | Network handoff layer: port relay, transit electrical pulse, private security cabinet, federal-request-like abstract data tunnel, systems linking across boundaries. |
| `music_oakland_combat_loop` | Seamless combat bed using container impacts, transit rail rhythm, hand percussion inspired by community street texture without cultural imitation, lake-water pulse, defiant electronic bass. |
| `music_oakland_boss_contract_hydra_loop` | Boss loop: six recurring contract motifs, each a different relay rhythm, container-crane bass, clauses stacking until one vendor machine. |
| `stinger_oakland_contract_renewed` | Contract renewal: printer feeds a new page, digital signature relay, cash-register-like mechanism avoided, network powers back on. |

## 7.6 San Francisco — Fog of Probable Cause

| Asset | ElevenLabs prompt |
|---|---|
| `amb_san_francisco_city_identity_loop` | Seamless San Francisco ambience: marine fog, steep wet streets, cable track resonance, Victorian building creaks, distant bridge wind, autonomous vehicle tire hush. |
| `amb_san_francisco_hidden_sensor_fog_loop` | Fog surveillance layer: muffled sensor servos, lidar-like ticks diffused through mist, rooftop relay pulses, cable route prediction below audibility. |
| `music_san_francisco_combat_loop` | Seamless tense electronic loop with cable tension, wet street percussion, fog-softened synth, autonomous motor rhythm, ornate chamber fragments abstracted and modern. |
| `music_san_francisco_boss_algorithmic_moderate_loop` | Four-phase boss loop: balanced polite opening, public-safety pulse, civil-liberties interlude that still tracks, independent-review machinery, all phases expanding observation. |
| `stinger_san_francisco_improper_search` | Improper access event: credential handshake, muted lock bypass, fog clears for one sharp lens snap, 2–3 seconds. |

## 7.7 Columbus — The Six-Hundred-Eye Statehouse

| Asset | ElevenLabs prompt |
|---|---|
| `amb_columbus_city_identity_loop` | Seamless Columbus ambience: formal civic plaza, riverfront, campus brick court, suburban road transitions, hearing-building HVAC, gateway arches, restrained traffic. |
| `amb_columbus_statewide_sharing_loop` | Statewide sharing layer: many small jurisdiction relays linking into one deep server pulse, hearing queue mechanisms, calendar pages, archway scan lights. |
| `music_columbus_combat_loop` | Seamless combat loop from legislative desk taps, campus drumline textures abstracted beyond recognizable style, river pulse, copier rhythm, precise network bass. |
| `music_columbus_boss_meaningful_review_loop` | Boss loop: formal civic motif repeatedly paused, rescheduled, rerouted, and restarted while statewide data rhythm never stops. |
| `stinger_columbus_hearing_rescheduled` | Hearing rescheduled: calendar mechanism flips, queue barrier moves, polite chime texture collapses into delay relay. |

## 7.8 New York City — The Five-Borough Omnigaze

| Asset | ElevenLabs prompt |
|---|---|
| `amb_new_york_city_identity_loop` | Seamless New York macro ambience without intelligible voices: subway ventilation, scaffolding, distant elevated rail, rooftop water tower creak, bridge traffic wash, digital billboard electricity, dense but mixable. |
| `amb_new_york_five_borough_network_loop` | Five distinct surveillance layers cycling: financial prediction, bridge handoff, airport-transit corridor, elevated institutional relay, toll-and-ferry checkpoint, then synchronized. |
| `music_new_york_combat_loop` | 120-second seamless high-density combat bed: subway percussion, scaffold metal, digital-screen harmonics, bridge cable bass, financial clock precision, urgent but not cinematic cliché. |
| `music_new_york_boss_five_borough_baron_loop` | Five-part boss suite loop where borough motifs argue, interrupt, and finally merge into one relentless real-time-city rhythm. |
| `stinger_new_york_borough_phase_change` | Borough phase switch: transit route changes, bridge relay or toll gate texture, digital network snaps into a new rhythmic identity. |
| `stinger_new_york_real_time_city` | All five systems fuse: subway, toll, billboard, rooftop relay, and financial prediction lock into one 5-second machine. |

## 7.9 Los Angeles — Thirty-Five Hundred Eyes, No One in Charge

| Asset | ElevenLabs prompt |
|---|---|
| `amb_los_angeles_city_identity_loop` | Seamless Los Angeles ambience: broad arterial wash, freeway overpass, dry palms, studio ventilation, distant port, hillside wind, parking-lot heat, basin haze translated into soft high-frequency air. |
| `amb_los_angeles_decentralized_network_loop` | Independent private networks activating asynchronously: HOA gate, mall security relay, studio floodlight, valet scanner, parking cabinet, port logistics pulse, no central rhythm at first. |
| `music_los_angeles_combat_loop` | Seamless combat bed with freeway tire rhythm, studio clapper-like percussion abstracted, parking-gate ticks, dry analog bass, fragmented modules passing control. |
| `music_los_angeles_boss_accountability_producer_loop` | Boss loop with many production layers entering and leaving, city system drops out while private systems continue, media-safe polish masking relentless pursuit. |
| `stinger_los_angeles_no_longer_contract` | Municipal system powers down with official finality, half-second silence, then five private networks switch on louder. |

## 7.10 Atlanta — Flock’s Nest

| Asset | ElevenLabs prompt |
|---|---|
| `amb_atlanta_city_identity_loop` | Seamless Atlanta ambience: humid tree canopy, downtown freeway trench, airport terminal systems, BeltLine movement, corporate campus HVAC, film soundstage, distant data-center cooling. |
| `amb_atlanta_national_convergence_loop` | National network layer: freeway routing, airport identity sorting, HOA relays, server racks, fiber trunks, prior-city motifs entering as faint recognizable callbacks and synchronizing. |
| `music_atlanta_combat_loop` | Seamless final-city combat bed using freeway rhythm, airport conveyor percussion, server cooling pulse, film reset clicks, corporate glass resonance, escalating network bass. |
| `music_atlanta_midboss_public_private_chimera_loop` | Three-part loop: municipal march-like machinery, polished HOA gate rhythm, vendor server pulse; all fuse while each denies control. |
| `music_atlanta_boss_phase_1_objective_evidence_loop` | Ordered server-cathedral loop: standardized metadata rhythm, archive drawers, precise plate-like percussion, persuasive and controlled. |
| `music_atlanta_boss_phase_2_one_network_loop` | Ten-city convergence music: prior city rhythmic signatures reconnect through fiber pulses into one huge synchronized network, seamless and escalating. |
| `music_atlanta_boss_phase_3_eliminate_crime_loop` | Severe predictive loop with duplicated player-path rhythm, suspicion never relaxing, narrow optimized pulse, no harmonic relief. |
| `music_atlanta_boss_phase_4_the_flock_loop` | Final frantic server-hive loop: thousands of small shutter-like wing rhythms, severable network pulses, cathedral-scale cooling roar, clear rhythmic openings for gameplay. |
| `stinger_atlanta_network_link_severed` | One national link severed: fiber snap, relay cascade failure, distant city motif drops out, brief vacuum. |
| `stinger_atlanta_final_blind_spot` | Final Blind Spot: all network noise folds inward, camera-bird rhythm collapses, server cathedral powers down edge by edge, then warm human-scale silence and one resolving analog tone. |

---

# 8. Boss and enemy signature library

These reusable signatures should be layered with city identity rather than generating wholly separate generic attacks for every enemy.

| Asset | ElevenLabs prompt |
|---|---|
| `sfx_enemy_bureaucrat_spawn` | Papers, badge clips, office chair wheel, relay activation, absurd but threatening. |
| `sfx_enemy_drone_flyby` | Compact surveillance drone pass, electric rotor, camera gimbal, no military missile character. |
| `sfx_enemy_gate_deploy` | Portable fence or checkpoint unfolds: aluminum frame, caster lock, motorized barrier snap. |
| `sfx_enemy_map_redact` | Thick marker-like scrape across glass, frequency band muted, paper seal. |
| `sfx_enemy_data_extract` | Pump or server siphon pulls data: vacuumed digital grit, valve pulse, hard-drive chatter. |
| `sfx_enemy_jurisdiction_handoff` | Two radio channels handshake without speech, relay transfer, new network tone takes over. |
| `sfx_enemy_predictive_target` | Future-position prediction: three ghost impulses ahead of the player, tight rising calculation texture. |
| `sfx_enemy_network_heal` | Recurring invoice heals a sensor: printer, approval stamp, power relay, machine returns online. |
| `sfx_boss_barrier_slam` | Massive municipal barrier closes: hydraulic movement, concrete resonance, metal lock. |
| `sfx_boss_server_pulse` | Cathedral-scale server pulse: cooling fans dip, low electrical wave, thousands of relays answer. |
| `sfx_boss_network_reconnect` | Defeated node reconnects: cable arcs, database handshake, layered city motif returns. |
| `sfx_boss_link_sever` | Network link destroyed: tensioned fiber break, data cascade, machinery desynchronizes. |

---

# 9. Menu, campaign, and meta audio

| Asset | ElevenLabs prompt |
|---|---|
| `music_menu_main_loop` | Seamless 90-second title loop: sparse analog surveillance pulse, distant parking-lot ambience, camera shutter percussion, dry satirical tension, memorable but understated. |
| `amb_menu_safehouse_loop` | Quiet hideout ambience: improvised electronics, fan, distant city, paper maps, soldering station, no speech. |
| `music_campaign_map_loop` | Seamless campaign map music: ten small rhythmic nodes connected by a restrained electronic pulse, grows subtly as cities unlock. |
| `stinger_city_unlocked` | New city unlocked: map relay connects, distant city-specific texture appears, compact determined flourish. |
| `stinger_city_completed` | City cleared: local surveillance motif powers down, one network link breaks, short forward-moving resolve. |
| `stinger_campaign_finale` | Campaign completion: ten city motifs disconnect, server noise falls away, warm strange release, no triumphant military fanfare. |
| `sfx_map_city_focus` | Campaign-map city focus: soft map pin mechanism, relay highlight, city-specific micro-texture. |
| `sfx_loadout_open` | Equipment drawer opens, paper file slides, compact electronics wake. |
| `sfx_loadout_equip` | Tool locks into improvised rig, magnetic latch, short confirmation pulse. |

---

# 10. Accessibility and mix requirements

1. Important gameplay events require unique transient envelopes, not only pitch changes.
2. Never encode critical state solely in stereo position or low frequency.
3. Provide mono-compatible masters for critical cues.
4. Music and ambience must duck beneath `player_damaged`, `suspicion_max`, `boss_activated`, and extraction cues.
5. Rapid-fire sounds need concurrency limits and variants.
6. Camera tracking loops must stop immediately when the entity is destroyed or leaves projection range.
7. Fog, network, and suspicion layers should be independently mixable rather than baked into city music.
8. Support user controls for master, music, SFX, UI/feedback, and ambience when the settings surface is implemented.
9. Physical-device testing is mandatory for audio-route interruption, silent-mode policy, Bluetooth, speaker distortion, and sustained thermal load.

---

# 11. Intake and integration workflow

1. Inventory existing audio files and hashes.
2. Match against this document; mark `REUSE_EXACT` or `REJECT_DUPLICATE` before generating.
3. Generate WAV masters in ElevenLabs using the prompts above.
4. Trim, de-click, remove DC offset, and create seamless loops.
5. Loudness-normalize by category.
6. Run mono and small-speaker checks.
7. Export approved delivery files.
8. Add only runtime-ready stems to the app bundle.
9. Update `audio_events.json` only when a corresponding deterministic simulation event exists.
10. Register bundle stems with `AudioCuePlayer.setAvailableAssets`.
11. Add catalog and mapping tests.
12. Device-test audio interruption and mixing.
13. Update this document’s status fields and manifest; do not claim completion from prompt generation alone.

---

# 12. Definition of done

The audio package is complete only when:

- all 11 current runtime-required stems exist and match exact names
- every shipped file has provenance and license metadata
- no duplicate semantic assets exist under different filenames
- all loops are seamless
- high-priority cues remain readable under maximum combat density
- each city is recognizable without narration
- each recurring district reuses shared layers rather than duplicating complete soundscapes
- bosses have distinct phase-readable audio
- Atlanta reuses approved prior-city callbacks instead of regenerating them
- runtime catalog entries have deterministic triggers and tests
- missing assets fail safely without changing simulation behavior
- physical iPhone audio-route and small-speaker tests pass
- the final manifest reports zero unresolved missing runtime-required assets
