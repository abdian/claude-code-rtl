#!/usr/bin/env bash
# =============================================================================
# scripts/menu.sh — interactive installer UI. Windows · macOS · Linux.
#
# Launched by install-windows.cmd / install-macos.command in the repo root.
# This file only draws the menu and dispatches. Every real change is done by
# scripts/apply.sh (the engine) or by the enable/disable-startup helpers below.
# Nothing here touches the network — all writes are to local files in $HOME.
# =============================================================================
set -uo pipefail

# >>> your GitHub repo — shown in the banner. Edit if you fork/rename. <<<
REPO_URL="github.com/abdian/claude-code-rtl"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$HERE/apply.sh"        # the engine this menu drives (patch / --revert)
CONF="$HERE/claude-rtl.conf" # remembers the chosen font between runs (gitignored)

# Which shell env are we in? Only affects the login-hook + font paths, not the patch.
case "$(uname -s 2>/dev/null)" in
  Darwin)               OS=mac ;;
  MINGW*|MSYS*|CYGWIN*) OS=win ;;
  *)                    OS=linux ;;
esac

# Per-OS "run at login" hook. Enabling one re-applies the patch after every
# Claude Code update (an update lands in a NEW folder and wipes the old patch).
WIN_STARTUP="$HOME/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/ClaudeCodeRTL.vbs"
MAC_PLIST="$HOME/Library/LaunchAgents/com.claude-code-rtl.plist"
LINUX_DESKTOP="$HOME/.config/autostart/claude-code-rtl.desktop"

# ANSI colors — auto-disabled when stdout is not a terminal (e.g. piped to a file).
if [ -t 1 ]; then
  E=$'\033'; R="$E[0m"; B="$E[1m"; D="$E[2m"
  ORANGE="$E[38;5;209m"; CYAN="$E[38;5;80m"; GREEN="$E[38;5;114m"
  RED="$E[38;5;203m"; GRAY="$E[38;5;244m"; WHITE="$E[38;5;255m"
else
  R=""; B=""; D=""; ORANGE=""; CYAN=""; GREEN=""; RED=""; GRAY=""; WHITE=""
fi

# Wait for a keypress so the result stays on screen before redrawing the menu.
pause() { echo; read -n 1 -r -s -p "$(printf "${GRAY}   Press any key to continue...${R}")"; echo; }

# The installed extension's semver, with the "-win32-x64" platform suffix trimmed.
detect_version() {
  local d; d=$(ls -d "$HOME/.vscode/extensions"/anthropic.claude-code-* 2>/dev/null | sort -V | tail -1)
  [ -n "$d" ] && basename "$d" | sed -E 's/anthropic.claude-code-//; s/-(win32|darwin|linux)-.*$//' || echo "not found"
}
# The font currently recorded in claude-rtl.conf (defaults to Vazir before first pick).
current_font() { if [ -f "$CONF" ]; then . "$CONF"; echo "${FONT_LABEL:-Vazir}"; else echo "Vazir"; fi; }
# True (exit 0) when the login hook for this OS is installed.
startup_on() {
  case "$OS" in win) [ -f "$WIN_STARTUP" ] ;; mac) [ -f "$MAC_PLIST" ] ;; linux) [ -f "$LINUX_DESKTOP" ] ;; esac
}

# The orange title box "Claude Code · RTL". Uses box-drawing glyphs, so the
# console must be UTF-8 (install-windows.cmd sets `chcp 65001` for this reason).
banner() {
  printf "\n"
  printf "${ORANGE}${B}   ╭────────────────────────────╮${R}\n"
  printf "${ORANGE}${B}   │      Claude Code · RTL     │${R}\n"
  printf "${ORANGE}${B}   ╰────────────────────────────╯${R}\n"
  printf "   ${D}right-to-left  +  Vazir font${R}\n"
  printf "   ${CYAN}⌘ %s${R}\n" "$REPO_URL"
  printf "\n"
}
# A thin horizontal separator under section titles.
rule() { printf "${GRAY}   ────────────────────────────────────────────${R}\n"; }

# The live status block: OS, extension version, chosen font, auto-apply on/off.
status_panel() {
  local st stc
  if startup_on; then st="● enabled"; stc="$GREEN"; else st="○ disabled"; stc="$GRAY"; fi
  printf "${GRAY}${B}   STATUS${R}\n"; rule
  printf "     ${GRAY}%-13s${R}${WHITE}%s${R}\n" "OS"         "$OS"
  printf "     ${GRAY}%-13s${R}${WHITE}%s${R}\n" "Extension"  "$(detect_version)"
  printf "     ${GRAY}%-13s${R}${WHITE}%s${R}\n" "Font"       "$(current_font)"
  printf "     ${GRAY}%-13s${R}${stc}%s${R}\n"   "Auto-apply" "$st"
  printf "\n"
}
# Render one menu row:  [key]  label        dim right-hand help text
item() { printf "     ${ORANGE}${B}[%s]${R} ${WHITE}%-24s${R}${D}%s${R}\n" "$1" "$2" "$3"; }

# Save the font choice so the engine — and the auto-apply hook — reuse it later.
write_conf() { cat > "$CONF" <<EOF
FONT_LABEL="$1"
FONT_REG_FILE="$2"
FONT_BOLD_FILE="$3"
FONT_VARIABLE=$4
EOF
}

# [1] Apply the patch AND turn on auto-apply (the recommended one-tap action).
apply_now() {
  echo; echo "   Applying..."
  if bash "$CORE"; then
    enable_startup >/dev/null 2>&1   # option 1 also enables auto-apply
    printf "   ${GREEN}✔ done${R} ${D}— RTL + font on, auto-apply on.\n"
    printf "     Reload VSCode: Ctrl/Cmd + Shift + P -> Developer: Reload Window${R}\n"
  else printf "   ${RED}✘ error${R}\n"; fi
}

# [5] Undo everything: strip our CSS block and delete the copied font files,
#     leaving the extension exactly as it shipped. Does NOT touch auto-apply.
reset_now() {
  echo; echo "   Resetting to original..."
  if bash "$CORE" --revert; then printf "   ${GREEN}✔ removed RTL + font${R}  ${D}(reload VSCode)${R}\n"
  else printf "   ${RED}✘ error${R}\n"; fi
}

# [2] Sub-menu: pick the bundled Vazir, or fall back to the system font. Has Back.
choose_font() {
  while true; do
    clear; banner
    printf "${GRAY}${B}   CHANGE FONT${R}\n"; rule
    item 1 "Vazir"          "bundled, recommended"
    item 2 "System default" "no bundled font (VSCode's own)"
    item 0 "Back"           "keep current, return"
    printf "\n"
    read -r -p "$(printf "${ORANGE}${B}   ❯${R} Choose [0-2]: ")" f
    case "$f" in
      1) write_conf "Vazir"    "Vazir-Variable.ttf" "" 1; apply_now; pause; return ;;
      2) write_conf "Segoe UI" ""                   "" 0; apply_now; pause; return ;;
      0) return ;;
      *) : ;;
    esac
  done
}

# [3] Install the login hook so the patch survives Claude Code updates.
enable_startup() {
  case "$OS" in
    win)  # logon: hidden .vbs in the Startup folder (no admin)
      mkdir -p "$(dirname "$WIN_STARTUP")"
      # find the real bash.exe wherever Git is installed (don't hardcode Program Files)
      local BASH_WIN; BASH_WIN="$(cygpath -w "$(command -v bash)" 2>/dev/null || echo 'C:\Program Files\Git\bin\bash.exe')"
      cat > "$WIN_STARTUP" <<EOF
' Claude Code RTL: silently re-apply at every Windows logon.
Set sh = CreateObject("WScript.Shell")
sh.Run """$BASH_WIN"" -lc ""'$CORE'""", 0, False
EOF
      # mid-session updates: a scheduled task every 10 min (MINUTE needs no admin; ONLOGON does)
      local VBS_WIN; VBS_WIN="$(cygpath -w "$WIN_STARTUP" 2>/dev/null)"
      MSYS_NO_PATHCONV=1 schtasks /Create /TN "ClaudeCodeRTL" /TR "wscript.exe \"$VBS_WIN\"" /SC MINUTE /MO 10 /F >/dev/null 2>&1 || true
      ;;
    mac)  # LaunchAgent: run at login AND whenever the extensions folder changes (updates)
      mkdir -p "$HOME/Library/LaunchAgents"
      cat > "$MAC_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.claude-code-rtl</string>
  <key>ProgramArguments</key>
  <array><string>/bin/bash</string><string>$CORE</string></array>
  <key>RunAtLoad</key><true/>
  <key>WatchPaths</key><array><string>$HOME/.vscode/extensions</string></array>
</dict></plist>
EOF
      launchctl unload "$MAC_PLIST" 2>/dev/null || true
      launchctl load "$MAC_PLIST" 2>/dev/null || true ;;
    linux)  # login: freedesktop autostart entry (works everywhere)
      mkdir -p "$HOME/.config/autostart"
      cat > "$LINUX_DESKTOP" <<EOF
[Desktop Entry]
Type=Application
Name=Claude Code RTL
Exec=bash "$CORE"
X-GNOME-Autostart-enabled=true
EOF
      # mid-session updates: systemd user path-unit that fires when the extensions dir changes
      if command -v systemctl >/dev/null 2>&1; then
        mkdir -p "$HOME/.config/systemd/user"
        printf '[Unit]\nDescription=Claude Code RTL re-apply\n[Service]\nType=oneshot\nExecStart=/bin/bash %s\n' "$CORE" > "$HOME/.config/systemd/user/claude-code-rtl.service"
        printf '[Unit]\nDescription=Watch VSCode extensions for Claude Code updates\n[Path]\nPathModified=%s/.vscode/extensions\n[Install]\nWantedBy=default.target\n' "$HOME" > "$HOME/.config/systemd/user/claude-code-rtl.path"
        systemctl --user daemon-reload 2>/dev/null || true
        systemctl --user enable --now claude-code-rtl.path 2>/dev/null || true
      fi
      ;;
  esac
  printf "   ${GREEN}✔ auto-apply enabled${R}\n"
}

# Remove the login hook (the current patch stays; it just won't re-apply).
disable_startup() {
  case "$OS" in
    win)   rm -f "$WIN_STARTUP"; MSYS_NO_PATHCONV=1 schtasks /Delete /TN "ClaudeCodeRTL" /F >/dev/null 2>&1 || true ;;
    mac)   launchctl unload "$MAC_PLIST" 2>/dev/null || true; rm -f "$MAC_PLIST" ;;
    linux) rm -f "$LINUX_DESKTOP"
           if command -v systemctl >/dev/null 2>&1; then systemctl --user disable --now claude-code-rtl.path 2>/dev/null || true; fi
           rm -f "$HOME/.config/systemd/user/claude-code-rtl.path" "$HOME/.config/systemd/user/claude-code-rtl.service" ;;
  esac
  printf "   ${GRAY}○ auto-apply disabled${R}\n"
}

# [3] Flip auto-apply on/off depending on its current state.
toggle_startup() { if startup_on; then disable_startup; else enable_startup; fi; }

# ---- main loop --------------------------------------------------------------
while true; do
  clear; banner
  status_panel
  if startup_on; then a3="Disable auto-apply"; a3h="currently ON — stop re-applying"
  else               a3="Enable auto-apply";  a3h="currently OFF — re-apply after updates"; fi
  printf "${GRAY}${B}   MENU${R}\n"; rule
  item 1 "Apply now"          "RTL + font  (+ auto-apply)"
  item 2 "Change font"        "current: $(current_font)"
  item 3 "$a3"                "$a3h"
  item 4 "Reset to original"  "undo — remove everything"
  item 0 "Exit"               "quit"
  printf "\n"
  read -r -p "$(printf "${ORANGE}${B}   ❯${R} Choose [0-4]: ")" c
  case "$c" in
    1) apply_now;            pause ;;
    2) choose_font ;;
    3) echo; toggle_startup; pause ;;
    4) reset_now;            pause ;;
    0) printf "\n${CYAN}   Bye 👋${R}\n\n"; exit 0 ;;
    *) : ;;
  esac
done
