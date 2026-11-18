# IAS 2.0 - Gestor de Skills por proyecto
# Compatible con Windows PowerShell 5.1
# Fuente exclusiva: $HOME\.ias\plugins
# No modifica plugins originales ni instalaciones globales de Claude/Cursor.

[CmdletBinding()]
param(
    [Parameter(Position=0)][string]$Command,
    [Parameter(Position=1)][string]$Argument,
    [Parameter(ValueFromRemainingArguments=$true)][string[]]$ExtraArgs
)

$ErrorActionPreference = 'Stop'
$script:IasHome = Join-Path $HOME '.ias'
$script:PluginRoot = Join-Path $script:IasHome 'plugins'
$script:StateRoot = Join-Path $script:IasHome 'state'
$script:IgnoredFile = Join-Path $script:StateRoot 'ignored.json'
$script:CatalogFile = Join-Path $script:StateRoot 'catalog.json'

function Ensure-State {
    if (-not (Test-Path -LiteralPath $script:StateRoot)) {
        New-Item -ItemType Directory -Path $script:StateRoot -Force | Out-Null
    }
    if (-not (Test-Path -LiteralPath $script:IgnoredFile)) {
        Write-JsonAtomic -Path $script:IgnoredFile -Data ([PSCustomObject]@{ ignored = @() })
    }
}

function Write-JsonAtomic {
    param([string]$Path, $Data)
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $tmp = "$Path.tmp"
    $json = ConvertTo-Json -InputObject $Data -Depth 15
    [System.IO.File]::WriteAllText($tmp, $json, (New-Object System.Text.UTF8Encoding($false)))
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}

function Read-Json {
    param([string]$Path, $Default)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $Default }
    $raw = [System.IO.File]::ReadAllText($Path)
    if ([string]::IsNullOrWhiteSpace($raw)) { return $Default }
    return ($raw | ConvertFrom-Json -ErrorAction Stop)
}

function Get-Ignored {
    Ensure-State
    $data = Read-Json -Path $script:IgnoredFile -Default ([PSCustomObject]@{ ignored = @() })
    if ($null -eq $data.ignored) { return @() }
    return @($data.ignored | ForEach-Object { [string]$_ })
}

function Get-Catalog {
    if (-not (Test-Path -LiteralPath $script:PluginRoot -PathType Container)) {
        throw "No existe el directorio de plugins IAS: $script:PluginRoot"
    }
    $items = New-Object System.Collections.Generic.List[object]
    foreach ($dir in @(Get-ChildItem -LiteralPath $script:PluginRoot -Directory -Force)) {
        $skillsRoot = Join-Path $dir.FullName 'skills'
        if (-not (Test-Path -LiteralPath $skillsRoot -PathType Container)) { continue }
        $manifest = Join-Path $dir.FullName '.claude-plugin\plugin.json'
        $pluginName = $dir.Name
        $version = ''
        $pluginDescription = ''
        if (Test-Path -LiteralPath $manifest -PathType Leaf) {
            try {
                $m = Read-Json -Path $manifest -Default $null
                if ($m.name) { $pluginName = [string]$m.name }
                if ($m.version) { $version = [string]$m.version }
                if ($m.description) { $pluginDescription = [string]$m.description }
            } catch { Write-Warning "Manifiesto inválido: $manifest" }
        }
        foreach ($skillDir in @(Get-ChildItem -LiteralPath $skillsRoot -Directory -Force)) {
            $skillFile = Join-Path $skillDir.FullName 'SKILL.md'
            if (-not (Test-Path -LiteralPath $skillFile -PathType Leaf)) { continue }
            $description = ''
            $lines = @(Get-Content -LiteralPath $skillFile -TotalCount 40 -ErrorAction SilentlyContinue)
            $inFrontMatter = $false
            $frontMatterStarted = $false
            foreach ($line in $lines) {
                $t = ([string]$line).Trim()
                if ($t -eq '---') {
                    if (-not $frontMatterStarted) { $frontMatterStarted = $true; $inFrontMatter = $true; continue }
                    if ($inFrontMatter) { $inFrontMatter = $false; continue }
                }
                if (-not $inFrontMatter -and $t -and -not $t.StartsWith('#')) { $description = $t; break }
            }
            $items.Add([PSCustomObject]@{
                Id = "$pluginName/$($skillDir.Name)"
                Plugin = $pluginName
                Version = $version
                PluginDescription = $pluginDescription
                Name = $skillDir.Name
                Path = $skillDir.FullName
                Description = $description
            })
        }
    }
    return @($items | Sort-Object Plugin, Name)
}

function Get-Project {
    $root = (Get-Location).ProviderPath
    $dir = Join-Path $root '.ias'
    return [PSCustomObject]@{
        Root = $root
        IasDir = $dir
        Config = Join-Path $dir 'project.json'
        Managed = Join-Path $dir 'managed.json'
        ClaudeSkills = Join-Path $root '.claude\skills'
        CursorSkills = Join-Path $root '.cursor\skills'
        Backups = Join-Path $dir 'backups'
    }
}

function Get-ProjectConfig {
    param([switch]$Required)
    $p = Get-Project
    if (-not (Test-Path -LiteralPath $p.Config -PathType Leaf)) {
        if ($Required) { throw "Este repositorio no está configurado. Ejecuta 'ias select'." }
        return $null
    }
    $cfg = Read-Json -Path $p.Config -Default $null
    if ($null -eq $cfg) { if ($Required) { throw "No se pudo leer $($p.Config)" }; return $null }
    if ($null -eq $cfg.selected) { $cfg | Add-Member -NotePropertyName selected -NotePropertyValue @() -Force }
    return $cfg
}

function Get-Managed {
    param($Project)
    $data = Read-Json -Path $Project.Managed -Default ([PSCustomObject]@{ items = @() })
    if ($null -eq $data -or $null -eq $data.items) { return @() }
    return @($data.items)
}

function Save-ProjectSelection {
    param([string[]]$Ids)
    $p = Get-Project
    if (-not (Test-Path -LiteralPath $p.IasDir)) { New-Item -ItemType Directory -Path $p.IasDir -Force | Out-Null }
    $cfg = [PSCustomObject]@{ schemaVersion = 2; selected = @($Ids | Sort-Object -Unique); hosts = @('claude','cursor'); updatedAt = (Get-Date).ToString('s') }
    Write-JsonAtomic -Path $p.Config -Data $cfg
}

function Show-Help {
    Write-Host "IAS 2.0 - Skills por proyecto" -ForegroundColor Cyan
    Write-Host "Fuente exclusiva: $script:PluginRoot"
    Write-Host '  ias list [plugin]          Lista Skills locales'
    Write-Host '  ias plugins                Resume los plugins'
    Write-Host '  ias select [plugin]        Selecciona Skills para este repo'
    Write-Host '  ias install                Instala la selección en Claude y Cursor del repo'
    Write-Host '  ias adopt                  Registra Skills antiguas si son idénticas a la fuente'
    Write-Host '  ias update                 Actualiza MobiAI y solo Skills ya gestionadas'
    Write-Host '  ias ignore <plugin/skill>  Ignora una Skill globalmente'
    Write-Host '  ias unignore <plugin/skill> Quita la exclusión global'
    Write-Host '  ias status                 Estado del repo'
    Write-Host '  ias catalog update         Reconstruye índice de plugins locales'
}

function Show-Plugins {
    $cat = @(Get-Catalog)
    foreach ($g in @($cat | Group-Object Plugin)) {
        $f = $g.Group | Select-Object -First 1
        Write-Host ("{0,-22} {1,3} Skills  {2}" -f $g.Name, $g.Count, $f.Version) -ForegroundColor Cyan
    }
    Write-Host "Total: $($cat.Count) Skills" -ForegroundColor Green
}

function Show-List {
    param([string]$Plugin)
    $cat = @(Get-Catalog)
    if ($Plugin) { $cat = @($cat | Where-Object { $_.Plugin -eq $Plugin }) }
    if ($cat.Count -eq 0) { Write-Host 'No hay Skills para mostrar.' -ForegroundColor Yellow; return }
    $ignored = @(Get-Ignored)
    $cfg = Get-ProjectConfig
    $selected = @(); if ($cfg) { $selected = @($cfg.selected) }
    foreach ($g in @($cat | Group-Object Plugin)) {
        Write-Host "`n[$($g.Name)]" -ForegroundColor Cyan
        foreach ($s in $g.Group) {
            $tag = if ($ignored -contains $s.Id) { ' [IGNORADA]' } elseif ($selected -contains $s.Id) { ' [SELECCIONADA]' } else { '' }
            Write-Host "  $($s.Name)$tag"
            if ($s.Description) { Write-Host "    $($s.Description)" -ForegroundColor DarkGray }
        }
    }
}

function Select-Skills {
    param([string]$Plugin)
    $cat = @(Get-Catalog)
    $ignored = @(Get-Ignored)
    $available = @($cat | Where-Object { $ignored -notcontains $_.Id })
    if ($Plugin) { $available = @($available | Where-Object { $_.Plugin -eq $Plugin }) }
    if ($available.Count -eq 0) { Write-Host 'No hay Skills disponibles.' -ForegroundColor Yellow; return }
    $cfg = Get-ProjectConfig
    $old = @(); if ($cfg) { $old = @($cfg.selected) }
    Write-Host "Selecciona números separados por comas; 'all' selecciona todas las mostradas; 'q' cancela." -ForegroundColor Cyan
    for ($i=0; $i -lt $available.Count; $i++) {
        $mark = if ($old -contains $available[$i].Id) { '[x]' } else { '[ ]' }
        Write-Host ("{0,3}. {1} {2}" -f ($i+1), $mark, $available[$i].Id)
    }
    $answer = Read-Host 'Selección'
    if ($answer -eq 'q') { Write-Host 'Cancelado.'; return }
    $chosen = @()
    if ($answer -eq 'all') { $chosen = @($available | ForEach-Object { $_.Id }) }
    elseif (-not [string]::IsNullOrWhiteSpace($answer)) {
        foreach ($part in ($answer -split '[,; ]+' | Where-Object { $_ })) {
            $n = 0
            if (-not [int]::TryParse($part, [ref]$n) -or $n -lt 1 -or $n -gt $available.Count) { throw "Número no válido: $part" }
            $chosen += $available[$n-1].Id
        }
    }
    if ($Plugin) { $chosen = @(($old | Where-Object { ($_ -split '/')[0] -ne $Plugin }) + $chosen) }
    Save-ProjectSelection -Ids $chosen
    Write-Host 'Selección guardada en .ias\project.json' -ForegroundColor Green
}

function Save-ManagedRecord {
    param($Project, [string]$Id, [string]$HostName, [string]$Target)
    $records = @(Get-Managed -Project $Project | Where-Object { -not ($_.id -eq $Id -and $_.host -eq $HostName) })
    $records += [PSCustomObject]@{ id=$Id; host=$HostName; target=$Target; updatedAt=(Get-Date).ToString('s') }
    Write-JsonAtomic -Path $Project.Managed -Data ([PSCustomObject]@{ items=@($records) })
}

function Sync-Skill {
    param($Project, $Skill, [string]$HostName, [switch]$UpdateOnly)
    $base = if ($HostName -eq 'claude') { $Project.ClaudeSkills } else { $Project.CursorSkills }
    $target = Join-Path $base $Skill.Name
    $records = @(Get-Managed -Project $Project)
    $isManaged = @($records | Where-Object { $_.id -eq $Skill.Id -and $_.host -eq $HostName }).Count -gt 0
    if ($UpdateOnly -and -not $isManaged) { Write-Host "  [OMITIDA] $($Skill.Id): no estaba gestionada en $HostName" -ForegroundColor Yellow; return $false }
    if ((Test-Path -LiteralPath $target) -and -not $isManaged) { Write-Host "  [PROTEGIDA] Existe una carpeta ajena a IAS: $target" -ForegroundColor Yellow; return $false }
    if (-not (Test-Path -LiteralPath $base)) { New-Item -ItemType Directory -Path $base -Force | Out-Null }
    $stage = Join-Path $base ('.ias-stage-' + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $stage -Force | Out-Null
    try {
        Get-ChildItem -LiteralPath $Skill.Path -Force | Copy-Item -Destination $stage -Recurse -Force
        if (Test-Path -LiteralPath $target) {
            $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
            $backupDir = Join-Path (Join-Path $Project.Backups $stamp) $HostName
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            $safe = $Skill.Id -replace '[^a-zA-Z0-9._-]','_'
            $backup = Join-Path $backupDir $safe
            if (Test-Path -LiteralPath $backup) { $backup += '-' + [Guid]::NewGuid().ToString('N') }
            Move-Item -LiteralPath $target -Destination $backup
            try { Move-Item -LiteralPath $stage -Destination $target }
            catch { if (-not (Test-Path -LiteralPath $target) -and (Test-Path -LiteralPath $backup)) { Move-Item -LiteralPath $backup -Destination $target }; throw }
        } else { Move-Item -LiteralPath $stage -Destination $target }
        Save-ManagedRecord -Project $Project -Id $Skill.Id -HostName $HostName -Target $target
        Write-Host "  [OK] $($Skill.Id) -> $HostName" -ForegroundColor Green
        return $true
    } finally { if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue } }
}

function Install-Selection {
    param([switch]$UpdateOnly)
    $project = Get-Project
    $cfg = Get-ProjectConfig -Required
    $cat = @(Get-Catalog)
    $ignored = @(Get-Ignored)
    $count = 0
    foreach ($id in @($cfg.selected)) {
        if ($ignored -contains $id) { Write-Host "[IGNORADA] $id" -ForegroundColor DarkYellow; continue }
        $found = @($cat | Where-Object { $_.Id -eq $id })
        if ($found.Count -ne 1) { Write-Host "[NO ENCONTRADA] $id" -ForegroundColor Yellow; continue }
        foreach ($hostName in @('claude','cursor')) {
            if (Sync-Skill -Project $project -Skill $found[0] -HostName $hostName -UpdateOnly:$UpdateOnly) { $count++ }
        }
    }
    Write-Host "Sincronizaciones completadas: $count" -ForegroundColor Cyan
    if ($UpdateOnly) { Write-Host "Respaldos: $($project.Backups)" -ForegroundColor DarkGray }
}

function Set-Ignore {
    param([string]$Id, [switch]$Remove)
    $cat = @(Get-Catalog)
    if ([string]::IsNullOrWhiteSpace($Id)) { Get-Ignored | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }; return }
    $matches = @($cat | Where-Object { $_.Id -eq $Id })
    if ($matches.Count -eq 0) { $matches = @($cat | Where-Object { $_.Name -eq $Id }) }
    if ($matches.Count -ne 1) { throw "Skill no encontrada o ambigua: $Id. Usa plugin/skill." }
    $canonical = $matches[0].Id
    $ignored = @(Get-Ignored)
    if ($Remove) { $ignored = @($ignored | Where-Object { $_ -ne $canonical }) }
    elseif ($ignored -notcontains $canonical) { $ignored += $canonical }
    Write-JsonAtomic -Path $script:IgnoredFile -Data ([PSCustomObject]@{ ignored=@($ignored | Sort-Object -Unique) })
    if ($Remove) { Write-Host "Ya no se ignora: $canonical" -ForegroundColor Green }
    else { Write-Host "Ignorada: $canonical. No se borrarán copias existentes." -ForegroundColor Green }
}


function Test-FolderMatch {
    param([string]$Source, [string]$Destination)
    if (-not (Test-Path -LiteralPath $Source -PathType Container) -or -not (Test-Path -LiteralPath $Destination -PathType Container)) { return $false }
    $srcFiles = @(Get-ChildItem -LiteralPath $Source -File -Recurse -Force)
    $dstFiles = @(Get-ChildItem -LiteralPath $Destination -File -Recurse -Force)
    if ($srcFiles.Count -ne $dstFiles.Count) { return $false }
    foreach ($file in $srcFiles) {
        $relative = $file.FullName.Substring($Source.TrimEnd('\\').Length).TrimStart('\\')
        $other = Join-Path $Destination $relative
        if (-not (Test-Path -LiteralPath $other -PathType Leaf)) { return $false }
        $h1 = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
        $h2 = (Get-FileHash -LiteralPath $other -Algorithm SHA256).Hash
        if ($h1 -ne $h2) { return $false }
    }
    return $true
}

function Adopt-ExistingSkills {
    $project = Get-Project
    $cfg = Get-ProjectConfig -Required
    $cat = @(Get-Catalog)
    $ignored = @(Get-Ignored)
    $added = 0
    foreach ($id in @($cfg.selected)) {
        if ($ignored -contains $id) { Write-Host "[IGNORADA] $id" -ForegroundColor DarkYellow; continue }
        $skill = $cat | Where-Object { $_.Id -eq $id } | Select-Object -First 1
        if (-not $skill) { Write-Host "[NO ENCONTRADA] $id" -ForegroundColor Yellow; continue }
        foreach ($hostName in @('claude','cursor')) {
            $base = if ($hostName -eq 'claude') { $project.ClaudeSkills } else { $project.CursorSkills }
            $target = Join-Path $base $skill.Name
            if (-not (Test-Path -LiteralPath $target -PathType Container)) { Write-Host "[NO EXISTE] $id en $hostName" -ForegroundColor DarkGray; continue }
            if (Test-FolderMatch -Source $skill.Path -Destination $target) {
                Save-ManagedRecord -Project $project -Id $id -HostName $hostName -Target $target
                Write-Host "[ADOPTADA] $id en $hostName (contenido idéntico)" -ForegroundColor Green
                $added++
            } else {
                Write-Host "[NO ADOPTADA] $id en ${hostName}: el contenido no coincide; no se ha modificado nada." -ForegroundColor Yellow
            }
        }
    }
    Write-Host "Adopciones realizadas: $added" -ForegroundColor Cyan
}

function Update-Mobiai {
    $installedPath = Join-Path $HOME '.mobiai\state\installed.json'
    if (-not (Test-Path -LiteralPath $installedPath -PathType Leaf)) { throw "No se puede verificar installed.json: $installedPath. Se cancela por seguridad." }
    $state = Read-Json -Path $installedPath -Default $null
    if ($null -eq $state -or $null -eq $state.packs) { throw 'installed.json no tiene el formato esperado. Se cancela por seguridad.' }
    $registered = @($state.packs.PSObject.Properties)
    if ($registered.Count -gt 0) { throw 'Hay packs globales registrados en MobiAI. Para evitar reinstalaciones globales, IAS no ejecutará mobiai update.' }
    $cmd = Get-Command mobiai -ErrorAction SilentlyContinue
    if (-not $cmd) { throw "No se encuentra 'mobiai' en PATH." }
    Write-Host '[1/2] Ejecutando mobiai update...' -ForegroundColor Cyan
    & $cmd.Source update
    if ($LASTEXITCODE -ne 0) { throw "mobiai update falló con código $LASTEXITCODE. No se actualizarán Skills del proyecto." }
    Write-Host '[OK] MobiAI actualizado; packs globales registrados: ninguno.' -ForegroundColor Green
}

function Update-CatalogIndex {
    $cat = @(Get-Catalog)
    $plugins = @($cat | Group-Object Plugin | ForEach-Object {
        $first = $_.Group | Select-Object -First 1
        [PSCustomObject]@{ name=$_.Name; version=$first.Version; description=$first.PluginDescription; skills=@($_.Group | ForEach-Object { $_.Id }) }
    })
    Write-JsonAtomic -Path $script:CatalogFile -Data ([PSCustomObject]@{ schemaVersion=1; source=$script:PluginRoot; generatedAt=(Get-Date).ToString('s'); skillCount=$cat.Count; plugins=$plugins })
    Write-Host "Índice reconstruido: $($cat.Count) Skills, $($plugins.Count) plugins." -ForegroundColor Green
    Write-Host 'Solo se han leído tus plugins locales; no se han descargado ni modificado.' -ForegroundColor DarkGray
}

function Show-Status {
    $p = Get-Project
    $cfg = Get-ProjectConfig
    if (-not $cfg) { Write-Host "Proyecto sin configurar: $($p.Root). Ejecuta ias select." -ForegroundColor Yellow; return }
    $cat = @(Get-Catalog); $ignored = @(Get-Ignored); $managed = @(Get-Managed -Project $p)
    Write-Host "Proyecto: $($p.Root)" -ForegroundColor Cyan
    foreach ($id in @($cfg.selected)) {
        if ($ignored -contains $id) { Write-Host "  $id [IGNORADA]" -ForegroundColor DarkYellow; continue }
        $s = $cat | Where-Object { $_.Id -eq $id } | Select-Object -First 1
        if (-not $s) { Write-Host "  $id [NO ENCONTRADA]" -ForegroundColor Red; continue }
        $parts = @()
        foreach ($h in @('claude','cursor')) {
            $base = if ($h -eq 'claude') { $p.ClaudeSkills } else { $p.CursorSkills }
            $target = Join-Path $base $s.Name
            $recorded = @($managed | Where-Object { $_.id -eq $id -and $_.host -eq $h }).Count -gt 0
            $parts += if ($recorded -and (Test-Path -LiteralPath $target)) { "$h OK" } else { "$h no instalada" }
        }
        Write-Host ("  {0} | {1}" -f $id, ($parts -join ' | '))
    }
}

try {
    Ensure-State
    switch ($Command) {
        'list' { Show-List -Plugin $Argument }
        'plugins' { Show-Plugins }
        'select' { Select-Skills -Plugin $Argument }
        'install' { Install-Selection }
        'adopt' { Adopt-ExistingSkills }
        'update' {
            $null = Get-ProjectConfig -Required
            Update-Mobiai
            Write-Host '[2/2] Actualizando Skills seleccionadas que IAS ya gestiona...' -ForegroundColor Cyan
            Install-Selection -UpdateOnly
        }
        'ignore' { Set-Ignore -Id $Argument }
        'unignore' { Set-Ignore -Id $Argument -Remove }
        'status' { Show-Status }
        'catalog' { if ($Argument -eq 'update') { Update-CatalogIndex } else { Write-Host 'Uso: ias catalog update' -ForegroundColor Yellow } }
        default { Show-Help }
    }
} catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
