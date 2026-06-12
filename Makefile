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

.PHONY: help build release test lint check package dist-check dist-release clean-build clean-dist clean

.DEFAULT_GOAL := help

help: ## Show this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_\-\.]+:.*?## / {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

all: release package ## Run release, package

---------------: ## ---------------

build: clean-build ## Build the app in Debug configuration
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Debug -derivedDataPath $(DERIVED_DATA_PATH) build

release: clean-build ## Build the app in Release configuration
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Release -derivedDataPath $(DERIVED_DATA_PATH) -destination generic/platform=macOS build

---------------: ## ---------------

test: ## Run tests
	xcodebuild test -project $(PROJECT) -scheme $(SCHEME) -configuration Debug -derivedDataPath $(DERIVED_DATA_PATH)

lint: ## Run linting
	swiftformat JoinNow JoinNowTests --lint --cache ignore
	swiftlint --strict --no-cache --config .swiftlint.yml

check: lint test ## Run linting and tests

---------------: ## ---------------

package: clean-dist release ## Package the app into ZIP and DMG formats
	ditto "$(RELEASE_APP)" "$(DIST_DIR)/$(APP_NAME).app"
	cd "$(DIST_DIR)" && ditto -c -k --keepParent --sequesterRsrc --zlibCompressionLevel 9 "$(APP_NAME).app" "$(PACKAGE_NAME).zip"
	mkdir -p "$(DMG_STAGING_DIR)"
	ditto "$(DIST_DIR)/$(APP_NAME).app" "$(DMG_STAGING_DIR)/$(APP_NAME).app"
	create-dmg \
		--volname "$(APP_NAME)" \
		--window-pos 200 120 \
		--window-size 480 560 \
		--icon "$(APP_NAME).app" 240 130 \
		--hide-extension "$(APP_NAME).app" \
		--app-drop-link 240 380 \
		"$(DMG_PATH)" \
		"$(DMG_STAGING_DIR)"
	rm -rf "$(DMG_STAGING_DIR)"
	@echo "Created $(ZIP_PATH)"
	@echo "Created $(DMG_PATH)"

dist-check:
	goreleaser release --snapshot --clean

dist-release:
	goreleaser release --clean

clean-build:
	rm -rf "$(DERIVED_DATA_PATH)"
	mkdir -p "$(DERIVED_DATA_PATH)"

clean-dist:
	rm -rf "$(DIST_DIR)"
	mkdir -p "$(DIST_DIR)"

clean: clean-build clean-dist ## Clean build and dist directories
