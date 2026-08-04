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

                Write-Host `
                    "Updating file permissions...`n" `
                    "File path: '$file'" `
                    -ForegroundColor White
                icacls.exe $file `
                    /grant '*S-1-5-32-544:F' `
                    /C `
                    | Out-Null

               Write-Host `
                    "Attempt to delete file...`n" `
                    "File path: '$file'" `
                        -ForegroundColor White
                try {
                    Remove-Item `
                        -LiteralPath $file `
                        -Force `
                        -ErrorAction Stop `
                        -Confirm:$false
                    Write-Host `
                        "File deletion successful.`n" `
                        "File path: '$file'" `
                        -ForegroundColor White
                }

                catch {
                    Write-Host `
                        "Failed to delete file!`n" `
                        "File path: '$file'" `
                        -ForegroundColor Yellow
                }

            }

        }

    try {
        Write-Host `
            "Attempt to delete directory...`n" `
            "Directory path: '$Directory'"
        Remove-Item `
            -LiteralPath $Directory `
            -Force `
            -ErrorAction Stop `
            -Confirm:$false
    }
    catch {
        Write-Host `
            "Failed to delete directory!`n" `
            "Directory path: '$Directory'" `
            -ForegroundColor Yellow
    }
}

# Devnull "Windows.old":
function Remove-WindowsOLD {
    if (Test-Path $Path) {
        Remove-Directory $Path

        if (
            -not (Test-Path $Path)
        ) {
            Write-Host "Windows.old deleted successfully." `
                -ForegroundColor Green
        }
        else {
            Write-Error "Failed to delete the Windows.old completely!"
        }
    }

    else {
        Write-Host `
            "Unable to locate Windows.old!`n" `
            "Directory path: '$Path'" `
            -ForegroundColor Blue
    }
}

Remove-WindowsOLD
