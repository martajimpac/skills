$ErrorActionPreference = 'Stop'
$bin = Join-Path $HOME '.ias\bin'
$plugins = Join-Path $HOME '.ias\plugins'
if (-not (Test-Path -LiteralPath $plugins -PathType Container)) { throw "No existe $plugins. No se instalará IAS para evitar una instalación incompleta." }
if (-not (Test-Path -LiteralPath $bin -PathType Container)) { New-Item -ItemType Directory -Path $bin -Force | Out-Null }
$sourcePs1 = Join-Path $PSScriptRoot 'ias.ps1'
$sourceCmd = Join-Path $PSScriptRoot 'ias.cmd'
if (-not (Test-Path -LiteralPath $sourcePs1 -PathType Leaf)) { throw "No se encuentra $sourcePs1" }
if (-not (Test-Path -LiteralPath $sourceCmd -PathType Leaf)) { throw "No se encuentra $sourceCmd" }
Copy-Item -LiteralPath $sourcePs1 -Destination (Join-Path $bin 'ias.ps1') -Force
Copy-Item -LiteralPath $sourceCmd -Destination (Join-Path $bin 'ias.cmd') -Force
$state = Join-Path $HOME '.ias\state'
if (-not (Test-Path -LiteralPath $state)) { New-Item -ItemType Directory -Path $state -Force | Out-Null }
$ignored = Join-Path $state 'ignored.json'
if (-not (Test-Path -LiteralPath $ignored)) { [System.IO.File]::WriteAllText($ignored, '{"ignored":[]}', (New-Object System.Text.UTF8Encoding($false))) }
$userPath = [Environment]::GetEnvironmentVariable('Path','User')
$entries = @($userPath -split ';' | Where-Object { $_ -and $_.TrimEnd('\') -ne $bin.TrimEnd('\') })
$entries += $bin
[Environment]::SetEnvironmentVariable('Path', ($entries -join ';'), 'User')
if (($env:Path -split ';' | Where-Object { $_.TrimEnd('\') -eq $bin.TrimEnd('\') }).Count -eq 0) { $env:Path += ";$bin" }
Write-Host "IAS 2.0 instalado en $bin" -ForegroundColor Green
Write-Host 'Cierra y vuelve a abrir PowerShell. Después ejecuta: ias plugins; ias catalog update' -ForegroundColor Cyan
