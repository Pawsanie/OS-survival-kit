#!/usr/bin/env pwsh
#requires -Version 5.1
# Shutdown Windows automatic disk encryption.

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
            '-ExecutionPolicy Bypass',
            '-NoExit',
            '-File',
            $PSCommandPath
    )

    exit

}

<#
.SYNOPSIS
Turns off automatic disk encryption.
#>
function Set-Windows-Automatic-Disk-Encryption-Policies {

    Set-ItemProperty `
        -Path "HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker" `
        -Name "PreventDeviceEncryption" `
        -Type DWord `
        -Value 1

}

<#
.SYNOPSIS
Decrypts already encrypted disks.
#>
function Invoke-Disk-Decryption {

    Get-BitLockerVolume `
        | Where-Object {
            $_.VolumeStatus -ne 'FullyDecrypted'
        } `
        | ForEach-Object {
            manage-bde `
                -off $_.MountPoint
        }

}

<#
.SYNOPSIS
Get the decrytional status for outputting progress to STDOUT.
#>
function Get-Decrytional-Status {

    $volumes = @(
        Get-BitLockerVolume `
            | Where-Object VolumeStatus -ne 'FullyDecrypted' `
            | Select-Object `
                -ExpandProperty MountPoint
    )

    while ($true) {

        $statuses = @(
            Get-BitLockerVolume `
                | Where-Object {
                    $_.MountPoint -in $volumes -and
                    $_.VolumeStatus -ne 'FullyDecrypted'
                }
        )

        if ($statuses.Count -eq 0) {

            break

        }

        foreach ($volume in $statuses) {

            $mountPoint = $volume.MountPoint
            $percent = 100 - $volume.EncryptionPercentage
            $id = [array]::IndexOf(
                    $volumes, $mountPoint
            ) + 1

            Write-Progress `
                -Id $id `
                -Activity "Volume $mountPoint" `
                -Status "$percent% deciphered..." `
                -PercentComplete $percent

        }

        Start-Sleep `
            -Seconds 5

    }

}

<#
.SYNOPSIS
Runs Windows shutdown automatic disk encryption pipeline.
#>
function Main {

    Write-Host `
        "Windows shutdown automatic disk encryption script has been launched." `
        -ForegroundColor Blue

    try {

        # Run decrytional pipline:
        Write-Host `
            "Prohibiting automatic disk encryption..." `
            -ForegroundColor White

        Set-Windows-Automatic-Disk-Encryption-Policies

        Write-Host `
            "Decrypting disks..." `
            -ForegroundColor White

        Invoke-Disk-Decryption

        # Awaiting decrytional:
        Get-Decrytional-Status

    }
    catch {

        Write-Host `
            "A critical error occurred during pipeline execution...`n" `
            "Execution has been aborted!" `
            -Separator "" `
            -ForegroundColor Red

        return

    }

    Write-Host `
        "Decryption complete." `
        -ForegroundColor Green

    Write-Host `
        "Windows shutdown automatic disk encryption scenario completed." `
        -ForegroundColor Blue

}

# Entry point:
Main
