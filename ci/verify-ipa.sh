#!/bin/bash
set -e
dir=$(mktemp -d)
unzip -q "$1" -d "$dir"
ex="$dir/Payload/CozyDaily.app/PlugIns/CozyWidgets.appex"
get() { /usr/libexec/PlistBuddy -c "Print :$2" "$1/Info.plist"; }
point=$(get "$ex" NSExtension:NSExtensionPointIdentifier)
app_id=$(get "$dir/Payload/CozyDaily.app" CFBundleIdentifier)
ex_id=$(get "$ex" CFBundleIdentifier)
exe=$(get "$ex" CFBundleExecutable)
echo "::notice::IPA widget: id=$ex_id app=$app_id point=$point type=$(get "$ex" CFBundlePackageType) minOS=$(get "$ex" MinimumOSVersion) arch=$(lipo -archs "$ex/$exe")"
[ "$point" = "com.apple.widgetkit-extension" ]
[[ "$ex_id" == "$app_id".* ]]
test -x "$ex/$exe"
codesign -d --entitlements - "$ex" 2>&1 | grep -q application-groups
