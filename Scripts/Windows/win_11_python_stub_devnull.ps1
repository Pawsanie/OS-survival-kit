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
            '-NoExit',
            '-File',
            $PSCommandPath
    )

    exit

}

# Path settings:
$folders = @(
    "$env:LOCALAPPDATA\Microsoft\WindowsApps",
    "$env:WINDIR\AppInstaller"
)

<#
.SYNOPSIS
Devnull Windows Python stubs EXE files.
#>
function Remove-Python-Stubs {
    foreach ($folder in $folders) {
        if (Test-Path $folder) {

            Get-ChildItem `
                -Path $folder `
                -Include `
                    "python*.exe",
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
                            "Deleted: $($_.FullName)" `
                            -ForegroundColor White

                    }
                    catch {

                        Write-Warning `
                            "Failed to delete $($_.FullName): $_"

                    }

                }

        }

    }

}

<#
.SYNOPSIS
Checks if Python is registered in the PATH.
#>
function Test-Python-Path {

    try {

        if (
            $pythonPaths = & where.exe python 2>$null
        ) {

            Write-Host `
                "Checking 'where python':" `
                -ForegroundColor Green

            $pythonPaths | ForEach-Object {

                Write-Host `
                    "$_" `
                    -ForegroundColor White

            }

        }
        else {

            Write-Host `
                "Python EXE do not found." `
                -ForegroundColor Yellow

        }

    }
    catch {

        Write-Host `
            "Failed to execute 'where python'!" `
            -ForegroundColor Red

    }

}

<#
.SYNOPSIS
Checks if Python is available to call.
#>
function Test-Python-Application {

    try {

        python `
            --version

        return $True

    }
    catch {

        return $False

    }

}

<#
.SYNOPSIS
Runs devnull Windows Python stubs EXE files pipeline.
#>
function Main {

    Write-Host `
        "Windows Python EXE stubs devnull script has been launched." `
        -ForegroundColor White

    Write-Host `
        "Checking Python EXE availability for invocation." `
        -ForegroundColor White

    if (
        -not (Test-Python-Application)
    ) {

        Write-Host `
            "Unable to invocate Python EXE: remove stubs." `
            -ForegroundColor White

        Remove-Python-Stubs

    }
    else {

        Write-Host `
            "Stubs do not interfere with invocate Python EXE." `
            -ForegroundColor Green

        python `
            --version

    }

    Test-Python-Path

    Write-Host `
        "Windows Python EXE stubs devnull scenario completed." `
        -ForegroundColor Blue

}

# Entry point:
Main
