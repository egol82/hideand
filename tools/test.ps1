param([string]$Godot = $env:GODOT_BIN)
$ErrorActionPreference = "Stop"
$Project = Split-Path $PSScriptRoot -Parent
if (-not $Godot) {
    $candidate = Get-Command godot -ErrorAction SilentlyContinue
    if ($candidate) { $Godot = $candidate.Source }
}
if (-not $Godot -or -not (Test-Path $Godot)) {
    throw 'Set GODOT_BIN to the full path of the standard Godot executable, or use -Godot C:\Tools\Godot.exe'
}
function Invoke-GodotChecked([string[]]$Arguments, [string]$Expected = "") {
    $output = & $Godot @Arguments 2>&1
    $exit = $LASTEXITCODE
    $output | ForEach-Object { Write-Host $_ }
    if ($exit -ne 0 -or ($output -join "`n") -match '(SCRIPT ERROR:|Parse Error:|^ERROR:)') {
        throw "Godot validation failed: exit $exit"
    }
    if ($Expected -and ($output -join "`n") -notmatch [regex]::Escape($Expected)) {
        throw "Godot exited without the required completion marker: $Expected"
    }
}
Push-Location $Project
try {
    & $Godot --version
    Invoke-GodotChecked -Arguments @('--headless','--path',$Project,'--editor','--import')
    Invoke-GodotChecked -Arguments @('--headless','--path',$Project,'--script','res://tests/test_weapon.gd')
    Invoke-GodotChecked -Arguments @('--headless','--fixed-fps','60','--quit-after','240','--path',$Project,'--','--smoke-test') -Expected 'PHASE1_SMOKE_READY'
    Write-Host 'Godot checks passed. A GUI playtest is still required.'
} finally { Pop-Location }
