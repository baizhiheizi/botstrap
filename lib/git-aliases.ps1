#requires -Version 5.1
# Git alias catalog helpers and Phase 3 apply logic (Windows).

function Get-BotstrapGitAliasesYaml {
    Join-Path $env:BOTSTRAP_ROOT 'configs\git\aliases.yaml'
}

function Get-BotstrapGitAliasesConfigDir {
    Join-Path $env:USERPROFILE '.config\botstrap'
}

function Get-BotstrapGitAliasesFragmentPath {
    Join-Path (Get-BotstrapGitAliasesConfigDir) 'git-aliases'
}

function Get-BotstrapGitAliasesEnvPath {
    Join-Path (Get-BotstrapGitAliasesConfigDir) 'git-aliases.env'
}

function Get-BotstrapGitAliasesUserGitconfig {
    Join-Path $env:USERPROFILE '.gitconfig'
}

function Get-BotstrapGitAliasesDefaultCsv {
    $yaml = Get-BotstrapGitAliasesYaml
    if (-not (Test-Path -LiteralPath $yaml)) { return '' }
    $enabled = & yq -r '.defaults.enabled // true' $yaml 2>$null
    if ("$enabled" -ne 'true') { return '' }
    $ids = @(& yq -r '.aliases[] | select(.default == true) | .id' $yaml 2>$null | ForEach-Object { "$_".Trim() } | Where-Object { $_ })
    return ($ids -join ',')
}

function Get-BotstrapGitAliasEntry {
    param([Parameter(Mandatory)][string]$Id)
    $yaml = Get-BotstrapGitAliasesYaml
    if (-not (Test-Path -LiteralPath $yaml)) { return $null }
    $env:BOTSTRAP_ALIAS_ID = $Id
    $name = & yq -r '.aliases[] | select(.id == strenv(BOTSTRAP_ALIAS_ID)) | .name' $yaml 2>$null
    $command = & yq -r '.aliases[] | select(.id == strenv(BOTSTRAP_ALIAS_ID)) | .command' $yaml 2>$null
    Remove-Item Env:BOTSTRAP_ALIAS_ID -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace("$name")) { return $null }
    return [pscustomobject]@{ Name = "$name".Trim(); Command = "$command".Trim() }
}

function Get-BotstrapGitAliasesPreviewLines {
    $yaml = Get-BotstrapGitAliasesYaml
    if (-not (Test-Path -LiteralPath $yaml)) { return @() }
    return @(& yq -r '.aliases[] | "\(.id) → \(.command) — \(.description)"' $yaml 2>$null | ForEach-Object { "$_".Trim() } | Where-Object { $_ })
}

function Get-BotstrapGitAliasesChooseLabels {
    $yaml = Get-BotstrapGitAliasesYaml
    if (-not (Test-Path -LiteralPath $yaml)) { return @() }
    return @(& yq -r '.aliases[] | "\(.id) → \(.command)"' $yaml 2>$null | ForEach-Object { "$_".Trim() } | Where-Object { $_ })
}

function Get-BotstrapGitAliasIdFromLabel {
    param([Parameter(Mandatory)][string]$Label)
    if ($Label -match ' → ') {
        return $Label.Split(' → ', 2)[0].Trim()
    }
    return $Label.Trim()
}

function Get-BotstrapGitAliasesManagedCsv {
    $envFile = Get-BotstrapGitAliasesEnvPath
    if (-not (Test-Path -LiteralPath $envFile)) { return '' }
    $line = @(Get-Content -LiteralPath $envFile -ErrorAction SilentlyContinue | Where-Object { $_ -match '^\s*managed=' } | Select-Object -First 1)
    if ($line.Count -eq 0) { return '' }
    return ($line[0] -replace '^\s*managed=', '').Trim()
}

function Test-BotstrapGitAliasesCsvContains {
    param(
        [string]$Csv,
        [Parameter(Mandatory)][string]$Needle
    )
    if ([string]::IsNullOrWhiteSpace($Csv)) { return $false }
    foreach ($part in ($Csv -split ',')) {
        if ($part.Trim() -eq $Needle) { return $true }
    }
    return $false
}

function Add-BotstrapGitAliasesInclude {
    $gitconfig = Get-BotstrapGitAliasesUserGitconfig
    $fragment = Get-BotstrapGitAliasesFragmentPath
    $marker = '# botstrap git-aliases'
    if (Test-Path -LiteralPath $gitconfig) {
        $raw = Get-Content -LiteralPath $gitconfig -Raw -ErrorAction SilentlyContinue
        if ($raw -and $raw.Contains($marker)) { return }
    }
    $block = @"

$marker
[include]
	path = $fragment
"@
    Add-Content -LiteralPath $gitconfig -Value $block -Encoding utf8
    Write-BotstrapInfo "Added git alias include to $gitconfig"
}

function Remove-BotstrapGitAliasesInclude {
    param([Parameter(Mandatory)][string]$GitconfigPath)
    if (-not (Test-Path -LiteralPath $GitconfigPath)) { return }
    $lines = @(Get-Content -LiteralPath $GitconfigPath -ErrorAction SilentlyContinue)
    if ($lines.Count -eq 0) { return }
    $out = New-Object System.Collections.Generic.List[string]
    $skip = $false
    foreach ($line in $lines) {
        if ($line -eq '# botstrap git-aliases') {
            $skip = $true
            continue
        }
        if ($skip) {
            if ($line -match '^\[include\]') { continue }
            if ($line -match '^\s*path\s*=') {
                $skip = $false
                continue
            }
            if ([string]::IsNullOrWhiteSpace($line)) {
                $skip = $false
                continue
            }
            $skip = $false
        }
        [void]$out.Add($line)
    }
    $newText = ($out -join "`n").TrimEnd()
    $oldText = ($lines -join "`n").TrimEnd()
    if ($newText -ne $oldText) {
        Set-Content -LiteralPath $GitconfigPath -Value $newText -Encoding utf8
        Write-BotstrapInfo "Removed git alias include from $GitconfigPath"
    }
}

function Install-BotstrapGitAliases {
    $selection = $env:BOTSTRAP_GIT_ALIASES
    $yaml = Get-BotstrapGitAliasesYaml
    $fragment = Get-BotstrapGitAliasesFragmentPath
    $envFile = Get-BotstrapGitAliasesEnvPath
    $configDir = Get-BotstrapGitAliasesConfigDir
    $managedCsv = Get-BotstrapGitAliasesManagedCsv
    $gitconfig = Get-BotstrapGitAliasesUserGitconfig

    New-Item -ItemType Directory -Force -Path $configDir | Out-Null

    if ($selection -eq 'none') {
        Remove-Item -LiteralPath $fragment -Force -ErrorAction SilentlyContinue
        Remove-BotstrapGitAliasesInclude -GitconfigPath $gitconfig
        @(
            '# Generated by Botstrap phase 3; git alias selection for reconfigure.',
            'selected=none',
            'managed='
        ) | Set-Content -LiteralPath $envFile -Encoding utf8
        Write-BotstrapInfo 'Git aliases skipped (BOTSTRAP_GIT_ALIASES=none).'
        return
    }

    if ([string]::IsNullOrWhiteSpace($selection)) {
        $selection = Get-BotstrapGitAliasesDefaultCsv
    }

    if ([string]::IsNullOrWhiteSpace($selection)) {
        Remove-Item -LiteralPath $fragment -Force -ErrorAction SilentlyContinue
        Remove-BotstrapGitAliasesInclude -GitconfigPath $gitconfig
        @(
            '# Generated by Botstrap phase 3; git alias selection for reconfigure.',
            'selected=',
            'managed='
        ) | Set-Content -LiteralPath $envFile -Encoding utf8
        return
    }

    if (-not (Test-Path -LiteralPath $yaml)) {
        Write-BotstrapWarn "Git alias catalog missing: $yaml"
        return
    }

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-BotstrapWarn 'git not on PATH; skipping git alias setup.'
        return
    }

    $applied = New-Object System.Collections.Generic.List[string]
    $iniLines = New-Object System.Collections.Generic.List[string]
    [void]$iniLines.Add('[alias]')

    foreach ($id in ($selection -split ',')) {
        $id = $id.Trim()
        if (-not $id) { continue }
        $entry = Get-BotstrapGitAliasEntry -Id $id
        if (-not $entry) {
            Write-BotstrapWarn "Unknown git alias id: $id"
            continue
        }
        $prevEa = $ErrorActionPreference
        $ErrorActionPreference = 'SilentlyContinue'
        $existing = & git config --global --get "alias.$($entry.Name)" 2>$null
        $ErrorActionPreference = $prevEa
        if ($existing -and -not (Test-BotstrapGitAliasesCsvContains -Csv $managedCsv -Needle $entry.Name)) {
            Write-BotstrapWarn "Skipping git alias $($entry.Name): already set globally (not managed by Botstrap)."
            continue
        }
        [void]$iniLines.Add("`t$($entry.Name) = $($entry.Command)")
        [void]$applied.Add($entry.Name)
    }

    if ($applied.Count -eq 0) {
        Remove-Item -LiteralPath $fragment -Force -ErrorAction SilentlyContinue
        Remove-BotstrapGitAliasesInclude -GitconfigPath $gitconfig
        @(
            '# Generated by Botstrap phase 3; git alias selection for reconfigure.',
            "selected=$selection",
            'managed='
        ) | Set-Content -LiteralPath $envFile -Encoding utf8
        Write-BotstrapInfo 'No git aliases applied (conflicts or empty selection).'
        return
    }

    $iniLines | Set-Content -LiteralPath $fragment -Encoding utf8
    Add-BotstrapGitAliasesInclude

    $managedOut = ($applied -join ',')
    @(
        '# Generated by Botstrap phase 3; git alias selection for reconfigure.',
        "selected=$selection",
        "managed=$managedOut"
    ) | Set-Content -LiteralPath $envFile -Encoding utf8

    Write-BotstrapInfo "Applied $($applied.Count) git alias(es) to $fragment"
}

function Uninstall-BotstrapGitAliases {
    param([switch]$Purge)
    $fragment = Get-BotstrapGitAliasesFragmentPath
    $envFile = Get-BotstrapGitAliasesEnvPath
    $gitconfig = Get-BotstrapGitAliasesUserGitconfig

    Remove-BotstrapGitAliasesInclude -GitconfigPath $gitconfig
    if (Test-Path -LiteralPath $fragment) {
        Remove-Item -LiteralPath $fragment -Force
        Write-BotstrapInfo "Removed $fragment"
    }
    if ($Purge -and (Test-Path -LiteralPath $envFile)) {
        Remove-Item -LiteralPath $envFile -Force
        Write-BotstrapInfo "Removed $envFile"
    }
}
