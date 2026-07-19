#!/usr/bin/env bash
# =============================================================================
# scripts/apply.sh — the engine (non-interactive). Windows · macOS · Linux.
#
# WHAT IT DOES
#   Appends a small, clearly-marked CSS block to the Claude Code VSCode webview
#   stylesheet so chat messages read right-to-left, and copies a font next to it.
#     apply.sh            apply / update   (reads scripts/claude-rtl.conf)
#     apply.sh --revert   remove the block + the copied fonts
#
# WHY PATCH A FILE (and not ship a VSCode extension)
#   The chat is a sandboxed <iframe> webview. No extension API can style another
#   extension's webview, and workbench "custom CSS" loaders never reach the iframe.
#   Editing the extension's own index.css on disk is the only thing that works.
#
# THREE THINGS THAT MAKE IT SAFE / PORTABLE (don't "simplify" these away):
#   1. RTL is scoped to TEXT elements of [data-testid="assistant-message"] only,
#      never the whole message container. If you set direction:rtl on the box,
#      the Monaco code/diff editors inside get shifted and render as BLANK boxes.
#      Code/diff/Monaco are additionally forced back to LTR as a belt-and-braces.
#   2. The font is bundled INSIDE the webview folder and referenced with a relative
#      url(). The webview CSP allows font-src only from the extension directory, so
#      a system-installed or remote font would be blocked — copying it in is required.
#   3. The block is stripped with awk + a temp file, NOT `sed -i`. macOS ships BSD
#      sed where `-i` needs an argument (`sed -i ''`), so `sed -i` is non-portable.
#
# Idempotent: re-running strips the old block first, so it never duplicates.
# You normally don't call this directly — use the installer menu (scripts/menu.sh).
# =============================================================================
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # scripts/
ROOT="$(cd "$HERE/.." && pwd)"                          # repo root
MARK_START="/* claude-code-rtl start */"                # sentinel that brackets our block
CONF="$HERE/claude-rtl.conf"                            # runtime font choice (gitignored)
FONTBUNDLE="$ROOT/fonts"                                # shipped + user-added .ttf files
FONT_FAMILY="ClaudeCodeRTL"                             # @font-face family name we define
FONT_REG_OUT="ccrtl-font-regular.ttf"                   # font copied into the webview
FONT_BOLD_OUT="ccrtl-font-bold.ttf"

# ---- detect OS (used for font search paths only; the patch itself is identical) --
case "$(uname -s 2>/dev/null)" in
  Darwin)               OS=mac ;;
  MINGW*|MSYS*|CYGWIN*) OS=win ;;
  *)                    OS=linux ;;
esac

# ---- font defaults; overridden by claude-rtl.conf if the user picked another ----
FONT_LABEL="Vazir"                 # shown in the menu STATUS
FONT_REG_FILE="Vazir-Variable.ttf" # a variable font covers every weight in one file
FONT_BOLD_FILE=""                  # only used for non-variable fonts
FONT_VARIABLE=1
[ -f "$CONF" ] && . "$CONF"

MODE="${1:-apply}"

# VSCode keeps extensions under the same relative path on every OS; also cover
# Insiders and the Remote/WSL server layout.
EXT_ROOTS=(
  "$HOME/.vscode/extensions"
  "$HOME/.vscode-insiders/extensions"
  "$HOME/.vscode-server/extensions"
)

# Find a font file: prefer the repo bundle, then fall back to the OS font folders.
resolve_font() { # $1 = filename -> echoes a full path, or empty if not found anywhere
  [ -z "$1" ] && return 0
  local cands=("$FONTBUNDLE/$1")
  case "$OS" in
    win)   cands+=("$HOME/AppData/Local/Microsoft/Windows/Fonts/$1" "/c/Windows/Fonts/$1") ;;
    mac)   cands+=("$HOME/Library/Fonts/$1" "/Library/Fonts/$1" "/System/Library/Fonts/Supplemental/$1") ;;
    linux) cands+=("$HOME/.local/share/fonts/$1" "/usr/share/fonts/$1") ;;
  esac
  local c; for c in "${cands[@]}"; do [ -f "$c" ] && { echo "$c"; return 0; }; done
  echo ""
}

# Remove our block in place, portably (see note #3 above). Matches the current
# marker and the legacy "esanj-rtl" one, so upgrades never leave a stale block.
strip_block() { # $1 = css file
  grep -qE 'claude-code-rtl start|esanj-rtl start' "$1" || return 0
  awk 'BEGIN{s=0} /(claude-code|esanj)-rtl start/{s=1} s==0{print} /(claude-code|esanj)-rtl end/{s=0}' "$1" > "$1.tmp" \
    && mv -f "$1.tmp" "$1"
}
# Delete fonts we copied in — current names and the legacy ones.
clean_fonts() {
  rm -f "$1/$FONT_REG_OUT" "$1/$FONT_BOLD_OUT" \
        "$1/esanj-font-regular.ttf" "$1/esanj-font-bold.ttf" "$1/esanj-Vazir.ttf" 2>/dev/null
}

found=0; count=0
for ROOT_EXT in "${EXT_ROOTS[@]}"; do
  [ -d "$ROOT_EXT" ] || continue
  # sort -V so the newest version folder wins if several are installed
  for DIR in $(ls -d "$ROOT_EXT"/anthropic.claude-code-* 2>/dev/null | sort -V); do
    CSS="$DIR/webview/index.css"; WEB="$DIR/webview"
    [ -f "$CSS" ] || continue
    found=1

    strip_block "$CSS"   # always start from a clean slate (idempotent)
    clean_fonts "$WEB"

    if [ "$MODE" = "--revert" ]; then
      echo "reset: $CSS"; count=$((count+1)); continue
    fi

    # ---- build the @font-face + family stack ----
    FACE=""
    FAMILY_STACK="\"$FONT_LABEL\",\"Segoe UI\",\"SF Pro Text\",Tahoma,sans-serif"
    REG_PATH="$(resolve_font "$FONT_REG_FILE")"
    if [ -n "$REG_PATH" ]; then
      cp -f "$REG_PATH" "$WEB/$FONT_REG_OUT"
      if [ "$FONT_VARIABLE" = "1" ]; then
        # one variable file serves the whole 100..900 weight range
        FACE="@font-face{font-family:\"$FONT_FAMILY\";src:url(\"./$FONT_REG_OUT\") format(\"truetype\");font-weight:100 900;font-style:normal;font-display:swap;}"
      else
        FACE="@font-face{font-family:\"$FONT_FAMILY\";src:url(\"./$FONT_REG_OUT\") format(\"truetype\");font-weight:400;font-style:normal;font-display:swap;}"
        BOLD_PATH="$(resolve_font "$FONT_BOLD_FILE")"
        if [ -n "$BOLD_PATH" ]; then
          cp -f "$BOLD_PATH" "$WEB/$FONT_BOLD_OUT"
          FACE="$FACE"$'\n'"@font-face{font-family:\"$FONT_FAMILY\";src:url(\"./$FONT_BOLD_OUT\") format(\"truetype\");font-weight:700;font-style:normal;font-display:swap;}"
        fi
      fi
      FAMILY_STACK="\"$FONT_FAMILY\",$FAMILY_STACK"
    fi

    # ---- append the block (see the scoping notes at the top of the file) ----
    {
      printf '\n%s\n' "$MARK_START"
      [ -n "$FACE" ] && printf '%s\n' "$FACE"
      # font on the whole panel (font only — never flips the UI layout)
      printf 'body,#root{font-family:%s;}\n' "$FAMILY_STACK"
      # AUTO-direction on message TEXT: a Persian paragraph flips RTL, an English/code
      # one stays LTR — per paragraph, from its own content (like dir="auto").
      printf '[data-testid="assistant-message"] :is(p,li,ul,ol,h1,h2,h3,h4,h5,h6,blockquote,table){unicode-bidi:plaintext;text-align:start;line-height:1.9;}\n'
      # logical padding so list bullets indent on the correct side per direction
      printf '[data-testid="assistant-message"] :is(ul,ol){padding-inline-start:1.5em;padding-inline-end:0;}\n'
      # keep code / diffs / editors LTR so they never render blank
      printf '[data-testid="assistant-message"] :is(pre,code,.monaco-editor,[class*="diff"]){direction:ltr;text-align:left;unicode-bidi:isolate;}\n'
      # the prompt box is two layers: the contenteditable holds only the (transparent)
      # text + caret, while a separate absolutely-positioned "mentionMirror" renders the
      # visible text. Give BOTH the same auto-direction (plaintext: RTL if a line starts
      # with Persian, LTR for English/code) AND the exact same horizontal padding, so the
      # caret and the visible text sit on top of each other instead of drifting apart.
      printf '[aria-label="Message input"],[class*="mentionMirror"]{unicode-bidi:plaintext;text-align:start;padding-left:14px;padding-right:36px;}\n'
      # the question / permission dialogs (options, radios) -> RTL, code inside stays LTR
      printf '[class*="permissionRequestContainer"],[class*="permissionRequestContent"]{direction:rtl;}\n'
      printf '[class*="permissionRequestContent"]{text-align:right;}\n'
      printf '[class*="permissionRequest"] :is(pre,code,.monaco-editor,[class*="diff"]){direction:ltr;text-align:left;unicode-bidi:isolate;}\n'
      # your own sent messages -> AUTO-direction too (code inside stays LTR)
      printf '[class*="userMessageContainer"]{unicode-bidi:plaintext;text-align:start;}\n'
      printf '[class*="userMessageContainer"] :is(pre,code,.monaco-editor,[class*="diff"]){direction:ltr;text-align:left;unicode-bidi:isolate;}\n'
      # todo lists (and similar <ul><li> widgets) are usually English — give them
      # auto-direction instead of hard RTL: English stays LTR, Persian still flips.
      printf '[data-testid="assistant-message"] :is([class*="todoList"],[class*="todoItem"]){direction:ltr;text-align:start;unicode-bidi:plaintext;}\n'
      printf '/* claude-code-rtl end */\n'
    } >> "$CSS"

    echo "patched: $CSS  (font: $FONT_LABEL, os: $OS)"
    count=$((count+1))
  done
done

if [ "$found" = 0 ]; then
  echo "ERROR: no Claude Code extension found under ~/.vscode/extensions."
  exit 1
fi
echo "OK ($count webview(s), os: $OS)."
