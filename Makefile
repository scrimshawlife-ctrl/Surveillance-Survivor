.PHONY: generate version-check privacy-check release-docs-check assets-check sprite-chroma-check audio-check weapon-vfx-check animation-check director-check city-state-check build-engine-check coordination-check story-check interactables-check landmark-check clearing-builds-check city-rules-check challenge-contracts-check unlockables-check art-qa-check launch-gate-check simulator-launch-retry-test repo-status-check repo-status-refresh qa-schema-test qa-baseline-check qa-baseline-refresh test build simulator-test simulator-smoke simulator-visual-stress simulator-visual-matrix emulator-test device-smoke device-ui-test device-test device-accept validate

QA_SWIFT_LOG ?= swift-test.log
QA_SIMULATOR_LOG ?= unit-xcodebuild.log
QA_UI_LOG ?= ui-xcodebuild.log

generate:
	xcodegen generate

version-check:
	python3 scripts/validate_versions.py

privacy-check:
	plutil -lint App/PrivacyInfo.xcprivacy

release-docs-check:
	python3 scripts/validate_release_docs.py

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

city-rules-check:
	python3 scripts/validate_city_systemic_rules.py

challenge-contracts-check:
	python3 scripts/validate_challenge_contracts.py

unlockables-check:
	python3 scripts/validate_unlockables.py

art-qa-check:
	python3 scripts/validate_art_qa_package.py

launch-gate-check:
	python3 scripts/validate_launch_gates.py

simulator-launch-retry-test:
	python3 scripts/test_simctl_launch_retry.py

repo-status-check:
	python3 scripts/check_repo_status_tip.py

# Updates only the documented SHA. Review human-owned evidence and gate language before commit.
repo-status-refresh:
	python3 scripts/check_repo_status_tip.py --refresh

qa-schema-test:
	python3 -m unittest discover -s scripts/tests -p 'test_*.py'

qa-baseline-check:
	python3 scripts/refresh_qa_baseline.py --swift-log "$(QA_SWIFT_LOG)" --simulator-log "$(QA_SIMULATOR_LOG)" --ui-log "$(QA_UI_LOG)"

qa-baseline-refresh:
	python3 scripts/refresh_qa_baseline.py --write --swift-log "$(QA_SWIFT_LOG)" --simulator-log "$(QA_SIMULATOR_LOG)" --ui-log "$(QA_UI_LOG)"

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

# Deterministic max-density visual evidence. Simulator-only, not a device ART pass.
simulator-visual-stress: generate
	SIMULATOR_SMOKE_SCENARIO=density SIMULATOR_SMOKE_ARTIFACTS=.simulator-visual-stress bash scripts/run_simulator_smoke.sh

simulator-visual-matrix:
	bash scripts/run_simulator_visual_matrix.sh

# Full automated emulator gate: package + simulator tests + launch smoke.
emulator-test:
	bash scripts/run_emulator_suite.sh

# Physical device: signed build + install + launch + process liveness (+ receipt).
# DEVICE_UDID optional — auto-selects first connected paired iPhone when omitted.
device-smoke: generate
	@device_udid="$(DEVICE_UDID)"; \
	if [[ -z "$$device_udid" ]]; then device_udid="$$(bash scripts/select_connected_iphone.sh)"; fi; \
	echo "device-smoke destination: $$device_udid"; \
	DEVICE_UDID="$$device_udid" bash scripts/run_device_smoke.sh "$$device_udid"

# Physical device XCUITests only (LaunchUITests chrome). Requires unlock + DEVELOPMENT_TEAM.
device-ui-test: generate
	@device_udid="$(DEVICE_UDID)"; \
	if [[ -z "$$device_udid" ]]; then device_udid="$$(bash scripts/select_connected_iphone.sh)"; fi; \
	team="$(DEVELOPMENT_TEAM)"; \
	if [[ -z "$$team" ]]; then team="X9M969D8M3"; fi; \
	echo "device-ui-test destination: $$device_udid team=$$team"; \
	rm -rf .device-smoke/DeviceUITests.xcresult; \
	mkdir -p .device-smoke; \
	xcodebuild \
	  -project SurveillanceSurvivor.xcodeproj \
	  -scheme SurveillanceSurvivor \
	  -destination "platform=iOS,id=$$device_udid" \
	  -derivedDataPath /private/tmp/surveillance-survivor-device-ui-derived-data \
	  -only-testing:SurveillanceSurvivorUITests \
	  -resultBundlePath .device-smoke/DeviceUITests.xcresult \
	  -allowProvisioningUpdates \
	  CODE_SIGN_STYLE=Automatic \
	  DEVELOPMENT_TEAM=$$team \
	  CODE_SIGNING_ALLOWED=YES \
	  test

# Full automated physical suite: smoke + UI tests + device-receipt.json.
# Does NOT replace operator ART checklist visual sign-off for ship_gate.
device-test:
	bash scripts/run_device_suite.sh

# Mechanical Blind Spot extract automation on device (force-extract UITest).
# ART readability + owner #3 ship note still required for ART_SHIP_APPROVED.
device-accept:
	bash scripts/run_device_acceptance.sh

# CI-parity local gate (no launch smoke; faster, matches GitHub Actions core path).
validate: version-check privacy-check release-docs-check assets-check sprite-chroma-check audio-check weapon-vfx-check animation-check director-check city-state-check build-engine-check coordination-check story-check interactables-check landmark-check clearing-builds-check city-rules-check challenge-contracts-check unlockables-check art-qa-check launch-gate-check repo-status-check qa-schema-test test simulator-test
