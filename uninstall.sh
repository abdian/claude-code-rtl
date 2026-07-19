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
# macOS LaunchAgent
rm -f "$HOME/Library/LaunchAgents/com.claude-code-rtl.plist" 2>/dev/null
launchctl remove com.claude-code-rtl 2>/dev/null || true
# Linux autostart + systemd path-unit
rm -f "$HOME/.config/autostart/claude-code-rtl.desktop" 2>/dev/null
if command -v systemctl >/dev/null 2>&1; then systemctl --user disable --now claude-code-rtl.path 2>/dev/null || true; fi
rm -f "$HOME/.config/systemd/user/claude-code-rtl.path" "$HOME/.config/systemd/user/claude-code-rtl.service" 2>/dev/null
# Windows (Git-Bash) Startup .vbs + scheduled task
rm -f "$HOME/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/ClaudeCodeRTL.vbs" 2>/dev/null
command -v schtasks >/dev/null 2>&1 && MSYS_NO_PATHCONV=1 schtasks /Delete /TN "ClaudeCodeRTL" /F >/dev/null 2>&1 || true
rm -rf "$HOME/.claude-code-rtl" 2>/dev/null

echo "Removed. Reload VSCode to see the original chat."
