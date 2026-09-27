param([string]$Godot = $env:GODOT_BIN)
$ErrorActionPreference = "Stop"
$Project = Split-Path $PSScriptRoot -Parent
if (-not $Godot) {
    $candidate = Get-Command godot -ErrorAction SilentlyContinue
    if ($candidate) { $Godot = $candidate.Source }
}
if (-not $Godot -or -not (Test-Path $Godot)) { throw 'Set GODOT_BIN or pass -Godot C:\Tools\Godot.exe' }
function Invoke-Phase3([string[]]$Arguments, [string]$Expected) {
    $output = & $Godot @Arguments 2>&1
    $code = $LASTEXITCODE
    $text = $output -join "`n"
    $output | ForEach-Object { Write-Host $_ }
    if ($code -ne 0 -or $text -match '(SCRIPT ERROR:|Parse Error:|(^|\s)ERROR:|FAIL:)') { throw "Phase 3 engine check failed ($code)" }
    if (-not $text.Contains($Expected)) { throw "Missing completion marker: $Expected" }
}
Push-Location $Project
try {
    & $Godot --version
    Invoke-Phase3 @('--headless','--fixed-fps','60','--quit-after','3000','--path',$Project,'--script','res://tests/phase3/test_phase3.gd','--','--phase3-test') 'PHASE3_UNIT_RESULT:'
    Invoke-Phase3 @('--headless','--fixed-fps','60','--quit-after','1800','--path',$Project,'res://scenes/phase3.tscn','--','--phase3-smoke') 'PHASE3_SMOKE_READY'
    foreach ($map in @('toy_home','warehouse','garden')) {
        Invoke-Phase3 @('--headless','--fixed-fps','60','--quit-after','180000','--path',$Project,'res://scenes/phase3.tscn','--','--phase3-autoplay',"--map=$map") 'PHASE3_AUTOPLAY_RESULT:'
    }
    Write-Host 'Phase 3 engine assertions and three map matches passed. Human input and GPU performance still need testing.'
} finally { Pop-Location }
