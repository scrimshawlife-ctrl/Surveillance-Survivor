.PHONY: generate test build simulator-test device-smoke validate

generate:
	xcodegen generate

test:
	swift test

build: generate
	xcodebuild -project SurveillanceSurvivor.xcodeproj -scheme SurveillanceSurvivor -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16 Pro' CODE_SIGNING_ALLOWED=NO build

simulator-test: generate
	xcodebuild -project SurveillanceSurvivor.xcodeproj -scheme SurveillanceSurvivor -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16 Pro' CODE_SIGNING_ALLOWED=NO test

device-smoke:
	@test -n "$(DEVICE_UDID)" || (echo "Usage: DEVICE_UDID=<connected-iPhone-UDID> make device-smoke" >&2; exit 64)
	bash scripts/run_device_smoke.sh "$(DEVICE_UDID)"

validate: test simulator-test
