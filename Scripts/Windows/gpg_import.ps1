#!/usr/bin/env pwsh
#requires -Version 5.1
# Import user GPG keys from backup folder.

# Path settings:
$TargetDisc = "D"
$BackupPath = "$($TargetDisc):\gpg-backup"

# Functional constants:
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

    }

}


<#
.SYNOPSIS
Import OpenPGP keys files.
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

    try {

        Test-GPG

    }
    catch {}

    Import-GPG-Keys

}

# Entry point:
Main
