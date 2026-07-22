.PHONY: generate test build validate

generate:
	xcodegen generate

test:
	swift test

build: generate
	xcodebuild -project SurveillanceSurvivor.xcodeproj -scheme SurveillanceSurvivor -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16 Pro' CODE_SIGNING_ALLOWED=NO build

validate: test build
