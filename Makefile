.PHONY: generate version-check privacy-check assets-check sprite-chroma-check audio-check weapon-vfx-check animation-check director-check city-state-check build-engine-check coordination-check story-check interactables-check landmark-check clearing-builds-check test build simulator-test simulator-smoke emulator-test device-smoke validate

generate:
	xcodegen generate

version-check:
	python3 scripts/validate_versions.py

privacy-check:
	plutil -lint App/PrivacyInfo.xcprivacy

assets-check:
	@if [[ -d Resources/RuntimeSprites ]] && compgen -G "Resources/RuntimeSprites/*.png" >/dev/null; then \
		bash scripts/validate_visual_assets.sh Resources/RuntimeSprites; \
	else \
		bash scripts/validate_visual_assets.sh --allow-empty Resources; \
	fi

sprite-chroma-check:
	python3 scripts/validate_sprite_chroma.py

audio-check:
	python3 scripts/validate_audio_manifest.py

weapon-vfx-check:
	python3 scripts/validate_weapon_vfx_manifest.py

animation-check:
	python3 scripts/validate_gameplay_animation_manifest.py

director-check:
	python3 scripts/validate_director_rules.py

city-state-check:
	python3 scripts/validate_infrastructure_nodes.py

build-engine-check:
	python3 scripts/validate_build_synergies.py

coordination-check:
	python3 scripts/validate_coordination_graphs.py

story-check:
	python3 scripts/validate_story_fact_rules.py

interactables-check:
	python3 scripts/validate_interactables.py

landmark-check:
	python3 scripts/validate_landmark_encounters.py

clearing-builds-check:
	python3 scripts/validate_clearing_builds.py

test:
	swift test

build: generate
	@simulator_id="$$(bash scripts/select_available_iphone_simulator.sh)"; \
	xcodebuild -project SurveillanceSurvivor.xcodeproj -scheme SurveillanceSurvivor -sdk iphonesimulator -destination "platform=iOS Simulator,id=$$simulator_id" CODE_SIGNING_ALLOWED=NO build

# Unit + UI tests on a booted/available iPhone Simulator.
simulator-test: generate
	@simulator_id="$$(bash scripts/select_available_iphone_simulator.sh)"; \
	echo "simulator-test destination: $$simulator_id"; \
	xcodebuild -project SurveillanceSurvivor.xcodeproj -scheme SurveillanceSurvivor -sdk iphonesimulator -destination "platform=iOS Simulator,id=$$simulator_id" CODE_SIGNING_ALLOWED=NO test

# Build, install, launch, settle, screenshot, and confirm the process stays up.
simulator-smoke: generate
	bash scripts/run_simulator_smoke.sh

# Full automated emulator gate: package + simulator tests + launch smoke.
emulator-test:
	bash scripts/run_emulator_suite.sh

device-smoke:
	@test -n "$(DEVICE_UDID)" || (echo "Usage: DEVICE_UDID=<connected-iPhone-UDID> make device-smoke" >&2; exit 64)
	bash scripts/run_device_smoke.sh "$(DEVICE_UDID)"

# CI-parity local gate (no launch smoke; faster, matches GitHub Actions core path).
validate: version-check privacy-check assets-check sprite-chroma-check audio-check weapon-vfx-check animation-check director-check city-state-check build-engine-check coordination-check story-check interactables-check landmark-check clearing-builds-check test simulator-test
