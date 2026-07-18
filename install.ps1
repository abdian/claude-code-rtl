# =============================================================================
# One-line installer for Windows (no Git needed). Run in PowerShell:
#
#   irm https://raw.githubusercontent.com/abdian/claude-code-rtl/main/install.ps1 | iex
#
# Downloads the engine + font, applies the RTL patch, and turns on auto-apply
# (runs hidden at each logon) so it survives Claude Code updates.
# =============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$raw  = 'https://raw.githubusercontent.com/abdian/claude-code-rtl/main'
$root = Join-Path $env:LOCALAPPDATA 'ClaudeCodeRTL'

# 1) Claude Code installed?
$extDir = Join-Path $env:USERPROFILE '.vscode\extensions'
if (-not (@(Get-ChildItem $extDir -Directory -Filter 'anthropic.claude-code-*' -ErrorAction SilentlyContinue)).Count) {
  Write-Host 'X  Claude Code extension not found. Install it in VSCode first, then re-run.' -ForegroundColor Red
  return
}

# 2) download engine + font into %LOCALAPPDATA%\ClaudeCodeRTL
Write-Host ''
Write-Host '->  downloading Claude Code . RTL ...' -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $root | Out-Null
Invoke-WebRequest "$raw/scripts/apply.ps1"        -OutFile (Join-Path $root 'apply.ps1')          -UseBasicParsing
Invoke-WebRequest "$raw/fonts/Vazir-Variable.ttf" -OutFile (Join-Path $root 'Vazir-Variable.ttf') -UseBasicParsing

# 3) apply now
$applyPath = Join-Path $root 'apply.ps1'
powershell -NoProfile -ExecutionPolicy Bypass -File $applyPath

# 4) auto-apply at every logon (hidden window, no admin)
$vbs = Join-Path ([Environment]::GetFolderPath('Startup')) 'ClaudeCodeRTL.vbs'
$vbsBody = 'Set sh=CreateObject("WScript.Shell")' + "`r`n" +
           'sh.Run "powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File ""' + $applyPath + '""",0,False'
Set-Content -LiteralPath $vbs -Value $vbsBody -Encoding ASCII

Write-Host ''
Write-Host 'OK  Installed. Claude Code chat is now right-to-left.' -ForegroundColor Green
Write-Host '    Last step -> reload VSCode:  Ctrl + Shift + P  ->  Developer: Reload Window'
Write-Host ''
Write-Host '    Uninstall later:  irm ' -NoNewline; Write-Host "$raw/uninstall.ps1 | iex" -ForegroundColor DarkGray
