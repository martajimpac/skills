# Instalador IAS 2.0 - Windows PowerShell 5.1
# Instala el motor como ias-core.ps1 para que PowerShell no intente
# ejecutar ias.ps1 directamente y respete el lanzador ias.cmd.
$ErrorActionPreference = 'Stop'

$iasHome = Join-Path $HOME '.ias'
$bin = Join-Path $iasHome 'bin'
$plugins = Join-Path $iasHome 'plugins'
$sourceEngine = Join-Path $PSScriptRoot 'ias.ps1'
$sourceCmd = Join-Path $PSScriptRoot 'ias.cmd'

if (-not (Test-Path -LiteralPath $plugins -PathType Container)) {
    throw "No existe el directorio de plugins: $plugins. No se ha modificado la instalación."
}
if (-not (Test-Path -LiteralPath $sourceEngine -PathType Leaf)) {
    throw "No se encuentra el motor de IAS: $sourceEngine"
}
if (-not (Test-Path -LiteralPath $sourceCmd -PathType Leaf)) {
    throw "No se encuentra el lanzador: $sourceCmd"
}

# Validar sintaxis del motor antes de modificar la instalación existente.
$tokens = $null
$parseErrors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($sourceEngine, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors -and $parseErrors.Count -gt 0) {
    $details = ($parseErrors | ForEach-Object { $_.Message }) -join '; '
    throw "El motor IAS contiene errores de sintaxis. No se ha modificado la instalación: $details"
}

if (-not (Test-Path -LiteralPath $bin -PathType Container)) {
    New-Item -ItemType Directory -Path $bin -Force | Out-Null
}

# Crear una copia de seguridad versionada antes de sustituir archivos.
$backupRoot = Join-Path $iasHome 'installer-backups'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backup = Join-Path $backupRoot $stamp
New-Item -ItemType Directory -Path $backup -Force | Out-Null

foreach ($name in @('ias.ps1', 'ias-core.ps1', 'ias.cmd')) {
    $existing = Join-Path $bin $name
    if (Test-Path -LiteralPath $existing -PathType Leaf) {
        Copy-Item -LiteralPath $existing -Destination (Join-Path $backup $name) -Force
    }
}

# Desplegar el motor con un nombre que no colisione con el comando "ias".
$coreTarget = Join-Path $bin 'ias-core.ps1'
Copy-Item -LiteralPath $sourceEngine -Destination $coreTarget -Force
Copy-Item -LiteralPath $sourceCmd -Destination (Join-Path $bin 'ias.cmd') -Force

# Retirar del directorio PATH el antiguo ias.ps1: PowerShell lo prioriza
# frente a ias.cmd y lo ejecuta directamente, saltándose el bypass del .cmd.
$oldScript = Join-Path $bin 'ias.ps1'
if (Test-Path -LiteralPath $oldScript -PathType Leaf) {
    $legacyTarget = Join-Path $backup 'ias.ps1.disabled'
    Move-Item -LiteralPath $oldScript -Destination $legacyTarget -Force
}

# Crear estado sin sobrescribir el estado existente.
$state = Join-Path $iasHome 'state'
if (-not (Test-Path -LiteralPath $state -PathType Container)) {
    New-Item -ItemType Directory -Path $state -Force | Out-Null
}
$ignored = Join-Path $state 'ignored.json'
if (-not (Test-Path -LiteralPath $ignored -PathType Leaf)) {
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($ignored, '{"ignored":[]}', $utf8NoBom)
}

# Añadir la carpeta bin al PATH del usuario sin duplicarla.
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($null -eq $userPath) { $userPath = '' }
$entries = @($userPath -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
$normalizedBin = $bin.TrimEnd('\')
$alreadyThere = $false
foreach ($entry in $entries) {
    if ($entry.Trim().TrimEnd('\') -ieq $normalizedBin) { $alreadyThere = $true; break }
}
if (-not $alreadyThere) { $entries += $bin }
[Environment]::SetEnvironmentVariable('Path', ($entries -join ';'), 'User')

# Refrescar también el PATH de esta ventana para poder probar inmediatamente.
$currentEntries = @($env:Path -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
$currentThere = $false
foreach ($entry in $currentEntries) {
    if ($entry.Trim().TrimEnd('\') -ieq $normalizedBin) { $currentThere = $true; break }
}
if (-not $currentThere) { $env:Path = ($env:Path.TrimEnd(';') + ';' + $bin) }

Write-Host ''
Write-Host 'IAS 2.0 instalado correctamente.' -ForegroundColor Green
Write-Host "Motor: $coreTarget" -ForegroundColor Cyan
Write-Host "Lanzador: $(Join-Path $bin 'ias.cmd')" -ForegroundColor Cyan
Write-Host "Copia de seguridad: $backup" -ForegroundColor DarkGray
Write-Host ''
Write-Host 'Cierra y abre PowerShell y comprueba:' -ForegroundColor Yellow
Write-Host '  Get-Command ias -All'
Write-Host '  ias plugins'
