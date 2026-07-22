.PHONY: generate privacy-check assets-check test build simulator-test device-smoke validate

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

simulator-test: generate
	@simulator_id="$$(bash scripts/select_available_iphone_simulator.sh)"; \
	xcodebuild -project SurveillanceSurvivor.xcodeproj -scheme SurveillanceSurvivor -sdk iphonesimulator -destination "platform=iOS Simulator,id=$$simulator_id" CODE_SIGNING_ALLOWED=NO test

device-smoke:
	@test -n "$(DEVICE_UDID)" || (echo "Usage: DEVICE_UDID=<connected-iPhone-UDID> make device-smoke" >&2; exit 64)
	bash scripts/run_device_smoke.sh "$(DEVICE_UDID)"

validate: privacy-check assets-check test simulator-test
