#!/bin/bash
# Chạy xcodebuild, ghi log đầy đủ và đưa lỗi compile lên GitHub Annotations.
log="build-$RANDOM.log"
if ! xcodebuild "$@" > "$log" 2>&1; then
  grep -E "(error:|\*\* .* FAILED)" "$log" | sort -u | head -40 | while IFS= read -r line; do
    echo "::error::${line#"$GITHUB_WORKSPACE"/}"
  done
  tail -60 "$log"
  exit 1
fi
grep -E "(CozyDaily|CozyWidgets|Shared|CozyCore)/.*warning:" "$log" | sort -u | head -30
tail -5 "$log"
