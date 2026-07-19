#!/usr/bin/env bash
# =============================================================================
# One-line installer (macOS · Linux · Git-Bash on Windows):
#
#   curl -fsSL https://raw.githubusercontent.com/abdian/claude-code-rtl/main/install.sh | bash
#
# No clone, no chmod, no Gatekeeper. Downloads the engine + font, applies the
# RTL patch, and turns on auto-apply so it survives Claude Code updates.
# =============================================================================
set -uo pipefail

RAW="https://raw.githubusercontent.com/abdian/claude-code-rtl/main"
DEST="$HOME/.claude-code-rtl"

ok(){ printf '\033[38;5;114m%s\033[0m\n' "$*"; }
info(){ printf '\033[38;5;80m%s\033[0m\n' "$*"; }
err(){ printf '\033[38;5;203m%s\033[0m\n' "$*"; }

get(){ # url  outfile
  if command -v curl >/dev/null 2>&1; then curl -fsSL "$1" -o "$2"
  elif command -v wget >/dev/null 2>&1; then wget -qO "$2" "$1"
  else err "need curl or wget"; return 1; fi
}

# 1) Claude Code installed?
if ! ls -d "$HOME/.vscode/extensions"/anthropic.claude-code-* >/dev/null 2>&1; then
  err "✘ Claude Code extension not found under ~/.vscode/extensions"
  echo "  Install the Claude Code extension in VSCode first, then run this again."
  exit 1
fi

# 2) fetch engine + font (repo layout, so scripts/apply.sh runs unchanged)
info "→ downloading Claude Code · RTL ..."
mkdir -p "$DEST/scripts" "$DEST/fonts"
get "$RAW/scripts/apply.sh" "$DEST/scripts/apply.sh" || { err "download failed (apply.sh)"; exit 1; }
get "$RAW/scripts/menu.sh"  "$DEST/scripts/menu.sh"  || { err "download failed (menu.sh)";  exit 1; }
get "$RAW/fonts/Vazir-Variable.ttf" "$DEST/fonts/Vazir-Variable.ttf" || { err "download failed (font)"; exit 1; }
chmod +x "$DEST/scripts/"*.sh 2>/dev/null || true

# 3) apply now
bash "$DEST/scripts/apply.sh" >/dev/null || { err "apply failed"; exit 1; }

# 4) auto-apply on every login (re-applies after each Claude Code update)
CORE="$DEST/scripts/apply.sh"
case "$(uname -s 2>/dev/null)" in
  Darwin)
    P="$HOME/Library/LaunchAgents/com.claude-code-rtl.plist"; mkdir -p "$(dirname "$P")"
    cat > "$P" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
 <key>Label</key><string>com.claude-code-rtl</string>
 <key>ProgramArguments</key><array><string>/bin/bash</string><string>$CORE</string></array>
 <key>RunAtLoad</key><true/>
 <key>WatchPaths</key><array><string>$HOME/.vscode/extensions</string></array>
</dict></plist>
EOF
    launchctl unload "$P" 2>/dev/null || true; launchctl load "$P" 2>/dev/null || true ;;
  Linux)
    # login autostart (works everywhere)
    D="$HOME/.config/autostart/claude-code-rtl.desktop"; mkdir -p "$(dirname "$D")"
    printf '[Desktop Entry]\nType=Application\nName=Claude Code RTL\nExec=bash "%s"\nX-GNOME-Autostart-enabled=true\n' "$CORE" > "$D"
    # plus a systemd user path-unit so it re-applies the instant the extensions dir changes
    if command -v systemctl >/dev/null 2>&1; then
      U="$HOME/.config/systemd/user"; mkdir -p "$U"
      printf '[Unit]\nDescription=Claude Code RTL re-apply\n[Service]\nType=oneshot\nExecStart=/bin/bash %s\n' "$CORE" > "$U/claude-code-rtl.service"
      printf '[Unit]\nDescription=Watch VSCode extensions for Claude Code updates\n[Path]\nPathModified=%s/.vscode/extensions\n[Install]\nWantedBy=default.target\n' "$HOME" > "$U/claude-code-rtl.path"
      systemctl --user daemon-reload 2>/dev/null || true
      systemctl --user enable --now claude-code-rtl.path 2>/dev/null || true
    fi ;;
  *)  # Git-Bash on Windows — detect the real bash.exe instead of hardcoding Program Files
    S="$HOME/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/ClaudeCodeRTL.vbs"; mkdir -p "$(dirname "$S")"
    BW="$(cygpath -w "$(command -v bash)" 2>/dev/null || echo 'C:\Program Files\Git\bin\bash.exe')"
    printf 'Set sh=CreateObject("WScript.Shell")\r\nsh.Run """%s"" -lc ""%s""",0,False\r\n' "$BW" "'$CORE'" > "$S" ;;
esac

echo
ok "✔ Installed. Claude Code chat is now right-to-left."
echo   "  Last step → reload VSCode:  Cmd/Ctrl + Shift + P  →  Developer: Reload Window"
echo   "  Options / uninstall later:  bash ~/.claude-code-rtl/scripts/menu.sh"
