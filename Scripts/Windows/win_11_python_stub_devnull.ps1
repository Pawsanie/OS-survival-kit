#!/usr/bin/env pwsh
#requires -Version 5.1
# Removes all Python system stubs that prevent scripts from running normally from the terminal.

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

# Path settings:
$folders = @(
    "$env:LOCALAPPDATA\Microsoft\WindowsApps",
    "C:\Windows\AppInstaller"
)

foreach ($folder in $folders) {
    if (Test-Path $folder) {

        Get-ChildItem `
            -Path $folder `
            -Include "python*.exe",
                "python*.lnk",
                "python*.appref-ms" `
            -File `
            -Recurse `
            -ErrorAction SilentlyContinue `
            | ForEach-Object {

                try {

                    if (
                        $_.Attributes `
                            -band [System.IO.FileAttributes]::ReadOnly
                    ) {

                        $_.Attributes = 'Normal'

                    }

                    Remove-Item `
                        -LiteralPath $_.FullName `
                        -Force `
                        -ErrorAction Stop

                    Write-Host `
                        "Deleted: $($_.FullName)"

                }
                catch {

                    Write-Warning `
                        "Failed to delete $($_.FullName): $_"

                }

            }
    }
}

try {

    Write-Host `
        "`nChecking 'where python':"
        & where.exe python 2>$null `
        | ForEach-Object { Write-Host "  $_" }

}
catch {

    Write-Warning `
        "Failed to execute 'where python': $_"

}
