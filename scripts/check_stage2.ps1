$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskLocalGhdl = Join-Path $taskRoot 'tools\ghdl-6.0.0\bin\ghdl.exe'
if (Test-Path -LiteralPath $taskLocalGhdl) {
    $taskGhdl = $taskLocalGhdl
} else {
    $taskGhdl = (Get-Command ghdl -ErrorAction Stop).Source
}
$taskBuild = Join-Path $taskRoot 'build\stage2'
New-Item -ItemType Directory -Force -Path $taskBuild | Out-Null
$taskSources = @(
    'rtl\clock_types_pkg.vhd'
    'rtl\clock_core.vhd'
    'rtl\time_format.vhd'
    'rtl\seven_segment.vhd'
    'rtl\display_driver.vhd'
    'sim\tb_clock_display.vhd'
) | ForEach-Object { Join-Path $taskRoot $_ }
Push-Location $taskBuild
try {
    & $taskGhdl -a --std=08 @taskSources
    if ($LASTEXITCODE -ne 0) { throw 'GHDL analysis failed.' }
    & $taskGhdl -e --std=08 tb_clock_display
    if ($LASTEXITCODE -ne 0) { throw 'GHDL elaboration failed.' }
    & $taskGhdl -r --std=08 tb_clock_display --assert-level=error --wave=clock_display.ghw --vcd=clock_display.vcd
    if ($LASTEXITCODE -ne 0) { throw 'GHDL simulation failed.' }
    foreach ($taskWave in @('clock_display.ghw', 'clock_display.vcd')) {
        $taskFile = Get-Item -LiteralPath $taskWave
        if ($taskFile.Length -eq 0) { throw "Empty waveform: $taskWave" }
        Write-Output ("Created {0} ({1} bytes)" -f $taskFile.FullName, $taskFile.Length)
    }
} finally {
    Pop-Location
}
