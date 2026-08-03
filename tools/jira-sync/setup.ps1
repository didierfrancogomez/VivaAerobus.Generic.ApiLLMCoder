#Requires -Version 5.1
<#
.SYNOPSIS
    One-shot dependency setup for the jira-sync tool and the ticket lifecycle.

.DESCRIPTION
    Checks every dependency the lifecycle shells out to and INSTALLS the ones that are
    safe to install automatically (a project-local python venv + its packages, and the
    global newman when node is already present). Runtimes and daemons (python, node,
    gh, dotnet, docker) are never auto-installed — you get the exact command instead.

    Ends by running `jira_sync.py doctor` with the venv interpreter, so the final word
    is the same check the /implement flow gates on.

    Safe to re-run at any time: every step is idempotent.

.PARAMETER CheckOnly
    Report everything, install nothing.

.EXAMPLE
    .\setup.ps1              # first-time setup (creates .venv, installs deps + newman)
.EXAMPLE
    .\setup.ps1 -CheckOnly   # audit only
#>
[CmdletBinding()]
param(
    [switch] $CheckOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$here = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) { $PSScriptRoot }
        else { Split-Path -Parent $MyInvocation.MyCommand.Path }

$failures = 0
function Write-Ok   { param([string]$m) Write-Host "  [ OK ] $m" -ForegroundColor Green }
function Write-Fix  { param([string]$m) Write-Host "  [FIX ] $m" -ForegroundColor Cyan }
function Write-Warn2{ param([string]$m) Write-Host "  [WARN] $m" -ForegroundColor Yellow }
function Write-Bad  { param([string]$m) $script:failures++; Write-Host "  [FAIL] $m" -ForegroundColor Red }

Write-Host "jira-sync setup — dependency check$(if ($CheckOnly) { ' (check only)' })" -ForegroundColor Cyan
Write-Host ""

# ── 1. Python ────────────────────────────────────────────────────────────────
$python = $null
foreach ($candidate in @("python", "python3", "py")) {
    $cmd = Get-Command $candidate -ErrorAction SilentlyContinue
    if ($cmd) {
        $v = & $cmd.Source --version 2>&1
        if ($LASTEXITCODE -eq 0 -and "$v" -match "Python 3\.(\d+)") {
            if ([int]$Matches[1] -ge 10) { $python = $cmd.Source; Write-Ok "python: $v ($python)"; break }
        }
    }
}
if (-not $python) {
    Write-Bad "Python 3.10+ not found. Install it:  winget install Python.Python.3.12  (then re-run)"
}

# ── 2. venv + python deps (auto-fixable) ─────────────────────────────────────
$venvPython = Join-Path $here ".venv\Scripts\python.exe"
if ($python) {
    if (-not (Test-Path $venvPython)) {
        if ($CheckOnly) { Write-Warn2 ".venv missing — setup would create it here" }
        else {
            Write-Fix "creating .venv..."
            & $python -m venv (Join-Path $here ".venv")
            if (-not (Test-Path $venvPython)) { Write-Bad ".venv creation failed" }
        }
    }
    if (Test-Path $venvPython) {
        $need = & $venvPython -c "import importlib.util,sys; mods=['requests','dotenv','openpyxl']; missing=[m for m in mods if importlib.util.find_spec(m) is None]; print(','.join(missing))" 2>&1
        if ([string]::IsNullOrWhiteSpace("$need")) { Write-Ok "python deps present in .venv" }
        elseif ($CheckOnly) { Write-Warn2 "python deps missing in .venv: $need" }
        else {
            Write-Fix "pip install -r requirements.txt ..."
            & $venvPython -m pip install --quiet --disable-pip-version-check -r (Join-Path $here "requirements.txt")
            if ($LASTEXITCODE -eq 0) { Write-Ok "python deps installed" } else { Write-Bad "pip install failed — run it manually to see why" }
        }
    }
}

# ── 3. .env (auto-scaffold, never auto-filled) ───────────────────────────────
$envFile = Join-Path $here ".env"
if (Test-Path $envFile) {
    $missingKeys = @()
    $envText = Get-Content $envFile -Raw
    foreach ($k in @("JIRA_BASE_URL", "JIRA_EMAIL", "JIRA_API_TOKEN")) {
        if ($envText -notmatch "(?m)^\s*$k\s*=\s*\S") { $missingKeys += $k }
    }
    if ($missingKeys.Count -eq 0) { Write-Ok ".env present with the required keys" }
    else { Write-Bad ".env exists but these keys are empty/missing: $($missingKeys -join ', ')" }
}
elseif ($CheckOnly) { Write-Warn2 ".env missing — setup would scaffold it from .env.example" }
else {
    Copy-Item (Join-Path $here ".env.example") $envFile
    Write-Fix ".env scaffolded from .env.example"
    Write-Bad  ".env created but NOT filled — set JIRA_BASE_URL / JIRA_EMAIL / JIRA_API_TOKEN (token: https://id.atlassian.com/manage-profile/security/api-tokens)"
}

# ── 4. node + newman (newman auto-fixable) ───────────────────────────────────
$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node -and (Test-Path "$env:ProgramFiles\nodejs\node.exe")) { $node = @{ Source = "$env:ProgramFiles\nodejs\node.exe" } }
if ($node) {
    Write-Ok "node: $(& $node.Source --version)"
    $newman = Get-Command newman -ErrorAction SilentlyContinue
    if (-not $newman -and (Test-Path "$env:APPDATA\npm\newman.cmd")) { $newman = @{ Source = "$env:APPDATA\npm\newman.cmd" } }
    if ($newman) { Write-Ok "newman (global): $($newman.Source)" }
    elseif ($CheckOnly) { Write-Warn2 "newman missing — setup would run: npm install -g newman" }
    else {
        Write-Fix "npm install -g newman ..."
        npm install -g newman | Out-Null
        if ($LASTEXITCODE -eq 0) { Write-Ok "newman installed globally" } else { Write-Bad "npm install -g newman failed — run it manually" }
    }
}
else {
    Write-Bad "node not found (newman needs it). Install:  winget install OpenJS.NodeJS.LTS  — then re-run so newman gets installed"
}

# ── 5. Runtimes we only verify, never install ────────────────────────────────
$gh = Get-Command gh -ErrorAction SilentlyContinue
if ($gh) {
    gh auth status 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { Write-Ok "gh CLI authenticated" }
    else { Write-Bad "gh CLI present but not authenticated — run: gh auth login" }
}
else { Write-Bad "gh CLI not found. Install:  winget install GitHub.cli  — then: gh auth login" }

if (Get-Command dotnet -ErrorAction SilentlyContinue) { Write-Ok "dotnet SDK: $(dotnet --version 2>&1 | Select-Object -First 1)" }
else { Write-Bad "dotnet SDK not found — install the SDK the code repo pins in global.json" }

docker ps -q 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) { Write-Ok "docker daemon running" }
else { Write-Warn2 "docker daemon not running — needed for local E2E/seed/Redis only (VB-TEST runs work without it). Start Docker Desktop + docker\dev-env-up.bat" }

# ── 6. Final word: doctor ────────────────────────────────────────────────────
Write-Host ""
if ((Test-Path $venvPython) -and $failures -eq 0) {
    Write-Host "Running doctor (the same check /implement gates on):" -ForegroundColor Cyan
    & $venvPython (Join-Path $here "jira_sync.py") doctor
    exit $LASTEXITCODE
}
Write-Host "$failures blocking issue(s) above — fix them and re-run .\setup.ps1" -ForegroundColor $(if ($failures) { "Red" } else { "Green" })
exit $failures
