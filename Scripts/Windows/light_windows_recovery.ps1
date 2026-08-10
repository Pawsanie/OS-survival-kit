#!/usr/bin/env pwsh
#requires -Version 5.1

function Clear-Windows-Update-Сache {

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

    Clear-Windows-Update-Сache
    Start-Recovery-Trick

}
