param([string]$Godot = $env:GODOT_BIN)
$ErrorActionPreference = "Stop"
$Project = Split-Path $PSScriptRoot -Parent
if (-not $Godot) {
    $candidate = Get-Command godot -ErrorAction SilentlyContinue
    if ($candidate) { $Godot = $candidate.Source }
}
if (-not $Godot -or -not (Test-Path $Godot)) { throw 'Set GODOT_BIN or pass -Godot C:\Tools\Godot.exe' }
function Invoke-Checked([string[]]$Arguments, [string]$Expected = "") {
    $output = & $Godot @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    $text = $output -join "`n"
    $output | ForEach-Object { Write-Host $_ }
    if ($exitCode -ne 0 -or $text -match '(SCRIPT ERROR:|Parse Error:|(^|\s)ERROR:|FAIL:)') { throw "Godot failed ($exitCode)" }
    if ($Expected -and -not $text.Contains($Expected)) { throw "Missing marker: $Expected" }
}
Push-Location $Project
try {
    & $Godot --version
    Invoke-Checked @('--headless','--path',$Project,'--editor','--import')
    Invoke-Checked @('--headless','--path',$Project,'--script','res://tests/test_weapon.gd') 'PHASE1_UNIT_RESULT:'
    Invoke-Checked @('--headless','--path',$Project,'--script','res://tests/phase2/test_phase2.gd') 'PHASE2_UNIT_RESULT:'
    Invoke-Checked @('--headless','--path',$Project,'--script','res://tests/phase2/test_interactions.gd') 'PHASE2_INTERACTION_RESULT:'
    Invoke-Checked @('--headless','--fixed-fps','60','--quit-after','360','--path',$Project,'res://scenes/main.tscn','--','--smoke-test') 'PHASE1_SMOKE_READY'
    Invoke-Checked @('--headless','--fixed-fps','60','--quit-after','600','--path',$Project,'--','--phase2-smoke','--seed=8027') 'PHASE2_SMOKE_READY'
    Invoke-Checked @('--headless','--fixed-fps','60','--quit-after','45000','--path',$Project,'--','--autoplay-test') 'PHASE2_AUTOPLAY_RESULT:'
    Write-Host 'Engine checks passed. Human playtesting and Windows export validation remain separate.'
} finally { Pop-Location }
