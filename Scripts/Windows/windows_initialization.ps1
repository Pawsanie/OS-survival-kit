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

<#
.SYNOPSIS
Disables telemetry dependent on registry policies.
#>
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

<#
.SYNOPSIS
Stops telemetry services.
#>
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

<#
.SYNOPSIS
Clears a significant portion of telemetry from the task list.
#>
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

<#
.SYNOPSIS
Disables Reclame and News widgets.
#>
function Set-Advertising-And-CloudContent-Registry-Policies {

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

<#
.SYNOPSIS
Turns off cloud dynamic wallpapers.
#>
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


<#
.SYNOPSIS
Removes the feed from the Start Menu search.
#>
function Set-Windows-Search-Highlights-Registry-Policies {

    foreach (
        $key in @(
            "EnableAllowedToQueryHighlights",
            "ConnectedSearchUseWeb"
        )
    ) {

        Set-ItemProperty `
            -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" `
            -Name $key `
            -Type DWord `
            -Value 0 `
            -Force `
            | Out-Null

    }

    Set-ItemProperty `
        -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" `
        -Name "DisableWebSearch" `
        -Value 1 `
        -Type DWord `
        -Force `
        | Out-Null

    Set-ItemProperty `
        -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" `
        -Name "BingSearchEnabled" `
        -Value 0 `
        -Type DWord `
        -Force `
        | Out-Null

}

<#
.SYNOPSIS
Removes unnecessary and reclame pre-installed applications.
#>
function Remove-Pre-installed-Apps {

    foreach (
        $app in @(
            # X-box:
            "Microsoft.XboxApp",
            "Microsoft.Xbox.TCUI",
            "Microsoft.XboxGameOverlay",
            "Microsoft.XboxGamingOverlay",
            "Microsoft.XboxIdentityProvider",
            "Microsoft.XboxSpeechToTextOverlay",
            "Microsoft.GamingApp",  # New X-box app.

            # Microsoft applications that are not OS part:
            "Microsoft.YourPhone",  # Reading SMS, push notifications and receiving calls from your smartphone.
            "Microsoft.GetHelp",
            "Microsoft.Getstarted",
            "Microsoft.ZuneMusic",  # Groove Music (Legacy)
            "Microsoft.ZuneVideo",  # Movies & TV
            "Microsoft.BingNews",
            "Microsoft.BingWeather",
            "Microsoft.BingFinance",
            "Microsoft.BingSports",
            "Microsoft.People", # Contacts (Legacy)
            "Microsoft.SkypeApp",   # Skype (Legacy)
            "Microsoft.Todos",  # To Do list
            "Microsoft.OneConnect", # Mobile Plans
            "Microsoft.MixedReality.Portal",    # Mixed Reality
            "Microsoft.Whiteboard",  # Whiteboard

            # Advertising:
            "Microsoft.MicrosoftOfficeHub", # Office Hub (MS Office Advertising)
            "Microsoft.MicrosoftSolitaireCollection",   # Solitaire with Advertising
            "Clipchamp.Clipchamp",  # Clipchamp (video editor, Advertising)
            "Microsoft.Advertising.Xaml",   # Advertising SDK

            # Virtual hard links to third-party services:
            "SpotifyAB.SpotifyMusic",
            "Disney.37853FC22B2CE", # Disney+
            "Facebook.Facebook",
            "Instagram.Instagram",
            "TikTok.TikTok"
        )
    ) {

        Get-AppxPackage `
            -Name $app `
            -AllUsers `
            | Remove-AppxPackage `
                -AllUsers `
                -ErrorAction SilentlyContinue

        Get-AppxProvisionedPackage `
            -Online `
            | Where-Object DisplayName `
                -like "$app*" `
                | Remove-AppxProvisionedPackage `
                -Online `
                -ErrorAction SilentlyContinue

    }

}

<#
.SYNOPSIS
Prevents the remote Xbox piece from being called every time the game is opened.
#>
function Disable-Gaming-Overlay {

    New-Item `
        -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" `
        -Force `
        | Out-Null

    New-ItemProperty `
        -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" `
        -Name "AllowGameDVR" `
        -Type DWord `
        -Value 0 `
        -Force `
        | Out-Null

}

<#
.SYNOPSIS
Runs Windows initialization pipeline.
#>
function Main {

    Write-Host `
        "Post-installation Windows initialization script has been launched."`
        -ForegroundColor White

    # Telemetry:
    Set-Telemetry-Registry-Policies
    Stop-Telemetry-Services
    Clear-telemetry-Tasks

    # Advertising and CloudContent:
    Set-Advertising-And-CloudContent-Registry-Policies

    # Wallpapers:
    Set-Wallpaper-Spotlight-Registry-Policies

    # Search News and Highlights:
    Set-Windows-Search-Highlights-Registry-Policies

    # Apps:
    Remove-Pre-installed-Apps
    Disable-Gaming-Overlay

    # Apply changes that do not require a system restart:
    Stop-Process `
        -Name explorer `
        -Force
    Start-Process explorer

    Write-Host `
        "Post-installation Windows initialization scenario completed." `
        -ForegroundColor Blue

}

# Entry point:
Main
