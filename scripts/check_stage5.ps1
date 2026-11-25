$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskLocalGhdl = Join-Path $taskRoot 'tools\ghdl-6.0.0\bin\ghdl.exe'
if (Test-Path -LiteralPath $taskLocalGhdl) {
    $taskGhdl = $taskLocalGhdl
} else {
    $taskGhdl = (Get-Command ghdl -ErrorAction Stop).Source
}
$taskBuild = Join-Path $taskRoot 'build\stage5'
New-Item -ItemType Directory -Force -Path $taskBuild | Out-Null
$taskWaves = @('digital_clock.ghw', 'digital_clock.vcd')
foreach ($taskProduct in @('work-obj08.cf') + $taskWaves) {
    $taskPath = Join-Path $taskBuild $taskProduct
    if (Test-Path -LiteralPath $taskPath -PathType Leaf) {
        Remove-Item -LiteralPath $taskPath
    }
}
$taskSources = @(
    'rtl\clock_types_pkg.vhd'
    'rtl\clock_core.vhd'
    'rtl\time_format.vhd'
    'rtl\seven_segment.vhd'
    'rtl\display_driver.vhd'
    'rtl\timer_engine.vhd'
    'rtl\daily_alarm.vhd'
    'rtl\digital_clock.vhd'
    'sim\tb_digital_clock.vhd'
) | ForEach-Object { Join-Path $taskRoot $_ }
Push-Location $taskBuild
try {
    & $taskGhdl -a --std=08 @taskSources
    if ($LASTEXITCODE -ne 0) { throw 'GHDL analysis failed.' }
    & $taskGhdl -e --std=08 tb_digital_clock
    if ($LASTEXITCODE -ne 0) { throw 'GHDL elaboration failed.' }
    & $taskGhdl -r --std=08 tb_digital_clock --assert-level=error --wave=digital_clock.ghw --vcd=digital_clock.vcd
    if ($LASTEXITCODE -ne 0) { throw 'GHDL integration simulation failed.' }
    foreach ($taskWave in $taskWaves) {
        $taskFile = Get-Item -LiteralPath $taskWave
        if ($taskFile.Length -eq 0) { throw "Empty waveform: $taskWave" }
        Write-Output ("Created {0} ({1} bytes)" -f $taskFile.FullName, $taskFile.Length)
    }
} finally {
    Pop-Location
}
