#!/usr/bin/env pwsh
#requires -Version 5.1
# Activates the OpenPGP GPG key for signing commits in Git.

# Prefix or fingerprint of the OpenPGP secret key:
$GPGID = ""

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
                        $_ -split '\s+'
                    )[1] `
                        -split '/'
                )[1]
            }

    )

}

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

function Main {

    if ($GPGID -eq "") {

        $gpgId = Get-Default-GPG-ID

    }
    else {

        $gpgId = $GPGID

    }

    Set-Git-Config `
        -OpenPGPKeyId $gpgId

}

# Entry point:
Main
