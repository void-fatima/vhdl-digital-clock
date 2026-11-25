$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskLocalGhdl = Join-Path $taskRoot 'tools\ghdl-6.0.0\bin\ghdl.exe'
if (Test-Path -LiteralPath $taskLocalGhdl) {
    $taskGhdl = $taskLocalGhdl
} else {
    $taskGhdl = (Get-Command ghdl -ErrorAction Stop).Source
}
$taskBuild = Join-Path $taskRoot 'build\setup'
New-Item -ItemType Directory -Force -Path $taskBuild | Out-Null
Push-Location $taskBuild
try {
    & $taskGhdl --version
    if ($LASTEXITCODE -ne 0) { throw 'GHDL version check failed.' }
    & $taskGhdl -a --std=08 (Join-Path $taskRoot 'sim\tb_setup.vhd')
    if ($LASTEXITCODE -ne 0) { throw 'GHDL analysis failed.' }
    & $taskGhdl -e --std=08 tb_setup
    if ($LASTEXITCODE -ne 0) { throw 'GHDL elaboration failed.' }
    & $taskGhdl -r --std=08 tb_setup --assert-level=error --wave=setup.ghw --vcd=setup.vcd
    if ($LASTEXITCODE -ne 0) { throw 'GHDL simulation failed.' }
    foreach ($taskWave in @('setup.ghw', 'setup.vcd')) {
        $taskFile = Get-Item -LiteralPath $taskWave
        if ($taskFile.Length -eq 0) { throw "Empty waveform: $taskWave" }
        Write-Output ("Created {0} ({1} bytes)" -f $taskFile.FullName, $taskFile.Length)
    }
} finally {
    Pop-Location
}
