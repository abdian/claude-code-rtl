# =============================================================================
# scripts/apply.ps1 — Claude Code · RTL engine for Windows (PowerShell, no Git).
# Copies the bundled font into each Claude Code webview and (re)writes the RTL
# CSS block. Idempotent. Run by install.ps1 now and by the logon task afterwards.
# The matching bash engine is scripts/apply.sh — keep the CSS in the two in sync.
# =============================================================================
$ErrorActionPreference = 'SilentlyContinue'

$here    = $PSScriptRoot
# flat one-line install keeps the font next to this script; the repo keeps it in ../fonts
$fontSrc = Join-Path $here 'Vazir-Variable.ttf'
if (-not (Test-Path $fontSrc)) { $fontSrc = Join-Path $here '..\fonts\Vazir-Variable.ttf' }
$extDir  = Join-Path $env:USERPROFILE '.vscode\extensions'

# The exact block we append. Scoped to message TEXT only so Monaco code/diff
# widgets are never shifted (setting rtl on the whole box renders them blank).
$block = @'

/* claude-code-rtl start */
@font-face{font-family:"ClaudeCodeRTL";src:url("./ccrtl-font-regular.ttf") format("truetype");font-weight:100 900;font-style:normal;font-display:swap;}
body,#root{font-family:"ClaudeCodeRTL","Vazir","Segoe UI",Tahoma,sans-serif;}
[data-testid="assistant-message"] :is(p,li,ul,ol,h1,h2,h3,h4,h5,h6,blockquote,table){unicode-bidi:plaintext;text-align:start;line-height:1.9;}
[data-testid="assistant-message"] :is(ul,ol){padding-inline-start:1.5em;padding-inline-end:0;}
[data-testid="assistant-message"] :is(pre,code,.monaco-editor,[class*="diff"]){direction:ltr;text-align:left;unicode-bidi:isolate;}
[aria-label="Message input"],[class*="mentionMirror"]{unicode-bidi:plaintext;text-align:start;padding-left:14px;padding-right:36px;}
[class*="permissionRequestContainer"],[class*="permissionRequestContent"]{direction:rtl;}
[class*="permissionRequestContent"]{text-align:right;}
[class*="permissionRequest"] :is(pre,code,.monaco-editor,[class*="diff"]){direction:ltr;text-align:left;unicode-bidi:isolate;}
[class*="userMessageContainer"]{unicode-bidi:plaintext;text-align:start;}
[class*="userMessageContainer"] :is(pre,code,.monaco-editor,[class*="diff"]){direction:ltr;text-align:left;unicode-bidi:isolate;}
[data-testid="assistant-message"] :is([class*="todoList"],[class*="todoItem"]){direction:ltr;text-align:start;unicode-bidi:plaintext;}
/* claude-code-rtl end */
'@

$patched = 0
Get-ChildItem $extDir -Directory -Filter 'anthropic.claude-code-*' -ErrorAction SilentlyContinue | ForEach-Object {
  $web = Join-Path $_.FullName 'webview'
  $css = Join-Path $web 'index.css'
  if (-not (Test-Path $css)) { return }

  if (Test-Path $fontSrc) { Copy-Item $fontSrc (Join-Path $web 'ccrtl-font-regular.ttf') -Force }

  # read as UTF-8 (NOT Get-Content -Raw: on PS 5.1 it decodes with the ANSI codepage
  # and would mojibake every non-ASCII char in the file — e.g. checkbox ✓ glyphs)
  $c = [System.IO.File]::ReadAllText($css)
  # strip any previous block (current or legacy marker), then re-append a fresh one
  $c = [regex]::Replace($c, '(?s)\s*/\* (?:claude-code|esanj)-rtl start \*/.*?/\* (?:claude-code|esanj)-rtl end \*/', '')
  $c = $c.TrimEnd() + "`r`n" + $block
  # write UTF-8 WITHOUT a BOM (a BOM can upset the webview's CSS parsing)
  [System.IO.File]::WriteAllText($css, $c, (New-Object System.Text.UTF8Encoding($false)))
  $patched++
}

if ($patched -eq 0) { Write-Host 'No Claude Code webview found.' -ForegroundColor Yellow }
else { Write-Host "OK ($patched webview(s) patched)." -ForegroundColor Green }
