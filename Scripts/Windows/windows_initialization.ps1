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
Runs Windows initialization pipeline.
#>
function Main {}

# Entry point:
Main
