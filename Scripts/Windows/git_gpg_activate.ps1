#!/usr/bin/env pwsh
#requires -Version 5.1
# Activates the OpenPGP GPG key for signing commits in Git.

# Prefix or fingerprint of the OpenPGP secret key:
$GPGID = ""

<#
.SYNOPSIS
Get default OpenPGP secret key prefix for Git configuration.

.OUTPUTS
OpenPGP secret key prefix.
#>
function Get-Default-GPG-ID {

    return (

        gpg `
            --list-secret-keys `
            --keyid-format LONG `
            | Select-String '^sec\s' `
            | Select-Object `
                -First 1 `
            | ForEach-Object {
                (
                    (
                        $_ `
                            -split '\s+'
                    )[1] `
                        -split '/'
                )[1]
            }

    )

}

<#
.SYNOPSIS
Setup OpenPGP GPG Git configuration.

.PARAMETER OpenPGPKeyId
Prefix or fingerprint of the OpenPGP secret key.
#>
function Set-Git-Config {
    param(
        [string]$OpenPGPKeyId
    )

    git config `
        --global `
        user.signingkey $OpenPGPKeyId

    git config `
        --global `
        commit.gpgsign true

    git config `
        --global `
        gpg.program $(
            [System.IO.Path]::GetFullPath(
                (
                    Get-Command gpg.exe `
                        -ErrorAction Stop
                ).Path
            )
        )

}

<#
.SYNOPSIS
Checking that the GitBash is installed.
#>
function Test-Git {

    Write-Host `
        "Checking for GitBash availability." `
        -ForegroundColor White

    try {

        git `
            --version

    }
    catch {

        Write-Host `
            "GitBash not installed!" `
            -ForegroundColor Red

        throw

    }

}

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
Runs Git GPG signing activation pipeline.
#>
function Main {

    Write-Host `
        "The GPG signing activation script has been launched."`
        -ForegroundColor White

    try {

        Test-Git
        Test-GPG

    }
    catch {

        Write-Host `
            "Script execution was terminated due to non-compliance with requirements..." `
            -ForegroundColor Red

        return

    }

    if ($GPGID -eq "") {

        Write-Host `
        "The OpenPGP secret key ID is not hardcoded.`n" `
        "Attempting to get default OpenPGP secret key ID..." `
        -ForegroundColor Yellow

        try {

            $gpgId = Get-Default-GPG-ID

        }
        catch {

            Write-Host `
                "Unable to get default OpenPGP secret key ID.`n" `
                "Script execution terminated!" `
                -ForegroundColor Red

            return

        }

    }
    else {

        Write-Host `
            "The OpenPGP secret key ID is hardcoded." `
            -ForegroundColor White

        $gpgId = $GPGID

    }

    Write-Host `
        "Attempting to update the Git utility configuration." `
        -ForegroundColor White

    Set-Git-Config `
        -OpenPGPKeyId $gpgId

    Write-Host `
        "GPG signing activation scenario completed." `
        -ForegroundColor Blue

}

# Entry point:
Main
