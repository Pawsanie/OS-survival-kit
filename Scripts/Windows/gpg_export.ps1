#!/usr/bin/env pwsh
#requires -Version 5.1
# Export user GPG keys to backup folder.

# Path settings:
$TargetDisc = "D"
$BackupPath = "$($TargetDisc):\gpg-backup"

<#
.SYNOPSIS
Creates a backup folder if necessary.
#>
function New-GPG-Backup-Folder {

    if (
        -not (Test-Path $BackupPath)
    ) {

        mkdir `
            $BackupPath

    }
    else {

        Write-Host `
            "The catalog already exists..."`
            -ForegroundColor White

    }

}

<#
.SYNOPSIS
Export OpenPGP keys files.
When executing the function code, you must enter a GPG key password if necessary.
#>
function Export-GPG-Keys {

    gpg `
        --armor `
        --export `
        --output  "$($BackupPath)\public-keys.asc"

    gpg `
        --armor `
        --export-secret-keys `
        --output "$($BackupPath)\private-keys.asc"

    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [System.IO.File]::WriteAllLines(

            "$BackupPath\ownertrust.txt",

            $(
                gpg `
                    --export-ownertrust
            ),

            $(
                New-Object `
                    System.Text.UTF8Encoding(
                        $false
                    )
            )
    )

}

<#
.SYNOPSIS
Copy optional GPG configuration files.
#>
function Export-Optional-GPG-Configs {

    foreach (
        $file in @{
            "gpg.conf" = "$env:APPDATA\gnupg\gpg.conf"
            "gpg-agent.conf" = "$env:APPDATA\gnupg\gpg-agent.conf"
        }.GetEnumerator()
    ) {

        if (Test-Path $file.Value) {

            Copy-Item `
                $file.Value `
                "$BackupPath\$($file.Key)"

        }

    }

}

<#
.SYNOPSIS
Runs GPG keys export pipeline.
#>
function Main {

    Write-Host `
        "The GPG export script has been launched."`
        -ForegroundColor Blue

    try {
        Write-Host `
            "Attempting to create a directory for secrets..."`
            -ForegroundColor White
        New-GPG-Backup-Folder
    }
    catch {
        Write-Host `
            "Unable to create directory for secrets!`nPath: $($BackupPath)"`
            -ForegroundColor Red
        return
    }

    Write-Host `
        "Attempt to export OpenPGP secrets..."`
        -ForegroundColor White
    Export-GPG-Keys

    Write-Host `
        "Attempt to export optional GPG configs"`
        -ForegroundColor White
    Export-Optional-GPG-Configs

    Write-Host `
        "GPG export script Scenario completed." `
        -ForegroundColor Blue

}

# Entry point:
Main
