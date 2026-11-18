set shell := ["bash", "-euo", "pipefail", "-c"]

xcodebuild_cmd := "/usr/bin/env -i HOME=\"$HOME\" PATH=\"/usr/bin:/bin:/usr/sbin:/sbin\" DEVELOPER_DIR=\"$(/usr/bin/xcode-select -p)\" /usr/bin/xcodebuild"

default:
    just --list

test:
    swift test

build:
    {{xcodebuild_cmd}} -project 2048.xcodeproj -target 2048-iOS -sdk iphonesimulator -configuration Debug build CODE_SIGNING_ALLOWED=NO
    {{xcodebuild_cmd}} -project 2048.xcodeproj -target 2048-macOS -sdk macosx -configuration Debug build CODE_SIGNING_ALLOWED=NO

build-ios-device:
    {{xcodebuild_cmd}} -project 2048.xcodeproj -target 2048-iOS -sdk iphoneos -configuration Debug -destination 'generic/platform=iOS' -allowProvisioningUpdates build

build-macos:
    {{xcodebuild_cmd}} -quiet -project 2048.xcodeproj -target 2048-macOS -sdk macosx -configuration Debug build CODE_SIGNING_ALLOWED=NO

install-ios device_id: build-ios-device
    /usr/bin/xcrun devicectl device install app --device "{{device_id}}" build/Debug-iphoneos/2048.app

launch-macos: build-macos
    /usr/bin/open build/Debug/2048.app

run: launch-macos

pkg: build-macos
    /bin/mkdir -p dist
    /usr/bin/pkgbuild --component build/Debug/2048.app --install-location /Applications --identifier "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' build/Debug/2048.app/Contents/Info.plist)" --version 1.0.0 dist/2048.pkg

dmg: build-macos
    /bin/mkdir -p dist
    /usr/bin/hdiutil create -volname 2048 -srcfolder build/Debug/2048.app -ov -format UDZO dist/2048.dmg
