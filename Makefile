.PHONY: build run run-debug install clean test rebuild

APP_NAME = Voice2Text
BUNDLE_ID = com.voice2text.app
BUILD_DIR = .build/release
APP_BUNDLE = dist/$(APP_NAME).app
CONTENTS_DIR = $(APP_BUNDLE)/Contents
MACOS_DIR = $(CONTENTS_DIR)/MacOS
RESOURCES_DIR = $(CONTENTS_DIR)/Resources

build:
	@echo "Building $(APP_NAME)..."
	swift build -c release
	@echo "Packaging app bundle..."
	@mkdir -p $(MACOS_DIR) $(RESOURCES_DIR)
	@cp $(BUILD_DIR)/$(APP_NAME) $(MACOS_DIR)/
	@cp Info.plist $(CONTENTS_DIR)/
	@if [ -f Assets/AppIcon.icns ]; then cp Assets/AppIcon.icns $(RESOURCES_DIR)/; fi
	@echo "Signing app bundle..."
	codesign --deep --force --sign - $(APP_BUNDLE)
	@echo "✓ Build complete: $(APP_BUNDLE)"

rebuild: build

run:
	@if [ ! -d "$(APP_BUNDLE)" ]; then \
		$(MAKE) build; \
	fi
	@echo "Running existing $(APP_NAME) app bundle..."
	@open $(APP_BUNDLE)

run-debug:
	@if [ ! -d "$(APP_BUNDLE)" ]; then \
		$(MAKE) build; \
	fi
	@echo "Running $(APP_NAME) app bundle with debug logging enabled..."
	@open "$(APP_BUNDLE)" --args --debug-logging

install: build
	@echo "Installing $(APP_NAME) to /Applications..."
	@rm -rf /Applications/$(APP_NAME).app
	@cp -R $(APP_BUNDLE) /Applications/
	@echo "✓ Installed to /Applications/$(APP_NAME).app"

clean:
	@echo "Cleaning build artifacts..."
	@rm -rf .build dist
	@echo "✓ Clean complete"

test:
	@echo "Running tests..."
	swift test
