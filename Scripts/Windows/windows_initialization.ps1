#!/usr/bin/env pwsh
#requires -Version 5.1
# The script cleans a newly installed Windows instance of pre-installed applications and disables telemetry.


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

function Set-Telemetry-Registry-Policies {

    New-Item `
        -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" `
        -Force `
        | Out-Null

    Set-ItemProperty `
        -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" `
        -Name AllowTelemetry `
        -Type DWord `
        -Value 0 `
        -Force `
        | Out-Null

}

function Stop-Telemetry-Services {

    Stop-Service diagtrack `
        -Force `
        -ErrorAction SilentlyContinue
    Set-Service diagtrack `
        -StartupType Disabled

    Stop-Service dmwappushservice `
        -Force `
        -ErrorAction SilentlyContinue
    Set-Service dmwappushservice `
        -StartupType Disabled

}

function Clear-telemetry-Tasks {

    foreach (
        $task in @(
            "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
            "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
            "\Microsoft\Windows\Autochk\Proxy",
            "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
            "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
            "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask",
            "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"
        )
    ) {

        schtasks `
            /Change `
            /TN `
            $task `
            /Disable `
            2>$null `
            | Out-Null

    }

}

function Set-Reclame-Registry-Policies {

    foreach (
        $path in @(
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
        )
    ) {

        New-Item `
        -Path $path `
        -Force `
        | Out-Null

    }

    foreach (
        $key in @(
            "ContentDeliveryAllowed",
            "OemPreInstalledAppsEnabled",
            "PreInstalledAppsEnabled",
            "PreInstalledAppsEverEnabled",
            "SilentInstalledAppsEnabled",
            "SubscribedContent-310093Enabled",
            "SubscribedContent-338389Enabled",
            "SubscribedContent-314563Enabled",
            "SystemPaneSuggestionsEnabled"
        )
    ) {

        Set-ItemProperty `
            -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
            -Name $key `
            -Type DWord `
            -Value 0 `
            -Force `
            | Out-Null

    }

    foreach (
        $key in @(
            "DisableWindowsConsumerFeatures",
            "DisableSoftLanding",
            "DisableWindowsSpotlightFeatures"
        )
    ) {

        Set-ItemProperty `
            -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"`
            -Name $key `
            -Type DWord `
            -Value 1 `
            -Force `
            | Out-Null

    }

}

function Set-Wallpaper-Spotlight-Registry-Policies {

    foreach (
        $key in @(
            "DisableWindowsSpotlightOnLockScreen",
            "DisableSpotlightCollectionOnDesktop"
        )
    ) {

        Set-ItemProperty `
            -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"`
            -Name $key `
            -Type DWord `
            -Value 1 `
            -Force `
            | Out-Null

    }

}

function Set-Windows-Search-Highlights-Registry-Policies {

    New-ItemProperty `
        -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" `
        -Name "EnableAllowedToQueryHighlights" `
        -Value 0 `
        -PropertyType DWord `
        -Force `
        | Out-Null

}

<#
.SYNOPSIS
Runs Windows initialization pipeline.
#>
function Main {

    # Telemetry:
    Set-Telemetry-Registry-Policies
    Stop-Telemetry-Services
    Clear-telemetry-Tasks

    # Reclame:
    Set-Reclame-Registry-Policies

    # Wallpapers:
    Set-Wallpaper-Spotlight-Registry-Policies

    # Search News and Highlights:
    Set-Windows-Search-Highlights-Registry-Policies

}

# Entry point:
Main
