#!/usr/bin/env pwsh
#requires -Version 5.1
# Import user GPG keys from backup folder.

# Path settings:
$TargetDisc = "D"
$BackupPath = "$($TargetDisc):\gpg-backup"

# Functional variables:
$GPGPath = ""

<#
.SYNOPSIS
Checking that the Gpg4win is installed.
#>
function Test-GPG {

    Write-Host `
        "Checking for Gpg4win availability." `
        -ForegroundColor White

    try {

        gpg `
            --version

        $script:GPGPath = Split-Path (
            Split-Path `
                $(where.exe gpg) `
                -Parent
        ) `
            -Parent

    }
    catch {

        Write-Host `
            "Gpg4win not installed!" `
            -ForegroundColor Red

        throw

    }

}


<#
.SYNOPSIS
Import OpenPGP keys files.
When executing the function code, you must enter a GPG key password if necessary.
#>
function Import-GPG-Keys {

    gpg `
        --import "$BackupPath\private-keys.asc"

    gpg `
        --import-ownertrust "$BackupPath\ownertrust.txt"

}


<#
.SYNOPSIS
Runs GPG keys import pipeline.
#>
function Main {

    Write-Host `
        "The GPG OpenPGP keys import script has been launched."`
        -ForegroundColor White

    try {

        Test-GPG

    }
    catch {

        Write-Host `
            "Script execution was terminated due to non-compliance with requirements..." `
            -ForegroundColor Red

        return

    }

    Import-GPG-Keys

    Write-Host `
        "GPG OpenPGP keys import scenario completed." `
        -ForegroundColor Blue

}

# Entry point:
Main
