<#
.SYNOPSIS
    Runs the backlog runner over and over until everything is ticked.

.DESCRIPTION
    One task per Claude Code invocation, so each task gets a clean context and a
    clean commit. Between tasks the script re-checks the queue and stops on its
    own when nothing is actionable.

    Requires the Claude Code CLI on PATH:
        npm install -g @anthropic-ai/claude-code

    If you are driving this from the Claude Code desktop app instead, you do not
    need this script at all - see implementation/README.md and use /loop.

.PARAMETER Tasks
    How many tasks to attempt in this session. Default 8.

.PARAMETER Yolo
    Pass --dangerously-skip-permissions instead of --permission-mode acceptEdits.
    Only for a machine you are happy to leave unattended.

.PARAMETER DelaySeconds
    Pause between tasks. Default 5.

.EXAMPLE
    .\implementation\loop.ps1 -Tasks 20
.EXAMPLE
    .\implementation\loop.ps1 -Tasks 100 -Yolo
#>
param(
    [int]$Tasks = 8,
    [switch]$Yolo,
    [int]$DelaySeconds = 5
)

$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo

$claude = Get-Command claude -ErrorAction SilentlyContinue
if (-not $claude) {
    Write-Host "The Claude Code CLI is not on PATH." -ForegroundColor Yellow
    Write-Host "  npm install -g @anthropic-ai/claude-code"
    Write-Host ""
    Write-Host "Or, from the Claude Code desktop app:"
    Write-Host "  /loop 45m Read and execute implementation/prompts/00-RUNNER-LOOP.md"
    exit 1
}

$logDir = Join-Path $PSScriptRoot "logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$permFlag = if ($Yolo) { "--dangerously-skip-permissions" } else { "--permission-mode", "acceptEdits" }

Write-Host ""
Write-Host "HARVEST THE NIGHT - backlog loop" -ForegroundColor Cyan
python tools/task.py stats
Write-Host ""

for ($i = 1; $i -le $Tasks; $i++) {
    $next = python tools/task.py next
    if ($LASTEXITCODE -ne 0 -or $next -match "nothing actionable") {
        Write-Host "Queue is empty or fully blocked. Stopping." -ForegroundColor Green
        $next
        break
    }

    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $log = Join-Path $logDir "$stamp.log"
    Write-Host "[$i/$Tasks] $next" -ForegroundColor Cyan
    Write-Host "         log: $log"

    & claude -p "Read and execute implementation/prompts/00-RUNNER-LOOP.md" @permFlag 2>&1 | Tee-Object -FilePath $log
    $code = $LASTEXITCODE

    if ($code -ne 0) {
        Write-Host "         claude exited $code - see the log. Stopping." -ForegroundColor Red
        break
    }

    # A task must not be left mid-flight. If it is, something went wrong.
    $stuck = Select-String -Path "implementation/prompts/*.md" -Pattern "Status:\*\* doing" -List
    if ($stuck) {
        Write-Host "         task still marked doing: $($stuck.Path)" -ForegroundColor Yellow
        Write-Host "         stopping so you can look at it." -ForegroundColor Yellow
        break
    }

    python tools/task.py stats
    if ($i -lt $Tasks) { Start-Sleep -Seconds $DelaySeconds }
}

Write-Host ""
python tools/task.py stats
Write-Host "Journal: implementation/PROGRESS.md" -ForegroundColor Cyan
