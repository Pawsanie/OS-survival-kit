#!/usr/bin/env pwsh
#requires -Version 5.1
# Recursively deletes the contents of the "Windows.old" folder.

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
$Path = 'C:\Windows.old'

# Recursive devnull directory:
function Remove-Directory {
    param (
        [string]$Directory
    )

    Get-ChildItem `
        -LiteralPath $Directory `
        -Force `
        -ErrorAction SilentlyContinue `
        | ForEach-Object {
            if ($_.PSIsContainer) {
                Remove-Directory $_.FullName
            }
            else {
                $file = $_.FullName

                Write-Host "Updating '$file' file permissions"
                icacls.exe $file /grant '*S-1-5-32-544:F' /C | Out-Null

                try {
                    Write-Host "Attempt to delete '$file' file..."
                    Remove-Item `
                        -LiteralPath $file `
                        -Force `
                        -ErrorAction Stop
                }
                catch {
                    Write-Warning "Failed to delete: $file"
                }
            }
        }

    try {
        Write-Host "Attempt to delete directory '$Directory'..."
        Remove-Item `
            -LiteralPath $Directory `
            -Force `
            -ErrorAction Stop
    }
    catch {
        Write-Warning "Failed to delete directory: $Directory"
    }
}

# Devnull "Windows.old":
if (Test-Path $Path) {
    Remove-Directory $Path
    Write-Host "Windows.old was deleted."
}
