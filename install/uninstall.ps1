#requires -Version 5.1
param(
    [switch]$Yes,
    [switch]$Purge,
    [switch]$RemoveCheckout
)

$ErrorActionPreference = 'Stop'

if (-not $env:BOTSTRAP_ROOT) {
    Write-Host '[botstrap] BOTSTRAP_ROOT must be set' -ForegroundColor Red
    exit 1
}

$Root = $env:BOTSTRAP_ROOT
. (Join-Path $Root 'lib\log.ps1')
. (Join-Path $Root 'lib\profile-windows.ps1')

function Test-BotstrapInteractiveConsole {
    return (-not [Console]::IsInputRedirected -and -not [Console]::IsOutputRedirected)
}

function Remove-BotstrapProfileBlocks {
    param([Parameter(Mandatory)][string]$ProfilePath)

    if (-not (Test-Path -LiteralPath $ProfilePath)) {
        return
    }
    $raw = Get-Content -LiteralPath $ProfilePath -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrEmpty($raw)) {
        return
    }
    $markers = @('botstrap PATH', 'botstrap starship', 'botstrap zoxide', 'botstrap aliases')
    $before = $raw
    foreach ($m in $markers) {
        $markerLine = "# $m"
        $escaped = [regex]::Escape($markerLine)
        $pattern = $escaped + '\r?\n.*?(?=\r?\n# botstrap |\z)'
        $raw = [regex]::Replace(
            $raw,
            $pattern,
            '',
            [System.Text.RegularExpressions.RegexOptions]::Singleline
        )
    }
    if ($raw -ne $before) {
        Set-Content -LiteralPath $ProfilePath -Value $raw -Encoding utf8
        Write-BotstrapInfo "Updated PowerShell profile: $ProfilePath"
    }
}

function Confirm-BotstrapUninstall {
    $msg = @'
Remove Botstrap blocks from your PowerShell profile?
'@
    if ($Purge) {
        $msg += "`nAlso delete the entire $($env:USERPROFILE)\.config\botstrap directory (--purge)."
    }
    if ($RemoveCheckout) {
        $msg += "`nAlso delete the Botstrap checkout (--remove-checkout):`n$Root"
    }
    if ($Yes) {
        return $true
    }
    if ((Test-BotstrapInteractiveConsole) -and (Get-Command gum -ErrorAction SilentlyContinue)) {
        if (-not (& gum confirm $msg)) {
            Write-BotstrapInfo 'Uninstall cancelled.'
            return $false
        }
        return $true
    }
    if (Test-BotstrapInteractiveConsole) {
        Write-Host $msg
        $ans = Read-Host 'Proceed? [y/N]'
        if ($ans -match '^(?i)y(es)?$') {
            return $true
        }
        Write-BotstrapInfo 'Uninstall cancelled.'
        return $false
    }
    Write-BotstrapErr 'Non-interactive session: re-run with -Yes to confirm uninstall.'
    return $false
}

function Test-BotstrapCheckoutRemovalAllowed {
    if ([string]::IsNullOrWhiteSpace($Root)) {
        Write-BotstrapErr 'Refusing to remove checkout: BOTSTRAP_ROOT is empty.'
        return $false
    }
    if (-not [System.IO.Path]::IsPathRooted($Root)) {
        Write-BotstrapErr "Refusing to remove checkout: path must be absolute ($Root)."
        return $false
    }
    $full = [System.IO.Path]::GetFullPath($Root)
    $pathRoot = [System.IO.Path]::GetPathRoot($full)
    if ($pathRoot -and ($full.TrimEnd('\') -eq $pathRoot.TrimEnd('\'))) {
        Write-BotstrapErr 'Refusing to remove checkout: path is a drive root.'
        return $false
    }
    if ($full -eq [System.IO.Path]::GetFullPath($env:USERPROFILE)) {
        Write-BotstrapErr 'Refusing to remove checkout: path is USERPROFILE.'
        return $false
    }
    $gitDir = Join-Path $Root '.git'
    if (-not (Test-Path -LiteralPath $gitDir)) {
        Write-BotstrapErr "Refusing to remove checkout: missing $gitDir (not a git clone?)."
        return $false
    }
    return $true
}

if (-not (Confirm-BotstrapUninstall)) {
    exit 1
}

foreach ($profilePath in (Get-BotstrapWindowsPowerShellProfilePaths)) {
    Remove-BotstrapProfileBlocks -ProfilePath $profilePath
}

. (Join-Path $Root 'lib\git-aliases.ps1')
if ($Purge) {
    Uninstall-BotstrapGitAliases -Purge
}
else {
    Uninstall-BotstrapGitAliases
}

if ($Purge) {
    $cfg = Join-Path $env:USERPROFILE '.config\botstrap'
    if (Test-Path -LiteralPath $cfg) {
        Remove-Item -LiteralPath $cfg -Recurse -Force
        Write-BotstrapInfo "Removed $cfg"
    }
}

if ($RemoveCheckout) {
    if (-not (Test-BotstrapCheckoutRemovalAllowed)) {
        exit 1
    }
    Remove-Item -LiteralPath $Root -Recurse -Force
    Write-BotstrapInfo "Removed checkout $Root"
}

Write-BotstrapInfo 'Botstrap uninstall finished.'
