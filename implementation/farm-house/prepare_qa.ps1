# Mirror resources while directing Godot's user:// save fixtures to a QA folder.
$houseRepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$houseQaRoot = Join-Path $env:USERPROFILE '.codex/scratch/harvest-house-qa-20261002'
New-Item -ItemType Directory -Force -Path $houseQaRoot | Out-Null
foreach ($houseResourceDir in @('assets','src','scenes','sprites','implementation','tools','docs')) {
    $houseLink = Join-Path $houseQaRoot $houseResourceDir
    if (-not (Test-Path -LiteralPath $houseLink)) {
        New-Item -ItemType Junction -Path $houseLink -Target (Join-Path $houseRepoRoot $houseResourceDir) | Out-Null
    }
}
foreach ($houseResourceFile in @('design.md','README.md','CHANGELOG.md','default_bus_layout.tres','export_presets.cfg')) {
    Copy-Item -LiteralPath (Join-Path $houseRepoRoot $houseResourceFile) -Destination (Join-Path $houseQaRoot $houseResourceFile)
}
$houseConfig = [IO.File]::ReadAllText((Join-Path $houseRepoRoot 'project.godot'))
$houseConfig = $houseConfig.Replace('[application]', "[application]`nconfig/use_custom_user_dir=true`nconfig/custom_user_dir_name=`"HARVEST THE NIGHT-QA-farm-house`"")
[IO.File]::WriteAllText((Join-Path $houseQaRoot 'project.godot'), $houseConfig)
if (-not (Test-Path -LiteralPath (Join-Path $houseQaRoot '.godot'))) {
    Copy-Item -LiteralPath (Join-Path $houseRepoRoot '.godot') -Destination (Join-Path $houseQaRoot '.godot') -Recurse
}
$env:GODOT_PROJECT_PATH = $houseQaRoot
Write-Output $houseQaRoot
