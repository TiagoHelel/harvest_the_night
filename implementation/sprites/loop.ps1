<#
.SYNOPSIS
Run the separate sprite queue using the original Claude CLI loop model.
Requires an agent with image-generation tools; DryRun never invokes the agent.
#>
param(
    [ValidateRange(1, 1000)][int]$Tasks = 8,
    [ValidateRange(0, 60)][int]$DelaySeconds = 5,
    [string]$GodotPath = 'C:\Users\Helel\Documents\godot\Godot_v4.7.1-stable_win64_console.exe',
    [switch]$DryRun
)
$ErrorActionPreference = 'Stop'
$repoPath = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$queueScript = Join-Path $PSScriptRoot 'task.py'
$previousGodot = $env:GODOT
$loopExit = 0
Push-Location $repoPath
try {
    if (-not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) {
        throw "Godot executable not found: $GodotPath"
    }
    $env:GODOT = $GodotPath
    & python $queueScript check
    if ($LASTEXITCODE -ne 0) { throw 'Invalid sprite queue.' }
    & python $queueScript stats
    if ($DryRun) {
        & python $queueScript next
        if ($LASTEXITCODE -ne 0) { throw 'Could not select a task.' }
        Write-Host "Dry run: up to $Tasks tasks; Godot $GodotPath; no agent invoked."
        Write-Host 'Runner: implementation/sprites/prompts/00-RUNNER-LOOP.md'
    } else {
        $agentCommand = Get-Command claude -ErrorAction SilentlyContinue
        if (-not $agentCommand) { throw 'Claude CLI not found. Use the runner directly in an agent with ImageGen tools.' }
        $logPath = Join-Path $PSScriptRoot 'logs'
        New-Item -ItemType Directory -Force -Path $logPath | Out-Null
        for ($iteration = 1; $iteration -le $Tasks; $iteration++) {
            $nextOutput = @(& python $queueScript next)
            if ($LASTEXITCODE -ne 0) { throw 'Could not select a task.' }
            if ($nextOutput[0] -match '^nothing actionable') {
                $nextOutput | Write-Host
                $blockedOutput = @(& python $queueScript list blocked)
                if ($LASTEXITCODE -ne 0) { throw 'Could not read blockers.' }
                if ($blockedOutput.Count -gt 0) { throw 'Queue has blockers; inspect PROGRESS.md.' }
                break
            }
            $selectedId = $nextOutput[0].Substring(0, 4)
            $stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
            $logFile = Join-Path $logPath "$stamp-$selectedId.log"
            Write-Host "[$iteration/$Tasks] $($nextOutput[0])"
            & $agentCommand.Source -p 'Read and execute implementation/sprites/prompts/00-RUNNER-LOOP.md. Complete exactly one task; generation requires an available raster image tool.' --permission-mode acceptEdits 2>&1 | Tee-Object -FilePath $logFile
            if ($LASTEXITCODE -ne 0) { throw "Agent failed; inspect $logFile" }
            & python $queueScript check
            if ($LASTEXITCODE -ne 0) { throw 'Queue failed validation after agent run.' }
            $doneOutput = @(& python $queueScript list done)
            if ($LASTEXITCODE -ne 0) { throw 'Could not read completed tasks.' }
            if (-not ($doneOutput | Where-Object { $_ -match "^$selectedId\s+done\s" })) {
                throw "Task $selectedId was not completed. Stopping; inspect $logFile and PROGRESS.md."
            }
            $blockedOutput = @(& python $queueScript list blocked)
            if ($LASTEXITCODE -ne 0) { throw 'Could not read blockers.' }
            if ($blockedOutput.Count -gt 0) { throw 'A production task is blocked. Stopping.' }
            & python $queueScript stats
            if ($iteration -lt $Tasks -and $DelaySeconds -gt 0) { Start-Sleep -Seconds $DelaySeconds }
        }
    }
} catch {
    Write-Host $_ -ForegroundColor Red
    $loopExit = 1
} finally {
    $env:GODOT = $previousGodot
    Pop-Location
}
exit $loopExit
