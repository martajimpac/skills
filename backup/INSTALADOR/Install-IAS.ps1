#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$InstallRoot = (Join-Path $HOME ".ias"),
    [string]$PluginsPath = (Join-Path $HOME ".ias\plugins"),
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$bin = Join-Path $InstallRoot "bin"
$corePath = Join-Path $bin "ias-core.ps1"
$cmdPath = Join-Path $bin "ias.cmd"
$configPath = Join-Path $InstallRoot "config.json"

Write-Host "Instalando IAS..." -ForegroundColor Cyan

if (-not (Test-Path -LiteralPath $PluginsPath -PathType Container)) {
    throw "No encuentro la carpeta de plugins: $PluginsPath`nCrea esa carpeta y coloca dentro tus plugins, o ejecuta: .\Install-IAS.ps1 -PluginsPath 'RUTA'"
}

if ((Test-Path $corePath) -and -not $Force) {
    $backup = "$corePath.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item -LiteralPath $corePath -Destination $backup
    Write-Host "Copia de seguridad del motor anterior: $backup" -ForegroundColor Yellow
}
if ((Test-Path $cmdPath) -and -not $Force) {
    $backup = "$cmdPath.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item -LiteralPath $cmdPath -Destination $backup
    Write-Host "Copia de seguridad del lanzador anterior: $backup" -ForegroundColor Yellow
}

New-Item -ItemType Directory -Path $bin -Force | Out-Null

$core = @'
#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Position=0)][string]$Command = "help",
    [Parameter(ValueFromRemainingArguments=$true)][string[]]$RemainingArgs
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$ConfigPath = Join-Path $Root "config.json"

function Say($text, $color = "Cyan") { Write-Host "[IAS] $text" -ForegroundColor $color }
function Fail($text) { Write-Host "[ERROR] $text" -ForegroundColor Red; exit 1 }

function Read-Config {
    if (-not (Test-Path -LiteralPath $ConfigPath)) { Fail "Falta config.json: $ConfigPath" }
    try { return (Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json) }
    catch { Fail "config.json no es válido: $($_.Exception.Message)" }
}

function Resolve-PathValue([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
    return [Environment]::ExpandEnvironmentVariables($Value.Replace("~", $HOME))
}

function Get-SkillFolders([string[]]$Roots) {
    $found = @()
    foreach ($rootValue in $Roots) {
        $root = Resolve-PathValue $rootValue
        if (-not $root -or -not (Test-Path -LiteralPath $root -PathType Container)) { continue }
        # SKILL.md es el marcador de una Skill. Se permite anidamiento (catálogos por plugin).
        Get-ChildItem -LiteralPath $root -Filter "SKILL.md" -File -Recurse -ErrorAction SilentlyContinue |
            ForEach-Object {
                $dir = $_.Directory.FullName
                $found += [PSCustomObject]@{ Name = $_.Directory.Name; Path = $dir; Root = $root }
            }
    }
    return @($found)
}

function Get-IgnoredNames([string]$Path) {
    $set = @{}
    if (Test-Path -LiteralPath $Path) {
        Get-Content -LiteralPath $Path | ForEach-Object {
            $n = $_.Trim()
            if ($n -and -not $n.StartsWith("#")) { $set[$n.ToLowerInvariant()] = $true }
        }
    }
    return $set
}

function Copy-SkillSafely([string]$Source, [string]$Destination, [bool]$WhatIf) {
    if ($WhatIf) { Say "WHATIF: $Destination <= $Source" "Yellow"; return }
    $parent = Split-Path -Parent $Destination
    $stage = Join-Path $parent (".ias-stage-" + [guid]::NewGuid().ToString("N"))
    $backup = Join-Path $parent (".ias-backup-" + [guid]::NewGuid().ToString("N"))
    try {
        New-Item -ItemType Directory -Path $stage -Force | Out-Null
        Get-ChildItem -LiteralPath $Source -Force | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination $stage -Recurse -Force
        }
        if (Test-Path -LiteralPath $Destination) {
            Move-Item -LiteralPath $Destination -Destination $backup
        }
        Move-Item -LiteralPath $stage -Destination $Destination
        if (Test-Path -LiteralPath $backup) { Remove-Item -LiteralPath $backup -Recurse -Force }
    }
    catch {
        if (Test-Path -LiteralPath $Destination) { Remove-Item -LiteralPath $Destination -Recurse -Force }
        if (Test-Path -LiteralPath $backup) { Move-Item -LiteralPath $backup -Destination $Destination }
        throw
    }
    finally {
        if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
    }
}

function Invoke-Update {
    $cfg = Read-Config
    $plugins = Resolve-PathValue $cfg.pluginsPath
    if (-not (Test-Path -LiteralPath $plugins -PathType Container)) { Fail "No existe la carpeta de plugins: $plugins" }

    # Protección explícita: MobiAI solo se actualiza si installed.json no registra packs globales.
    $installedState = Join-Path $HOME ".mobiai\state\installed.json"
    if ((Get-Command "mobiai" -ErrorAction SilentlyContinue) -and -not (Test-Path -LiteralPath $installedState)) {
        Fail "No existe installed.json para verificar los packs globales. Por seguridad no ejecutaré 'mobiai update'."
    }
    if (Test-Path -LiteralPath $installedState) {
        try {
            $state = Get-Content -LiteralPath $installedState -Raw | ConvertFrom-Json
            if ($state.packs -and @($state.packs.PSObject.Properties).Count -gt 0) {
                Fail "MobiAI registra packs instalados globalmente. Por seguridad no ejecutaré 'mobiai update'. Revisa $installedState."
            }
        } catch {
            if ($_.Exception.Message -like "MobiAI registra*") { throw }
            Fail "No puedo verificar installed.json; se cancela la actualización por seguridad."
        }
    }

    if (-not $cfg.skipOriginUpdates) {
        $commands = @($cfg.updateCommands)
        foreach ($entry in $commands) {
            $exe = [string]$entry.command
            $argsList = @($entry.args)
            if (-not (Get-Command $exe -ErrorAction SilentlyContinue)) {
                Say "No está instalado '$exe'; se omite: $($entry.label)" "Yellow"
                continue
            }
            Say "Actualizando origen: $($entry.label)"
            & $exe @argsList
            if ($LASTEXITCODE -ne 0) { Fail "Falló $exe $($argsList -join ' ') (código $LASTEXITCODE). No se sincronizarán archivos." }
        }
    }

    $roots = @($cfg.sourcePaths)
    $sourceSkills = @(Get-SkillFolders -Roots $roots)
    if ($sourceSkills.Count -eq 0) { Fail "No se encontraron Skills fuente. Comprueba sourcePaths en $ConfigPath." }

    $ignoredPath = Resolve-PathValue $cfg.ignoreFile
    $ignored = Get-IgnoredNames $ignoredPath
    $pluginDirs = @(Get-ChildItem -LiteralPath $plugins -Directory)
    $updated = 0
    $ignoredCount = 0
    $notFound = @()

    foreach ($plugin in $pluginDirs) {
        $skillsDir = Join-Path $plugin.FullName "skills"
        if (-not (Test-Path -LiteralPath $skillsDir -PathType Container)) { continue }

        foreach ($skill in Get-ChildItem -LiteralPath $skillsDir -Directory) {
            if ($ignored.ContainsKey($skill.Name.ToLowerInvariant())) {
                Say "Protegida por .sync-ignore: $($plugin.Name)/$($skill.Name)" "Yellow"
                $ignoredCount++
                continue
            }

            $matches = @($sourceSkills | Where-Object { $_.Name -ieq $skill.Name })
            if ($matches.Count -eq 0) {
                $notFound += "$($plugin.Name)/$($skill.Name)"
                continue
            }
            if ($matches.Count -gt 1) {
                Say "Hay $($matches.Count) fuentes para '$($skill.Name)'; se usará la primera según sourcePaths." "Yellow"
            }

            $source = $matches[0].Path
            Copy-SkillSafely -Source $source -Destination $skill.FullName -WhatIf ([bool]$cfg.dryRun)
            if (-not $cfg.dryRun) { $updated++ }
        }
    }

    Say "Resumen: sincronizadas=$updated; ignoradas=$ignoredCount; sin fuente=$($notFound.Count)" "Green"
    foreach ($item in ($notFound | Sort-Object -Unique)) { Say "Sin fuente, no modificada: $item" "Yellow" }
    Say "Finalizado. No se han instalado plugins en Claude Code ni Cursor." "Green"
}

switch ($Command.ToLowerInvariant()) {
    "update" {
        try { Invoke-Update } catch { Fail $_.Exception.Message }
    }
    "status" {
        $cfg = Read-Config
        Say "Plugins: $(Resolve-PathValue $cfg.pluginsPath)"
        Say "Fuentes configuradas:"
        foreach ($p in $cfg.sourcePaths) {
            $resolved = Resolve-PathValue $p
            $exists = Test-Path -LiteralPath $resolved -PathType Container
            Write-Host ("  [{0}] {1}" -f ($(if ($exists) {"OK"} else {"FALTA"}), $resolved))
        }
    }
    "help" { 
        Write-Host "IAS - Skills updater"
        Write-Host "  ias update  Actualiza orígenes configurados y sincroniza Skills existentes en plugins locales"
        Write-Host "  ias status  Comprueba rutas configuradas"
        Write-Host "  ias help    Muestra esta ayuda"
    }
    default { Write-Host "Comando desconocido: $Command"; Write-Host "Usa: ias help"; exit 2 }
}
'@

Set-Content -LiteralPath $corePath -Value $core -Encoding UTF8

$cmd = @'
@echo off
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0ias-core.ps1" %*
exit /b %ERRORLEVEL%
'@
Set-Content -LiteralPath $cmdPath -Value $cmd -Encoding ASCII

if (-not (Test-Path -LiteralPath $configPath) -or $Force) {
    $config = [ordered]@{
        pluginsPath = $PluginsPath
        sourcePaths = @(
            "$HOME\.claude\skills",
            "$HOME\.agents\skills",
            "$HOME\.mobiai\cache\catalog\skills"
        )
        ignoreFile = (Join-Path $InstallRoot ".sync-ignore")
        skipOriginUpdates = $false
        dryRun = $false
        updateCommands = @(
            @{ label = "MobiAI"; command = "mobiai"; args = @("update") },
            @{ label = "Android CLI"; command = "android"; args = @("skills", "update") },
            @{ label = "skills.sh / Supabase"; command = "npx"; args = @("skills", "update") }
        )
    }
    $config | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $configPath -Encoding UTF8
    $ignoreDefault = Join-Path $InstallRoot ".sync-ignore"
    if (-not (Test-Path -LiteralPath $ignoreDefault)) {
        Set-Content -LiteralPath $ignoreDefault -Value "# Una Skill por línea. Las líneas con # son comentarios." -Encoding UTF8
    }
} else {
    Write-Host "Se conserva config.json existente: $configPath" -ForegroundColor Yellow
}

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$entries = @($userPath -split ";" | Where-Object { $_ })
if ($entries -notcontains $bin) {
    $entries += $bin
    [Environment]::SetEnvironmentVariable("Path", ($entries -join ";"), "User")
}
if (($env:Path -split ";") -notcontains $bin) { $env:Path += ";$bin" }

Write-Host ""
Write-Host "IAS instalado." -ForegroundColor Green
Write-Host "Lanzador: $cmdPath"
Write-Host "Motor:    $corePath"
Write-Host "Config:   $configPath"
Write-Host ""
Write-Host "Cierra y abre PowerShell y ejecuta: ias status"
Write-Host "Después, cuando hayas revisado las rutas: ias update"
