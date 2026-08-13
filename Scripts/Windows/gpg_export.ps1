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

}

<#
.SYNOPSIS
Export real GPG keys files.
#>
function Export-GPG-Keys {

    gpg `
        --armor `
        --export > "$($BackupPath)\public-keys.asc"

    gpg `
        --armor `
        --export-secret-keys > "$($BackupPath)\private-keys.asc"

    gpg `
        --export-ownertrust > "$($BackupPath)\ownertrust.txt"

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

    New-GPG-Backup-Folder
    Export-GPG-Keys
    Export-Optional-GPG-Configs

}

# Entry point:
Main
