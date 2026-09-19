#!/usr/bin/env pwsh
#requires -Version 5.1
# Shutdown Windows Update CPU/GPU driver destroyer.

<#
Unix Root user equivalent for scripts:
Opens a new PowerShell window with elevated privileges
and executes the entire subsequent script in it.
#>
if (
    -not (
        [Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
) {

    Start-Process powershell `
        -Verb RunAs `
        -ArgumentList @(
            '-NoProfile',
            '-ExecutionPolicy',
            'Bypass',
            '-NoExit',
            '-File',
            $PSCommandPath
    )

    exit

}

# Path settings:
$policyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions"

<#
.SYNOPSIS
Creates a tree for the install devices restrictions Registry policy if it does not already exist.
#>
function New-Registry-Policy {

    Write-Host `
        "Creating a restrictions Registry policy tree for installed devices." `
        -ForegroundColor White

    New-Item `
        -Path $policyPath `
        -Force `
        | Out-Null

}

<#
.SYNOPSIS
Gets device objects for the subsequent scraping of information stored within them.

.OUTPUTS
Microsoft.Management.Infrastructure.CimInstance Processor or Display objects array.
#>
function Get-Devices {

    $devices = Get-PnpDevice `
        -PresentOnly `
        | Where-Object {

            $_.Class -eq "Processor" `
            -or `
            $_.Class -eq "Display"

    }

    if (-not $devices) {

        Write-Host `
            "Get-PnpDevice failed to gather CPU and GPU information!`n" `
            "Program execution has been suspended..." `
            -ForegroundColor Red

        exit 1

    }
    else {

        return $devices

    }

}

<#
.SYNOPSIS
Gets an array of Hardware IDs from CPU and GPU objects.

.PARAMETER Devices
Microsoft.Management.Infrastructure.CimInstance Processor or Display objects array.

.OUTPUTS
System.String[]
Hardware IDs array.
#>
function Get-Hardware-IDs {
    param (
        [object[]]$Devices
    )

    $hardwareIds = @()

    foreach ($device in $Devices) {

        Write-Host `
            "Type: $($device.Class)`n" `
            "Name: $($device.FriendlyName)`n" `
            "Class: $($device.Class)`n" `
            "Instance ID: $($device.InstanceId)" `
            -ForegroundColor White

        try {

            foreach (
                $id in $(
                    Get-PnpDeviceProperty `
                        -InstanceId $device.InstanceId `
                        -KeyName "DEVPKEY_Device_HardwareIds" `
                        -ErrorAction Stop `
                        | Select-Object `
                            -ExpandProperty Data
                    )
            ) {

                if ($id) {

                    $hardwareIds += $id

                    Write-Host `
                        "Hardware ID: $id" `
                        -ForegroundColor White

                }

            }

        }
        catch {

            Write-Warning `
                "Failed to retrieve hardware IDs: $($device.FriendlyName)" `
                -ForegroundColor White

        }

        Write-Host

    }

    if ($hardwareIds.Count -eq 0) {

        Write-Host `
            "Failed to retrieve any hardware IDs!`n" `
            "Program execution has been suspended..." `
            -ForegroundColor Red

        exit 1

    }
    else {

        return $hardwareIds `
                | Sort-Object `
                    -Unique

    }

}

<#
.SYNOPSIS
Gets the list of existing IDs from the Registry policy if any exist.

.OUTPUTS
System.String[]
Hardware IDs array.
#>
function Get-Existing-Hardware-IDs {

    try {

        return Get-ItemProperty `
                -Path $policyPath `
                -Name "DenyDeviceIDs" `
                -ErrorAction Stop `
                | Select-Object `
                    -ExpandProperty DenyDeviceIDs

    }
    catch {

        return @()

    }

}


<#
.SYNOPSIS
Updates the CPUs and GPUs Restrictions Registry driver updates policy.

.PARAMETER ExistingHardwareIDs
System.String[] hardware IDs array.

.PARAMETER HardwareIDs
System.String[] hardware IDs array.
#>
function Set-Registry-Policy {

    param (
        [System.String[]]$ExistingHardwareIDs,
        [System.String[]]$HardwareIDs
    )

    $allIds = @(
        $ExistingHardwareIDs
        $HardwareIDs
    ) `
        | Where-Object { $_ } `
        | Sort-Object `
            -Unique

    # Store the device IDs array in the restrictions:
    New-ItemProperty `
        -Path $policyPath `
        -Name "DenyDeviceIDs" `
        -PropertyType MultiString `
        -Value $allIds `
        -Force `
        | Out-Null

    # Exclude device drivers from Windows Update packages:
    New-ItemProperty `
        -Path $policyPath `
        -Name "ExcludeWUDriversInQualityUpdate" `
        -PropertyType DWord `
        -Value 1 `
        -Force `
        | Out-Null

    Write-Host `
        "Total Hardware IDs in the policy: $($allIds.Count)" `
        "Blocked by Hardware IDs: $($HardwareIDs.Count)" `
        -ForegroundColor Green

    # Updating Group Policy:

}

<#
.SYNOPSIS
Apply Registry policies.
#>
function Update-Registry-Policy {

    gpupdate.exe `
        /target:computer `
        /force

}


<#
.SYNOPSIS
Runs a pipeline to block CPU and GPU driver updates via Windows Update.
#>
function Main {

    Write-Host `
        "CPU and GPU drivers updates via Windows Update ban script has been launched." `
        -ForegroundColor Blue

    New-Registry-Policy

    Set-Registry-Policy `
        -ExistingHardwareIDs Get-Existing-Hardware-IDs `
        -HardwareIDs Get-Hardware-IDs `
            -Devices Get-Devices

    Update-Registry-Policy

    Write-Host `
        "CPU and GPU drivers updates via Windows Update ban scenario completed." `
        -ForegroundColor Blue

}

# Entry point:
Main
