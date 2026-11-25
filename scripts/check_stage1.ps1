$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskLocalGhdl = Join-Path $taskRoot 'tools\ghdl-6.0.0\bin\ghdl.exe'
if (Test-Path -LiteralPath $taskLocalGhdl) {
    $taskGhdl = $taskLocalGhdl
} else {
    $taskGhdl = (Get-Command ghdl -ErrorAction Stop).Source
}
$taskBuild = Join-Path $taskRoot 'build\stage1'
New-Item -ItemType Directory -Force -Path $taskBuild | Out-Null
Push-Location $taskBuild
try {
    & $taskGhdl -a --std=08 (Join-Path $taskRoot 'rtl\clock_types_pkg.vhd') (Join-Path $taskRoot 'rtl\clock_core.vhd') (Join-Path $taskRoot 'sim\tb_clock_core.vhd')
    if ($LASTEXITCODE -ne 0) { throw 'GHDL analysis failed.' }
    & $taskGhdl -e --std=08 tb_clock_core
    if ($LASTEXITCODE -ne 0) { throw 'GHDL elaboration failed.' }
    & $taskGhdl -r --std=08 tb_clock_core --assert-level=error --wave=clock_core.ghw --vcd=clock_core.vcd
    if ($LASTEXITCODE -ne 0) { throw 'GHDL simulation failed.' }
    foreach ($taskWave in @('clock_core.ghw', 'clock_core.vcd')) {
        $taskFile = Get-Item -LiteralPath $taskWave
        if ($taskFile.Length -eq 0) { throw "Empty waveform: $taskWave" }
        Write-Output ("Created {0} ({1} bytes)" -f $taskFile.FullName, $taskFile.Length)
    }
} finally {
    Pop-Location
}
