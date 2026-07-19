# =============================================================================
# One-line uninstall for Windows. Run in PowerShell:
#   irm https://raw.githubusercontent.com/abdian/claude-code-rtl/main/uninstall.ps1 | iex
# Removes the RTL block + font from every Claude Code webview, stops auto-apply,
# and deletes the installed files. The extension is left exactly as it shipped.
# =============================================================================
$ErrorActionPreference = 'SilentlyContinue'

$extDir = Join-Path $env:USERPROFILE '.vscode\extensions'
Get-ChildItem $extDir -Directory -Filter 'anthropic.claude-code-*' | ForEach-Object {
  $web = Join-Path $_.FullName 'webview'
  $css = Join-Path $web 'index.css'
  if (Test-Path $css) {
    # read as UTF-8 (NOT Get-Content -Raw: PS 5.1 would decode with the ANSI codepage
    # and mojibake every non-ASCII glyph in the file)
    $c = [System.IO.File]::ReadAllText($css)
    $c = [regex]::Replace($c, '(?s)\s*/\* (?:claude-code|esanj)-rtl start \*/.*?/\* (?:claude-code|esanj)-rtl end \*/', '')
    [System.IO.File]::WriteAllText($css, $c.TrimEnd() + "`r`n", (New-Object System.Text.UTF8Encoding($false)))
  }
  Remove-Item (Join-Path $web 'ccrtl-font-regular.ttf')  -Force -ErrorAction SilentlyContinue
  Remove-Item (Join-Path $web 'esanj-font-regular.ttf')  -Force -ErrorAction SilentlyContinue
}

Remove-Item (Join-Path ([Environment]::GetFolderPath('Startup')) 'ClaudeCodeRTL.vbs') -Force -ErrorAction SilentlyContinue
schtasks /Delete /TN 'ClaudeCodeRTL' /F 2>$null | Out-Null
Remove-Item (Join-Path $env:LOCALAPPDATA 'ClaudeCodeRTL') -Recurse -Force -ErrorAction SilentlyContinue

Write-Host 'OK  Removed. Reload VSCode to see the original chat.' -ForegroundColor Green
