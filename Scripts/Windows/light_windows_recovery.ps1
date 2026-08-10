#!/usr/bin/env pwsh
#requires -Version 5.1

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
            '-NoExit'
            '-File',
            $PSCommandPath
    )
    exit
}

function Clear-Windows-Update-Cache {

    $windowsUpdateServices = @(
        "cryptsvc"
        "bits"
        "wuauserv"
    )

    Stop-Service `
        -Name $windowsUpdateServices `
        -Force

    Remove-Item "$env:windir\SoftwareDistribution\*" `
        -Recurse `
        -Force

    Remove-Item "$env:windir\System32\catroot2\*" `
        -Recurse `
        -Force

    Start-Service `
        -Name $windowsUpdateServices

}

function Start-Recovery-Trick {

    DISM.exe `
        /Online `
        /Cleanup-Image `
        /RestoreHealth

    sfc.exe /scannow

}

function Main {

    try {
        Clear-Windows-Update-Cache `
            -ErrorAction Stop
    }
    catch {
        Write-Error $_
        return
    }
    Start-Recovery-Trick

}

# Entry point:
Main
