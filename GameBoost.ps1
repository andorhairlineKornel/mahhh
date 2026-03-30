[CmdletBinding()]
param(
    [switch]$Revert,
    [switch]$EnableHags
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Please run this script as Administrator.'
    }
}

function Set-RegistryValueSafe {
    param(
        [Parameter(Mandatory = $true)] [string]$Path,
        [Parameter(Mandatory = $true)] [string]$Name,
        [Parameter(Mandatory = $true)] [Object]$Value,
        [Parameter(Mandatory = $true)] [Microsoft.Win32.RegistryValueKind]$Type,
        [Parameter(Mandatory = $true)] [ref]$Backup
    )

    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }

    $existing = $null
    try {
        $existing = Get-ItemPropertyValue -Path $Path -Name $Name -ErrorAction Stop
    } catch {
        $existing = $null
    }

    $Backup.Value += [PSCustomObject]@{
        Path     = $Path
        Name     = $Name
        HadValue = $null -ne $existing
        Value    = $existing
        Type     = $Type.ToString()
    }

    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}


function Get-RegistryValueSafe {
    param(
        [Parameter(Mandatory = $true)] [string]$Path,
        [Parameter(Mandatory = $true)] [string]$Name
    )

    try {
        return Get-ItemPropertyValue -Path $Path -Name $Name -ErrorAction Stop
    }
    catch {
        return '<not set>'
    }
}

function Show-ValidationSummary {
    Write-Host '' -NoNewline
    Write-Host 'Validation summary:' -ForegroundColor Cyan

    $activePlan = (powercfg /GETACTIVESCHEME 2>&1 | Out-String).Trim()
    Write-Host "- Active power plan: $activePlan"
    Write-Host "- AllowAutoGameMode: $(Get-RegistryValueSafe -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'AllowAutoGameMode')"
    Write-Host "- AutoGameModeEnabled: $(Get-RegistryValueSafe -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'AutoGameModeEnabled')"
    Write-Host "- VisualFXSetting: $(Get-RegistryValueSafe -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name 'VisualFXSetting')"
    Write-Host "- GameDVR_Enabled: $(Get-RegistryValueSafe -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_Enabled')"
    Write-Host "- AppCaptureEnabled: $(Get-RegistryValueSafe -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' -Name 'AppCaptureEnabled')"
}

function Save-Backup {
    param(
        [Parameter(Mandatory = $true)] [array]$Backup,
        [Parameter(Mandatory = $true)] [string]$FilePath
    )

    $Backup | ConvertTo-Json -Depth 4 | Set-Content -Path $FilePath -Encoding UTF8
}

function Restore-Backup {
    param(
        [Parameter(Mandatory = $true)] [string]$FilePath
    )

    if (-not (Test-Path $FilePath)) {
        throw "Backup file not found at $FilePath"
    }

    $entries = Get-Content -Path $FilePath -Raw | ConvertFrom-Json

    foreach ($entry in $entries) {
        if ($entry.HadValue) {
            if (-not (Test-Path $entry.Path)) {
                New-Item -Path $entry.Path -Force | Out-Null
            }
            New-ItemProperty -Path $entry.Path -Name $entry.Name -Value $entry.Value -PropertyType $entry.Type -Force | Out-Null
        }
        else {
            if (Test-Path $entry.Path) {
                Remove-ItemProperty -Path $entry.Path -Name $entry.Name -ErrorAction SilentlyContinue
            }
        }
    }

    Write-Host 'Registry settings restored from backup.' -ForegroundColor Green
}

function Set-PowerPlanForGaming {
    $highPerfGuid = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
    $ultimateGuid = 'e9a42b02-d5df-448d-aa00-03f14749eb61'

    $listOutput = powercfg /L 2>&1

    if ($listOutput -match $ultimateGuid) {
        powercfg /S $ultimateGuid | Out-Null
        return 'Ultimate Performance'
    }

    if ($listOutput -match $highPerfGuid) {
        powercfg /S $highPerfGuid | Out-Null
        return 'High Performance'
    }

    powercfg /duplicatescheme $highPerfGuid | Out-Null
    powercfg /S $highPerfGuid | Out-Null
    return 'High Performance (created)'
}

function Apply-Tweaks {
    param(
        [switch]$EnableHags
    )

    Assert-Administrator

    $backupFile = Join-Path -Path $PSScriptRoot -ChildPath 'gameboost-backup.json'
    $backup = @()

    $selectedPlan = Set-PowerPlanForGaming

    # Game Mode
    Set-RegistryValueSafe -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'AllowAutoGameMode' -Value 1 -Type DWord -Backup ([ref]$backup)
    Set-RegistryValueSafe -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'AutoGameModeEnabled' -Value 1 -Type DWord -Backup ([ref]$backup)

    # Prioritize active foreground apps (helps games)
    Set-RegistryValueSafe -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' -Name 'Win32PrioritySeparation' -Value 38 -Type DWord -Backup ([ref]$backup)

    # Reduce UI effects for lower overhead
    Set-RegistryValueSafe -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name 'VisualFXSetting' -Value 2 -Type DWord -Backup ([ref]$backup)

    # Lower telemetry noise from GameDVR recording features
    Set-RegistryValueSafe -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_Enabled' -Value 0 -Type DWord -Backup ([ref]$backup)
    Set-RegistryValueSafe -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' -Name 'AppCaptureEnabled' -Value 0 -Type DWord -Backup ([ref]$backup)

    if ($EnableHags) {
        # Optional: Hardware-accelerated GPU scheduling (can improve latency on many systems)
        Set-RegistryValueSafe -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' -Name 'HwSchMode' -Value 2 -Type DWord -Backup ([ref]$backup)
    }

    Save-Backup -Backup $backup -FilePath $backupFile

    Write-Host "Done. Applied safe gaming tweaks and selected power plan: $selectedPlan" -ForegroundColor Green
    Write-Host "Backup saved to: $backupFile"
    Write-Host 'Restart Windows to ensure all changes are active.' -ForegroundColor Yellow
    Show-ValidationSummary
}

$logFile = Join-Path -Path $PSScriptRoot -ChildPath 'gameboost-last-run.log'
$transcriptStarted = $false

try {
    try {
        Start-Transcript -Path $logFile -Force | Out-Null
        $transcriptStarted = $true
    }
    catch {
        Write-Warning "Could not start transcript log at $logFile"
    }

    if ($Revert) {
        Assert-Administrator
        Restore-Backup -FilePath (Join-Path -Path $PSScriptRoot -ChildPath 'gameboost-backup.json')
        Write-Host 'You may need to manually switch power plan back if desired (powercfg /L, then powercfg /S <GUID>).' -ForegroundColor Yellow
        Show-ValidationSummary
    }
    else {
        Apply-Tweaks -EnableHags:$EnableHags
    }
}
catch {
    Write-Error $_
    exit 1
}
finally {
    if ($transcriptStarted) {
        Stop-Transcript | Out-Null
        Write-Host "Run log saved to: $logFile" -ForegroundColor DarkCyan
    }
}
