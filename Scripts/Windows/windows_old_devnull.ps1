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

# Devnull "Windows.old":
if (Test-Path $Path) {
    Get-ChildItem `
        -LiteralPath $Path `
        -Force `
        -Recurse `
        -File `
        -ErrorAction SilentlyContinue |
            ForEach-Object {
                $file = $_.FullName

                Write-Host "Updating '$file' file permissions"
                icacls.exe $file /grant '*S-1-5-32-544:F' /C | Out-Null

                try
                {
                    Remove-Item -LiteralPath $file -Force -ErrorAction Stop
                }

                catch
                {
                    Write-Warning "Failed to delete: $file"
                }
            }
    Write-Host "Windows.old was deleted."
}

else {
    Write-Host "'$Path' not found."
}
