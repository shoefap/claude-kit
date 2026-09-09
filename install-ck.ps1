<#
  Cai ClaudeKit `ck` dang plugin cho Claude Code tren Windows.

  Dung:
    .\install-ck.ps1
    .\install-ck.ps1 -Zip "C:\duong\dan\ck-plugin.zip"

  Neu bi chan boi execution policy, chay:
    powershell -ExecutionPolicy Bypass -File .\install-ck.ps1
#>

[CmdletBinding()]
param(
    [string]$Zip = "",
    [string]$KitDir = (Join-Path $HOME ".claude-kits")
)

$ErrorActionPreference = "Stop"

$MarketName = "ck-local"
$PluginName = "ck"

function Write-Info { param($m) Write-Host "==> $m" -ForegroundColor Cyan }
function Write-Ok   { param($m) Write-Host "  ok $m" -ForegroundColor Green }
function Write-Warn2{ param($m) Write-Host "  !! $m" -ForegroundColor Yellow }
function Fail       { param($m) Write-Host "  xx $m" -ForegroundColor Red; exit 1 }

# ---------- 1. Kiem tra moi truong ----------
Write-Info "Kiem tra moi truong"

$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node) { Fail "Thieu 'node'. Kit nay chay hook bang Node, can Node 18+. Tai tai https://nodejs.org" }

$nodeMajor = [int](& node -p "process.versions.node.split('.')[0]")
if ($nodeMajor -lt 18) { Fail "Node $nodeMajor qua cu, can >= 18." }

$claude = Get-Command claude -ErrorAction SilentlyContinue
if (-not $claude) { Fail "Khong thay lenh 'claude'. Cai Claude Code truoc." }

$claudeVer = (& claude --version 2>$null | Select-Object -First 1)
Write-Ok "node v$(& node -p 'process.versions.node'), claude $claudeVer"

# ---------- 2. Tim file zip ----------
if ([string]::IsNullOrWhiteSpace($Zip)) {
    $candidates = @(
        (Join-Path (Get-Location) "ck-plugin.zip"),
        (Join-Path $HOME "Downloads\ck-plugin.zip"),
        (Join-Path $HOME "Desktop\ck-plugin.zip")
    )
    foreach ($c in $candidates) {
        if (Test-Path -LiteralPath $c) { $Zip = $c; break }
    }
}

if ([string]::IsNullOrWhiteSpace($Zip) -or -not (Test-Path -LiteralPath $Zip)) {
    Fail "Khong tim thay ck-plugin.zip. Chay: .\install-ck.ps1 -Zip 'C:\duong\dan\ck-plugin.zip'"
}

$Zip = (Resolve-Path -LiteralPath $Zip).Path
Write-Ok "zip: $Zip"

# ---------- 3. Giai nen (co backup) ----------
$Dest = Join-Path $KitDir "ck-marketplace"

if (-not (Test-Path -LiteralPath $KitDir)) {
    New-Item -ItemType Directory -Path $KitDir -Force | Out-Null
}

if (Test-Path -LiteralPath $Dest) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $bak = "$Dest.bak.$stamp"
    Write-Info "Da ton tai, backup -> $bak"
    Move-Item -LiteralPath $Dest -Destination $bak
}

Write-Info "Giai nen vao $KitDir"
Expand-Archive -LiteralPath $Zip -DestinationPath $KitDir -Force

$manifest = Join-Path $Dest ".claude-plugin\marketplace.json"
if (-not (Test-Path -LiteralPath $manifest)) { Fail "Zip sai cau truc: thieu marketplace.json" }

$skillCount = (Get-ChildItem -LiteralPath (Join-Path $Dest "ck\skills") -Directory -ErrorAction SilentlyContinue |
    Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "SKILL.md") }).Count
$agentCount = (Get-ChildItem -LiteralPath (Join-Path $Dest "ck\agents") -Filter *.md -ErrorAction SilentlyContinue).Count
Write-Ok "$skillCount skills, $agentCount agents"

# ---------- 4. Dang ky marketplace (idempotent) ----------
Write-Info "Dang ky marketplace"
$out = (& claude plugin marketplace add "$Dest" 2>&1 | Out-String)

if ($LASTEXITCODE -eq 0) {
    Write-Ok "da them '$MarketName'"
}
elseif ($out -match "(?i)already") {
    & claude plugin marketplace update $MarketName 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { Write-Ok "da co san, cap nhat lai" }
    else { Write-Warn2 "khong update duoc, van tiep tuc" }
}
else {
    Write-Host $out
    Fail "Them marketplace that bai."
}

# ---------- 5. Cai plugin ----------
Write-Info "Cai plugin $PluginName@$MarketName"
$out = (& claude plugin install "$PluginName@$MarketName" 2>&1 | Out-String)

if ($LASTEXITCODE -eq 0) {
    Write-Ok "cai xong"
}
elseif ($out -match "(?i)already") {
    Write-Ok "da cai tu truoc"
}
else {
    Write-Host $out
    Write-Warn2 "CLI cai that bai. Mo Claude Code roi chay tay:"
    Write-Host "      /plugin marketplace add $Dest"
    Write-Host "      /plugin install $PluginName@$MarketName"
    exit 1
}

# ---------- 6. Config tuy chon ----------
$claudeHome = Join-Path $HOME ".claude"
$ckTarget = Join-Path $claudeHome ".ck.json"
$ckSource = Join-Path $Dest "ck\.ck.json"

if ((-not (Test-Path -LiteralPath $ckTarget)) -and (Test-Path -LiteralPath $ckSource)) {
    if (-not (Test-Path -LiteralPath $claudeHome)) {
        New-Item -ItemType Directory -Path $claudeHome -Force | Out-Null
    }
    Copy-Item -LiteralPath $ckSource -Destination $ckTarget
    Write-Ok "copy .ck.json -> ~\.claude\ (chinh codingLevel, locale o day)"
}

# ---------- 7. Xac nhan ----------
Write-Info "Kiem tra lai"
$list = (& claude plugin list 2>&1 | Out-String)
if ($list -match "(?i)$PluginName") {
    Write-Ok "plugin da nam trong danh sach"
} else {
    Write-Warn2 "khong doc duoc danh sach, kiem tra bang /plugin trong Claude Code"
}

Write-Host ""
Write-Host "  Xong. Khoi dong lai Claude Code roi go /ck: de xem danh sach." -ForegroundColor Green
Write-Host ""
Write-Host "  Thu: /ck:brainstorm   /ck:plan   /ck:debug   /ck:cook"
Write-Host ""
Write-Host "  Go cai:  claude plugin uninstall $PluginName"
Write-Host "           claude plugin marketplace remove $MarketName"
Write-Host "           Remove-Item -LiteralPath '$Dest' -Recurse -Force"
Write-Host ""
