$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskLocalGhdl = Join-Path $taskRoot 'tools\ghdl-6.0.0\bin\ghdl.exe'
if (Test-Path -LiteralPath $taskLocalGhdl) {
    $taskGhdl = $taskLocalGhdl
} else {
    $taskGhdl = (Get-Command ghdl -ErrorAction Stop).Source
}
$taskBuild = Join-Path $taskRoot 'build\stage4'
New-Item -ItemType Directory -Force -Path $taskBuild | Out-Null
$taskSources = @(
    'rtl\clock_types_pkg.vhd'
    'rtl\clock_core.vhd'
    'rtl\time_format.vhd'
    'rtl\seven_segment.vhd'
    'rtl\display_driver.vhd'
    'rtl\timer_engine.vhd'
    'rtl\daily_alarm.vhd'
    'rtl\digital_clock.vhd'
    'sim\tb_daily_alarm.vhd'
) | ForEach-Object { Join-Path $taskRoot $_ }
Push-Location $taskBuild
try {
    & $taskGhdl -a --std=08 @taskSources
    if ($LASTEXITCODE -ne 0) { throw 'GHDL analysis failed.' }
    & $taskGhdl -e --std=08 tb_daily_alarm
    if ($LASTEXITCODE -ne 0) { throw 'GHDL elaboration failed.' }
    & $taskGhdl -r --std=08 tb_daily_alarm --assert-level=error --wave=daily_alarm.ghw --vcd=daily_alarm.vcd
    if ($LASTEXITCODE -ne 0) { throw 'GHDL alarm simulation failed.' }
    foreach ($taskWave in @('daily_alarm.ghw', 'daily_alarm.vcd')) {
        $taskFile = Get-Item -LiteralPath $taskWave
        if ($taskFile.Length -eq 0) { throw "Empty waveform: $taskWave" }
        Write-Output ("Created {0} ({1} bytes)" -f $taskFile.FullName, $taskFile.Length)
    }
} finally {
    Pop-Location
}
