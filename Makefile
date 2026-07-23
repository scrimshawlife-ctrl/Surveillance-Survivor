.PHONY: generate privacy-check assets-check test build simulator-test simulator-smoke emulator-test device-smoke validate

generate:
	xcodegen generate

privacy-check:
	plutil -lint App/PrivacyInfo.xcprivacy

assets-check:
	bash scripts/validate_visual_assets.sh --allow-empty Resources

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
validate: privacy-check assets-check test simulator-test
