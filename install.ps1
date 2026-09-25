# Install the react-native-optimization agent skill on Windows.
# https://github.com/christywho/react-native-optimization
#
#   irm https://raw.githubusercontent.com/christywho/react-native-optimization/main/install.ps1 | iex
#   & ([scriptblock]::Create((irm .../install.ps1))) -Claude -Version v1.0.0
#   .\install.ps1 -All            (from a clone)
#
# Run with -Help for all options.

[CmdletBinding()]
param(
    [switch]$Claude,
    [switch]$Agents,
    [switch]$Codex,
    [switch]$Gemini,
    [switch]$Cursor,
    [string[]]$Dir = @(),
    [switch]$All,
    [switch]$Project,
    [string]$Version = '',
    [switch]$Uninstall,
    [switch]$DryRun,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'
$UserHome = if ($env:RNO_HOME) { $env:RNO_HOME } else { $HOME }
$Repo = 'christywho/react-native-optimization'
$SkillName = 'react-native-optimization'
$GitHub = if ($env:RNO_GITHUB) { $env:RNO_GITHUB } else { 'https://github.com' }
$Api = if ($env:RNO_API) { $env:RNO_API } else { 'https://api.github.com' }
$DataHome = if ($env:RNO_HOME) { Join-Path $UserHome '.local/share' } elseif ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } else { Join-Path $UserHome '.local/share' }
$BackupDir = if ($env:RNO_BACKUP_DIR) { $env:RNO_BACKUP_DIR } else { Join-Path $DataHome "$SkillName/backups" }

function Show-Usage {
    @'
Usage: install.ps1 [targets] [options]

Targets (default: every host whose home folder already exists):
  -Claude           Claude Code          ~/.claude/skills
  -Agents           Codex, Gemini CLI,   ~/.agents/skills
                    Cursor, and other agents that read .agents/skills
  -Codex            alias for -Agents
  -Gemini           alias for -Agents
  -Cursor           alias for -Agents
  -Dir <path>       any other skills folder (comma-separate for several)
  -All              -Claude and -Agents

Options:
  -Project          install into the current project instead of your home folder
  -Version <tag>    release to install, e.g. v1.0.0 (default: latest release;
                    from a clone without -Version: the clone's files)
  -Uninstall        remove the skill from the selected targets
  -DryRun           print what would happen, change nothing
  -Help             show this help
'@
}

$script:IsDryRun = [bool]$DryRun

function Invoke-Step([string]$Description, [scriptblock]$Action) {
    if ($script:IsDryRun) { Write-Host "would: $Description" } else { & $Action }
}

if ($Help) { Show-Usage; return }

# ---- targets ----------------------------------------------------------------

$wantClaude = $Claude -or $All
$wantAgents = $Agents -or $Codex -or $Gemini -or $Cursor -or $All
$base = if ($Project) { (Get-Location).Path } else { $UserHome }

if (-not $wantClaude -and -not $wantAgents -and $Dir.Count -eq 0) {
    if (Test-Path (Join-Path $UserHome '.claude')) { $wantClaude = $true }
    foreach ($d in '.agents', '.codex', '.gemini', '.cursor') {
        if (Test-Path (Join-Path $UserHome $d)) { $wantAgents = $true }
    }
    if (-not $wantClaude -and -not $wantAgents) {
        Show-Usage
        throw "no agent host found in $UserHome; pick a target such as -Claude or -Agents"
    }
}

$targets = @()
if ($wantClaude) { $targets += Join-Path $base '.claude/skills' }
if ($wantAgents) { $targets += Join-Path $base '.agents/skills' }
$targets += $Dir

function Test-OurSkill([string]$Path) {
    $md = Join-Path $Path 'SKILL.md'
    (Test-Path $md) -and (Select-String -Path $md -Pattern "^name: $SkillName$" -Quiet)
}

# ---- uninstall --------------------------------------------------------------

if ($Uninstall) {
    foreach ($t in $targets) {
        $dest = Join-Path $t $SkillName
        if (Test-OurSkill $dest) {
            Invoke-Step "remove $dest" { Remove-Item -Recurse -Force $dest }
            Write-Host "removed $dest"
        } elseif (Test-Path $dest) {
            Write-Warning "$dest is not this skill; left in place"
        } else {
            Write-Host "not installed in $t"
        }
    }
    return
}

# ---- source -----------------------------------------------------------------

$tmp = $null
try {
    $scriptDir = if ($PSCommandPath) { Split-Path -Parent $PSCommandPath } else { $null }
    if (-not $Version -and $scriptDir -and (Test-Path (Join-Path $scriptDir 'skill/SKILL.md'))) {
        $src = Join-Path $scriptDir 'skill'
        $versionFile = Join-Path $scriptDir 'VERSION'
        $Version = if (Test-Path $versionFile) { (Get-Content $versionFile -Raw).Trim() } else { 'local' }
        Write-Host "installing $SkillName $Version from $scriptDir"
    } else {
        if (-not $Version) {
            $latest = Invoke-RestMethod -Uri "$Api/repos/$Repo/releases/latest" -Headers @{ 'User-Agent' = $SkillName }
            $Version = $latest.tag_name
            if (-not $Version) { throw "no published release found for $Repo" }
        }
        $tmp = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
        New-Item -ItemType Directory -Path $tmp | Out-Null
        $url = "$GitHub/$Repo/archive/refs/tags/$Version.tar.gz"
        $archive = Join-Path $tmp 'src.tar.gz'
        Write-Host "downloading $SkillName $Version"
        try {
            Invoke-WebRequest -Uri $url -OutFile $archive -UseBasicParsing
        } catch {
            throw "download failed: $url (does tag $Version exist?)"
        }
        tar -xzf $archive -C $tmp
        if ($LASTEXITCODE -ne 0) { throw "could not unpack $url" }
        $src = Get-ChildItem -Path $tmp -Directory | ForEach-Object { Join-Path $_.FullName 'skill' } |
            Where-Object { Test-Path (Join-Path $_ 'SKILL.md') } | Select-Object -First 1
        if (-not $src) { throw "release $Version has no skill/ folder" }
    }

    # ---- install ------------------------------------------------------------

    $stamp = Get-Date -Format 'yyyyMMddHHmmss'

    function Get-TreeHash([string]$Path) {
        Get-ChildItem -Path $Path -Recurse -File | Where-Object { $_.Name -ne '.version' } |
            Sort-Object { $_.FullName.Substring($Path.Length) } |
            ForEach-Object { $_.FullName.Substring($Path.Length).Replace('\', '/') + ':' + (Get-FileHash $_.FullName).Hash }
    }

    foreach ($t in $targets) {
        $dest = Join-Path $t $SkillName
        if (Test-Path $dest) {
            $same = (@(Get-TreeHash $dest) -join "`n") -eq (@(Get-TreeHash $src) -join "`n")
            if ($same) {
                Invoke-Step "remove $dest" { Remove-Item -Recurse -Force $dest }
            } else {
                # Backups live outside the skills folder so hosts don't load them as a second copy.
                $bak = Join-Path $BackupDir ("$SkillName-$stamp-" + ($t -replace '[\\/: ]', '_'))
                Invoke-Step "move $dest to $bak" {
                    New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
                    Move-Item $dest $bak
                }
                Write-Host "existing copy differed; backed up to $bak"
            }
        }
        Invoke-Step "copy $src to $dest" {
            New-Item -ItemType Directory -Force -Path $t | Out-Null
            Copy-Item -Recurse $src $dest
            Set-Content -Path (Join-Path $dest '.version') -Value $Version
        }
        Write-Host "installed $SkillName $Version -> $dest"
    }

    if (-not $Project -and (Test-Path (Join-Path $UserHome ".codex/skills/$SkillName"))) {
        Write-Warning "an older copy exists in ~/.codex/skills; current Codex reads ~/.agents/skills. Remove the old copy to avoid running a stale version."
    }
} finally {
    if ($tmp -and (Test-Path $tmp)) { Remove-Item -Recurse -Force $tmp }
}
