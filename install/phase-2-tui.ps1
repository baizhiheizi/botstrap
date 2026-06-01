#requires -Version 5.1
$ErrorActionPreference = 'Stop'
. (Join-Path $env:BOTSTRAP_ROOT 'lib\log.ps1')

if (-not (Get-Command gum -ErrorAction SilentlyContinue)) {
    Write-BotstrapWarn 'gum not found; using non-interactive defaults.'
    $env:BOTSTRAP_GIT_NAME = $env:BOTSTRAP_GIT_NAME
    $env:BOTSTRAP_GIT_EMAIL = $env:BOTSTRAP_GIT_EMAIL
    if (-not $env:BOTSTRAP_CORE_TOOLS) {
        $coreYaml = Join-Path $env:BOTSTRAP_ROOT 'registry\core.yaml'
        $rawNames = & yq -r '.tools[].name' $coreYaml 2>$null
        $parts = @($rawNames -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        $env:BOTSTRAP_CORE_TOOLS = $parts -join ','
    }
    $optSelFile = Join-Path $env:USERPROFILE '.config\botstrap\optional-selections.env'
    $editorEnvFile = Join-Path $env:USERPROFILE '.config\botstrap\editor.env'
    $themeEnvFile = Join-Path $env:USERPROFILE '.config\botstrap\theme.env'
    if (-not $env:BOTSTRAP_EDITOR -and (Test-Path -LiteralPath $editorEnvFile)) {
        $em = @(Get-Content -LiteralPath $editorEnvFile -ErrorAction SilentlyContinue | Where-Object { $_ -match '^\s*editor=' } | Select-Object -First 1)
        if ($em.Count -gt 0) { $env:BOTSTRAP_EDITOR = ($em[0] -replace '^\s*editor=', '').Trim() }
    }
    if (-not $env:BOTSTRAP_EDITOR) { $env:BOTSTRAP_EDITOR = 'none' }
    if (-not $env:BOTSTRAP_LANGUAGES -and (Test-Path -LiteralPath $optSelFile)) {
        $lm = @(Get-Content -LiteralPath $optSelFile -ErrorAction SilentlyContinue | Where-Object { $_ -match '^\s*languages=' } | Select-Object -First 1)
        if ($lm.Count -gt 0) { $env:BOTSTRAP_LANGUAGES = ($lm[0] -replace '^\s*languages=', '').Trim() }
    }
    if (-not $env:BOTSTRAP_LANGUAGES) { $env:BOTSTRAP_LANGUAGES = '' }
    if (-not $env:BOTSTRAP_DATABASES -and (Test-Path -LiteralPath $optSelFile)) {
        $dm = @(Get-Content -LiteralPath $optSelFile -ErrorAction SilentlyContinue | Where-Object { $_ -match '^\s*databases=' } | Select-Object -First 1)
        if ($dm.Count -gt 0) { $env:BOTSTRAP_DATABASES = ($dm[0] -replace '^\s*databases=', '').Trim() }
    }
    if (-not $env:BOTSTRAP_DATABASES) { $env:BOTSTRAP_DATABASES = '' }
    if (-not $env:BOTSTRAP_AI_TOOLS -and (Test-Path -LiteralPath $optSelFile)) {
        $am = @(Get-Content -LiteralPath $optSelFile -ErrorAction SilentlyContinue | Where-Object { $_ -match '^\s*ai_tools=' } | Select-Object -First 1)
        if ($am.Count -gt 0) { $env:BOTSTRAP_AI_TOOLS = ($am[0] -replace '^\s*ai_tools=', '').Trim() }
    }
    if (-not $env:BOTSTRAP_AI_TOOLS) { $env:BOTSTRAP_AI_TOOLS = '' }
    if (-not $env:BOTSTRAP_THEME -and (Test-Path -LiteralPath $themeEnvFile)) {
        $tm = @(Get-Content -LiteralPath $themeEnvFile -ErrorAction SilentlyContinue | Where-Object { $_ -match '^\s*theme=' } | Select-Object -First 1)
        if ($tm.Count -gt 0) { $env:BOTSTRAP_THEME = ($tm[0] -replace '^\s*theme=', '').Trim() }
    }
    if (-not $env:BOTSTRAP_THEME) { $env:BOTSTRAP_THEME = 'catppuccin' }
    if (-not $env:BOTSTRAP_OPTIONAL_APPS -and (Test-Path -LiteralPath $optSelFile)) {
        $om = @(Get-Content -LiteralPath $optSelFile -ErrorAction SilentlyContinue | Where-Object { $_ -match '^\s*optional_apps=' } | Select-Object -First 1)
        if ($om.Count -gt 0) { $env:BOTSTRAP_OPTIONAL_APPS = ($om[0] -replace '^\s*optional_apps=', '').Trim() }
    }
    if (-not $env:BOTSTRAP_OPTIONAL_APPS) { $env:BOTSTRAP_OPTIONAL_APPS = '' }
    . (Join-Path $env:BOTSTRAP_ROOT 'lib\git-aliases.ps1')
    if (-not $env:BOTSTRAP_GIT_ALIASES) {
        $gitAliasesEnv = Get-BotstrapGitAliasesEnvPath
        if (Test-Path -LiteralPath $gitAliasesEnv) {
            $gaMatch = @(Get-Content -LiteralPath $gitAliasesEnv -ErrorAction SilentlyContinue | Where-Object { $_ -match '^\s*selected=' } | Select-Object -First 1)
            if ($gaMatch.Count -gt 0) {
                $env:BOTSTRAP_GIT_ALIASES = ($gaMatch[0] -replace '^\s*selected=', '').Trim()
            }
            else {
                $env:BOTSTRAP_GIT_ALIASES = Get-BotstrapGitAliasesDefaultCsv
            }
        }
        else {
            $env:BOTSTRAP_GIT_ALIASES = Get-BotstrapGitAliasesDefaultCsv
        }
    }
    return
}

$ErrorActionPreference = 'Continue'
& gum style --border rounded --padding '1 2' --foreground 212 'Botstrap' '' 'Cross-platform developer bootstrap.'

$ErrorActionPreference = 'Stop'
$gitNameDefault = $env:GIT_AUTHOR_NAME
if (-not $gitNameDefault) { $gitNameDefault = '' }
$gitEmailDefault = $env:GIT_AUTHOR_EMAIL
if (-not $gitEmailDefault) { $gitEmailDefault = '' }

$gitNamePlaceholder = 'Git user name'
if (-not $env:GIT_AUTHOR_NAME) {
    $prevEa = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    $gn = & git config --global --get user.name 2>$null
    $ErrorActionPreference = $prevEa
    if ($gn) { $gitNamePlaceholder = "$gn" }
}
$gitEmailPlaceholder = 'Git email'
if (-not $env:GIT_AUTHOR_EMAIL) {
    $prevEa = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    $ge = & git config --global --get user.email 2>$null
    $ErrorActionPreference = $prevEa
    if ($ge) { $gitEmailPlaceholder = "$ge" }
}

if (-not $env:BOTSTRAP_GIT_NAME) {
    $nameArgs = if ($gitNameDefault) { @('--value', $gitNameDefault) } else { @() }
    $env:BOTSTRAP_GIT_NAME = & gum input --placeholder $gitNamePlaceholder @nameArgs
}
if (-not $env:BOTSTRAP_GIT_EMAIL) {
    $emailArgs = if ($gitEmailDefault) { @('--value', $gitEmailDefault) } else { @() }
    $env:BOTSTRAP_GIT_EMAIL = & gum input --placeholder $gitEmailPlaceholder @emailArgs
}

. (Join-Path $env:BOTSTRAP_ROOT 'lib\git-aliases.ps1')
if (-not $env:BOTSTRAP_GIT_ALIASES) {
    $gitAliasLabels = @(Get-BotstrapGitAliasesChooseLabels)
    if ($gitAliasLabels.Count -gt 0) {
        $previewLines = @(Get-BotstrapGitAliasesPreviewLines)
        $previewText = ($previewLines -join "`n")
        $ErrorActionPreference = 'Continue'
        & gum style --border normal --padding '0 1' --foreground 212 `
            'Git shortcuts' '' `
            'Run git st, git co, and similar aliases from configs/git/aliases.yaml.' '' `
            $previewText
        $ErrorActionPreference = 'Stop'
        $installAliases = $false
        $ErrorActionPreference = 'Continue'
        if (& gum confirm 'Install git shortcuts? (git st, git co, …)') {
            $installAliases = $true
        }
        $ErrorActionPreference = 'Stop'
        if ($installAliases) {
            $gitAliasEnvFile = Get-BotstrapGitAliasesEnvPath
            $gitAliasGumArgs = @('choose', '--no-limit', '--ordered', '--header', 'Git shortcuts (git <name>)')
            $seedCsv = ''
            if (Test-Path -LiteralPath $gitAliasEnvFile) {
                $gaSeed = @(Get-Content -LiteralPath $gitAliasEnvFile -ErrorAction SilentlyContinue | Where-Object { $_ -match '^\s*selected=' } | Select-Object -First 1)
                if ($gaSeed.Count -gt 0) {
                    $seedCsv = ($gaSeed[0] -replace '^\s*selected=', '').Trim()
                }
            }
            if ($seedCsv -eq 'none') {
                # no pre-selection
            }
            elseif ($seedCsv) {
                foreach ($rawId in $seedCsv.Split(',')) {
                    $id = $rawId.Trim()
                    if (-not $id) { continue }
                    foreach ($label in $gitAliasLabels) {
                        if ($label.StartsWith("$id → ")) {
                            $gitAliasGumArgs += @('--selected', $label)
                        }
                    }
                }
            }
            else {
                $gitAliasGumArgs += @('--selected', '*')
            }
            $gitAliasGumArgs += $gitAliasLabels
            $ErrorActionPreference = 'Continue'
            $aliasLines = @( & gum @gitAliasGumArgs )
            $ErrorActionPreference = 'Stop'
            $aliasIds = @($aliasLines | ForEach-Object { Get-BotstrapGitAliasIdFromLabel -Label "$_".Trim() } | Where-Object { $_ })
            if ($aliasIds.Count -gt 0) {
                $env:BOTSTRAP_GIT_ALIASES = ($aliasIds -join ',')
            }
            else {
                $env:BOTSTRAP_GIT_ALIASES = 'none'
            }
        }
        else {
            $env:BOTSTRAP_GIT_ALIASES = 'none'
        }
    }
    else {
        $env:BOTSTRAP_GIT_ALIASES = 'none'
    }
}

$ErrorActionPreference = 'Stop'
$coreYaml = Join-Path $env:BOTSTRAP_ROOT 'registry\core.yaml'
$coreNames = @(& yq -r '.tools[].name' $coreYaml 2>$null | ForEach-Object { "$_".Trim() } | Where-Object { $_ })
$selectedFlag = '*'
$coreEnvFile = Join-Path $env:USERPROFILE '.config\botstrap\core-tools.env'
if (Test-Path -LiteralPath $coreEnvFile) {
    $match = @(Get-Content -LiteralPath $coreEnvFile -ErrorAction SilentlyContinue | Where-Object { $_ -match '^\s*core_tools=' } | Select-Object -First 1)
    if ($match.Count -gt 0) {
        $v = ($match[0] -replace '^\s*core_tools=', '').Trim()
        if ($v) { $selectedFlag = $v }
    }
}
$ErrorActionPreference = 'Continue'
$coreChooseArgs = @(
    'choose', '--no-limit', '--ordered',
    '--header', 'Core tools (registry/core.yaml)',
    '--selected', $selectedFlag
) + $coreNames
$coreLines = @( & gum @coreChooseArgs )
$env:BOTSTRAP_CORE_TOOLS = ($coreLines | ForEach-Object { "$_".Trim() } | Where-Object { $_ }) -join ','

$optSelFile = Join-Path $env:USERPROFILE '.config\botstrap\optional-selections.env'
$editorEnvFile = Join-Path $env:USERPROFILE '.config\botstrap\editor.env'
$themeEnvFile = Join-Path $env:USERPROFILE '.config\botstrap\theme.env'

$ErrorActionPreference = 'Continue'
$editorGumArgs = @()
if (Test-Path -LiteralPath $editorEnvFile) {
    $em = @(Get-Content -LiteralPath $editorEnvFile -ErrorAction SilentlyContinue | Where-Object { $_ -match '^\s*editor=' } | Select-Object -First 1)
    if ($em.Count -gt 0) {
        $ev = ($em[0] -replace '^\s*editor=', '').Trim()
        if ($ev) { $editorGumArgs = @('--selected', $ev) }
    }
}
$editorChoice = & gum choose --header 'Primary editor' @editorGumArgs cursor vscode neovim zed none
$env:BOTSTRAP_EDITOR = "$editorChoice".Trim()

$langGumArgs = @()
if (Test-Path -LiteralPath $optSelFile) {
    $lm = @(Get-Content -LiteralPath $optSelFile -ErrorAction SilentlyContinue | Where-Object { $_ -match '^\s*languages=' } | Select-Object -First 1)
    if ($lm.Count -gt 0) {
        $lcsv = ($lm[0] -replace '^\s*languages=', '').Trim()
        if ($lcsv) {
            foreach ($raw in $lcsv.Split(',')) {
                $x = $raw.Trim()
                if ($x) { $langGumArgs += @('--selected', $x) }
            }
        }
    }
}
$langLines = @( & gum choose --no-limit --header 'Programming languages (mise)' @langGumArgs node python ruby go rust java elixir php none )
if ($langLines.Count -gt 0) {
    $env:BOTSTRAP_LANGUAGES = ($langLines | ForEach-Object { "$_".Trim() } | Where-Object { $_ -ne '' }) -join ','
}
else {
    $env:BOTSTRAP_LANGUAGES = ''
}

$dbGumArgs = @()
if (Test-Path -LiteralPath $optSelFile) {
    $dm = @(Get-Content -LiteralPath $optSelFile -ErrorAction SilentlyContinue | Where-Object { $_ -match '^\s*databases=' } | Select-Object -First 1)
    if ($dm.Count -gt 0) {
        $dcsv = ($dm[0] -replace '^\s*databases=', '').Trim()
        if ($dcsv) {
            foreach ($raw in $dcsv.Split(',')) {
                $x = $raw.Trim()
                if ($x) { $dbGumArgs += @('--selected', $x) }
            }
        }
    }
}
$dbLines = @( & gum choose --no-limit --header 'Databases (Docker)' @dbGumArgs postgresql mysql redis sqlite none )
if ($dbLines.Count -gt 0) {
    $env:BOTSTRAP_DATABASES = ($dbLines | ForEach-Object { "$_".Trim() } | Where-Object { $_ -ne '' }) -join ','
}
else {
    $env:BOTSTRAP_DATABASES = ''
}

$aiGumArgs = @()
if (Test-Path -LiteralPath $optSelFile) {
    $am = @(Get-Content -LiteralPath $optSelFile -ErrorAction SilentlyContinue | Where-Object { $_ -match '^\s*ai_tools=' } | Select-Object -First 1)
    if ($am.Count -gt 0) {
        $acsv = ($am[0] -replace '^\s*ai_tools=', '').Trim()
        if ($acsv) {
            foreach ($raw in $acsv.Split(',')) {
                $x = $raw.Trim()
                if ($x) { $aiGumArgs += @('--selected', $x) }
            }
        }
    }
}
$aiLines = @( & gum choose --no-limit --header 'AI agent CLIs' @aiGumArgs claude-code openclaw codex gemini ollama none )
if ($aiLines.Count -gt 0) {
    $env:BOTSTRAP_AI_TOOLS = ($aiLines | ForEach-Object { "$_".Trim() } | Where-Object { $_ -ne '' }) -join ','
}
else {
    $env:BOTSTRAP_AI_TOOLS = ''
}

$ErrorActionPreference = 'Stop'
$themeGumArgs = @()
if (Test-Path -LiteralPath $themeEnvFile) {
    $tm = @(Get-Content -LiteralPath $themeEnvFile -ErrorAction SilentlyContinue | Where-Object { $_ -match '^\s*theme=' } | Select-Object -First 1)
    if ($tm.Count -gt 0) {
        $tv = ($tm[0] -replace '^\s*theme=', '').Trim()
        if ($tv) { $themeGumArgs = @('--selected', $tv) }
    }
}
$themeChoice = & gum choose --header 'Theme' @themeGumArgs catppuccin tokyo-night gruvbox nord rose-pine
$env:BOTSTRAP_THEME = "$themeChoice".Trim()

$ErrorActionPreference = 'Continue'
$appGumArgs = @()
if (Test-Path -LiteralPath $optSelFile) {
    $om = @(Get-Content -LiteralPath $optSelFile -ErrorAction SilentlyContinue | Where-Object { $_ -match '^\s*optional_apps=' } | Select-Object -First 1)
    if ($om.Count -gt 0) {
        $ocsv = ($om[0] -replace '^\s*optional_apps=', '').Trim()
        if ($ocsv) {
            foreach ($raw in $ocsv.Split(',')) {
                $x = $raw.Trim()
                if ($x) { $appGumArgs += @('--selected', $x) }
            }
        }
    }
}
$appLines = @( & gum choose --no-limit --header 'Optional apps' @appGumArgs 1password-cli tailscale ngrok postman none )
if ($appLines.Count -gt 0) {
    $env:BOTSTRAP_OPTIONAL_APPS = ($appLines | ForEach-Object { "$_".Trim() } | Where-Object { $_ -ne '' }) -join ','
}
else {
    $env:BOTSTRAP_OPTIONAL_APPS = ''
}

$ErrorActionPreference = 'Stop'
& gum confirm 'Apply these choices and continue?'
# gum confirm uses exit code only (no stdout); $? reflects native exit status (works on Windows PowerShell 5.1+).
if (-not $?) {
    Write-BotstrapWarn 'Aborted at confirmation; exiting.'
    exit 1
}

Write-BotstrapInfo 'Phase 2 (Windows) complete.'
