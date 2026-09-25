# Pester tests for install.ps1 (run on Windows CI):
#   Invoke-Pester tests/install.Tests.ps1

BeforeAll {
    $Root = Split-Path -Parent $PSScriptRoot
    $Installer = Join-Path $Root 'install.ps1'

    function New-Case {
        $dir = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
        $script:H = Join-Path $dir 'home'
        $script:P = Join-Path $dir 'project'
        New-Item -ItemType Directory -Force -Path $script:H, $script:P | Out-Null
    }

    function Invoke-Installer([hashtable]$Params) {
        $env:RNO_HOME = $script:H
        $env:RNO_BACKUP_DIR = Join-Path $script:H 'backups'
        Push-Location $script:P
        try { & $Installer @Params } finally {
            Pop-Location
            Remove-Item Env:RNO_HOME, Env:RNO_BACKUP_DIR -ErrorAction SilentlyContinue
        }
    }
}

Describe 'install.ps1 from a clone' {
    BeforeEach { New-Case }

    It 'installs into ~/.claude/skills' {
        Invoke-Installer @{ Claude = $true }
        Join-Path $H '.claude/skills/react-native-optimization/SKILL.md' | Should -Exist
        Join-Path $H '.claude/skills/react-native-optimization/references/static-scan.md' | Should -Exist
    }

    It 'maps -Codex to ~/.agents/skills' {
        Invoke-Installer @{ Codex = $true }
        Join-Path $H '.agents/skills/react-native-optimization/SKILL.md' | Should -Exist
    }

    It 'installs into the project with -Project' {
        Invoke-Installer @{ All = $true; Project = $true }
        Join-Path $P '.claude/skills/react-native-optimization/SKILL.md' | Should -Exist
        Join-Path $P '.agents/skills/react-native-optimization/SKILL.md' | Should -Exist
    }

    It 'backs up an edited copy outside the skills folder' {
        Invoke-Installer @{ Claude = $true }
        Add-Content (Join-Path $H '.claude/skills/react-native-optimization/SKILL.md') 'local tweak'
        Invoke-Installer @{ Claude = $true }
        @(Get-ChildItem (Join-Path $H 'backups')).Count | Should -Be 1
        @(Get-ChildItem (Join-Path $H '.claude/skills')).Count | Should -Be 1
    }

    It 'writes nothing with -DryRun' {
        Invoke-Installer @{ All = $true; DryRun = $true }
        Join-Path $H '.claude' | Should -Not -Exist
    }

    It 'removes the skill with -Uninstall' {
        Invoke-Installer @{ All = $true }
        Invoke-Installer @{ All = $true; Uninstall = $true }
        Join-Path $H '.claude/skills/react-native-optimization' | Should -Not -Exist
        Join-Path $H '.agents/skills/react-native-optimization' | Should -Not -Exist
    }
}
