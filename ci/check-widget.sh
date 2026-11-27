#!/bin/bash
udid=$(xcrun simctl list devices available | grep -m1 -E "iPhone" | grep -oE '[0-9A-F-]{36}')
xcrun simctl boot "$udid"
xcrun simctl bootstatus "$udid" -b
xcrun simctl install "$udid" "$1" || { echo "::error::Không cài được app lên Simulator"; exit 1; }
xcrun simctl launch "$udid" com.cozydaily.app
sleep 20
list=$(xcrun simctl spawn "$udid" pluginkit -m -v -p com.apple.widgetkit-extension 2>&1)
echo "$list"
crashes=$(ls ~/Library/Logs/DiagnosticReports 2>/dev/null | grep -i cozy | tr '\n' ' ')
echo "::notice::pluginkit: $(echo "$list" | grep -i cozy | tr -s ' \t' ' ' | head -3) | crash: ${crashes:-không}"
echo "$list" | grep -q "com.cozydaily.app.widgets" || { echo "::error::iOS không đăng ký widget extension"; exit 1; }
