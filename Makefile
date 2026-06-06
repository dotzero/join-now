PROJECT := JoinNow.xcodeproj
SCHEME := JoinNow
DERIVED_DATA_PATH := /private/tmp/joinnow-derived-data
APP_NAME := JoinNow
DIST_DIR := dist
RELEASE_DERIVED_DATA_PATH := /private/tmp/joinnow-release-derived-data
VERSION := $(shell plutil -extract CFBundleShortVersionString raw -o - JoinNow/Info.plist)
RELEASE_APP := $(RELEASE_DERIVED_DATA_PATH)/Build/Products/Release/$(APP_NAME).app
PACKAGE_NAME := $(APP_NAME)-$(VERSION)
ZIP_PATH := $(DIST_DIR)/$(PACKAGE_NAME).zip

.PHONY: test lint swiftformat swiftlint check build release package clean-dist

build:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Debug -derivedDataPath $(DERIVED_DATA_PATH) build

release:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Release -derivedDataPath $(RELEASE_DERIVED_DATA_PATH) -destination generic/platform=macOS build

package: release
	rm -rf "$(DIST_DIR)"
	mkdir -p "$(DIST_DIR)"
	ditto "$(RELEASE_APP)" "$(DIST_DIR)/$(APP_NAME).app"
	cd "$(DIST_DIR)" && ditto -c -k --keepParent --sequesterRsrc --zlibCompressionLevel 9 "$(APP_NAME).app" "$(PACKAGE_NAME).zip"
	@echo "Created $(ZIP_PATH)"

clean-dist:
	rm -rf "$(DIST_DIR)"

test:
	xcodebuild test -project $(PROJECT) -scheme $(SCHEME) -configuration Debug -derivedDataPath $(DERIVED_DATA_PATH)

swiftformat:
	swiftformat --lint . --cache ignore

swiftlint:
	swiftlint --strict --no-cache --config .swiftlint.yml

lint: swiftformat swiftlint

check: lint test
