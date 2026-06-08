APP_NAME := JoinNow
PROJECT := JoinNow.xcodeproj
SCHEME := JoinNow
DERIVED_DATA_PATH := build
DIST_DIR := dist
DMG_STAGING_DIR := $(DIST_DIR)/dmg
RELEASE_APP := $(DERIVED_DATA_PATH)/Build/Products/Release/$(APP_NAME).app
VERSION := $(shell plutil -extract CFBundleShortVersionString raw -o - JoinNow/Info.plist)
PACKAGE_NAME := $(APP_NAME)-$(VERSION)
ZIP_PATH := $(DIST_DIR)/$(PACKAGE_NAME).zip
DMG_PATH := $(DIST_DIR)/$(PACKAGE_NAME).dmg

.PHONY: test lint check build release package clean-dist clean-build

build: clean-build
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Debug -derivedDataPath $(DERIVED_DATA_PATH) build

release: clean-build
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Release -derivedDataPath $(DERIVED_DATA_PATH) -destination generic/platform=macOS build

package: clean-dist release
	ditto "$(RELEASE_APP)" "$(DIST_DIR)/$(APP_NAME).app"
	cd "$(DIST_DIR)" && ditto -c -k --keepParent --sequesterRsrc --zlibCompressionLevel 9 "$(APP_NAME).app" "$(PACKAGE_NAME).zip"
	mkdir -p "$(DMG_STAGING_DIR)"
	ditto "$(DIST_DIR)/$(APP_NAME).app" "$(DMG_STAGING_DIR)/$(APP_NAME).app"
	create-dmg \
		--volname "$(APP_NAME)" \
		--window-pos 200 120 \
		--window-size 480 540 \
		--icon "$(APP_NAME).app" 240 130 \
		--hide-extension "$(APP_NAME).app" \
		--app-drop-link 240 380 \
		"$(DMG_PATH)" \
		"$(DMG_STAGING_DIR)"
	rm -rf "$(DMG_STAGING_DIR)"
	@echo "Created $(ZIP_PATH)"
	@echo "Created $(DMG_PATH)"

clean-build:
	rm -rf "$(DERIVED_DATA_PATH)"
	mkdir -p "$(DERIVED_DATA_PATH)"

clean-dist:
	rm -rf "$(DIST_DIR)"
	mkdir -p "$(DIST_DIR)"

test:
	xcodebuild test -project $(PROJECT) -scheme $(SCHEME) -configuration Debug -derivedDataPath $(DERIVED_DATA_PATH)

lint:
	swiftformat --lint . --cache ignore
	swiftlint --strict --no-cache --config .swiftlint.yml

check: lint test
