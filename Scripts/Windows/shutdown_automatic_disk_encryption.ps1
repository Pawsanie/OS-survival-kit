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

    reg `
        add "HKLM\SYSTEM\CurrentControlSet\Control\BitLocker" `
        /v PreventDeviceEncryption `
        /t REG_DWORD `
        /d 1 `
        /f

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
Runs Windows shutdown automatic disk encryption pipeline.
#>
function Main {}

# Entry point:
Main
