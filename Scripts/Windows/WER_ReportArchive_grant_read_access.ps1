#!/usr/bin/env pwsh
#requires -Version 5.1
# The script grants to the current administrator permissions to read all WER reports.

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
            '-File',
            $PSCommandPath
    )
    exit
}

Write-Host `
    "WER reports permissions update script has been launched."`
    -ForegroundColor White

Get-ChildItem `
    -LiteralPath 'C:\ProgramData\Microsoft\Windows\WER\ReportArchive' `
    -Force `
    -Directory `
    -ErrorAction SilentlyContinue `
    | ForEach-Object {

        $ReportName = $_
        $ReportPath = $ReportName.FullName

        takeown.exe `
            /F $ReportPath `
            /R `
            /A `
            /D Y `
            | Out-Null

        icacls.exe `
            $ReportPath `
            /grant "$($env:USERDOMAIN)\$($env:USERNAME):(OI)(CI)F" `
            /setintegritylevel M `
            /T `
            /C `
            | Out-Null

        Write-Host `
            "Permissions updated: $ReportName" `
            -ForegroundColor Green

    }

Write-Host `
    "WER reports permissions update Scenario completed." `
    -ForegroundColor Blue
