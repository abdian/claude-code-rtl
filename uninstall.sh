#!/usr/bin/env bash
# =============================================================================
# One-line uninstall (macOS · Linux · Git-Bash on Windows):
#   curl -fsSL https://raw.githubusercontent.com/abdian/claude-code-rtl/main/uninstall.sh | bash
# Removes the RTL block + font from every Claude Code webview, stops auto-apply,
# and deletes the installed files.
# =============================================================================
set -uo pipefail

# 1) revert every webview (use the installed engine if present, else strip inline)
if [ -f "$HOME/.claude-code-rtl/scripts/apply.sh" ]; then
  bash "$HOME/.claude-code-rtl/scripts/apply.sh" --revert >/dev/null 2>&1 || true
else
  for DIR in "$HOME/.vscode/extensions"/anthropic.claude-code-*; do
    CSS="$DIR/webview/index.css"; [ -f "$CSS" ] || continue
    awk 'BEGIN{s=0} /(claude-code|esanj)-rtl start/{s=1} s==0{print} /(claude-code|esanj)-rtl end/{s=0}' "$CSS" > "$CSS.tmp" && mv -f "$CSS.tmp" "$CSS"
    rm -f "$DIR/webview/ccrtl-font-regular.ttf" "$DIR/webview/esanj-font-regular.ttf" 2>/dev/null
  done
fi

# 2) stop auto-apply (all OSes) and remove installed files
rm -f "$HOME/Library/LaunchAgents/com.claude-code-rtl.plist" 2>/dev/null
launchctl remove com.claude-code-rtl 2>/dev/null || true
rm -f "$HOME/.config/autostart/claude-code-rtl.desktop" 2>/dev/null
rm -f "$HOME/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/ClaudeCodeRTL.vbs" 2>/dev/null
rm -rf "$HOME/.claude-code-rtl" 2>/dev/null

echo "Removed. Reload VSCode to see the original chat."
