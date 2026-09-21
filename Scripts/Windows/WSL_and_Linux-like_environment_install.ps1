#!/usr/bin/env pwsh
#requires -Version 5.1
# The script installs and configures WSL and sets up Linux-like environment.

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
            '-ExecutionPolicy Bypass',
            '-NoExit',
            '-File',
            $PSCommandPath
    )

    exit

}

# TaskManager settings:
$TaskName = "Continue-WSL-Install"

# WSL settings:
$Distribution = "Ubuntu"

<#
.SYNOPSIS
Create a one-time task that will be executed after the OS restarts.

.PARAMETER Scriptblock
Scriptblock for WSL configuration and Ubuntu installation.
#>
function Register-Task {
    param(
        [scriptblock] $Scriptblock
    )

    $marker = [guid]::NewGuid().ToString()

    Register-ScheduledTask `
        -TaskName $TaskName `
        -Action (
            New-ScheduledTaskAction `
                -Execute "powershell.exe" `
                -Argument "$(
                    @(
                        "-NoProfile"
                        "-ExecutionPolicy Bypass"
                        "-NoExit"
                        "-EncodedCommand"
                        [Convert]::ToBase64String(
                            [Text.Encoding]::Unicode.GetBytes(
                                $ExecutionContext.InvokeCommand.ExpandString(
                                    $Scriptblock.Ast.EndBlock.Extent.Text.Replace(
                                            '`',
                                            $marker
                                    )
                                ).Replace(
                                            $marker,
                                            '`'
                                    )
                            )
                        )
                    ) `
                        -join " "
                )"
        ) `
        -Trigger (
            New-ScheduledTaskTrigger `
                -AtLogOn `
                -User $env:USERNAME
        ) `
        -Principal (
            New-ScheduledTaskPrincipal `
                -UserId $env:USERNAME `
                -LogonType Interactive `
                -RunLevel Highest
        ) `
        -Force

}

<#
.SYNOPSIS
Invoke user input.

.OUTPUTS
User input string.
#>
function Invoke-input {

    return Read-Host `
         "[ Y | Yes ] or [ N | No ]"

}

<#
.SYNOPSIS
The real check for the need to restart with recursion.
#>
function Get-Restart-Status {

    $inputStatus = Invoke-input

    if ($inputStatus  -in "Y", "Yes") {

        Restart-Computer

    }
    elseif ($inputStatus -in "N", "No") {

        Write-Host `
            "Script execution has been paused.`n" `
            "Manually restart the computer to continue the installation." `
            -Separator "" `
            -ForegroundColor Green

        return

    }
    else {

        Write-Host `
            "Invalid input...`n" `
            "Enter one of the following values:" `
            -Separator "" `
            -ForegroundColor Yellow

        Get-Restart-Status

    }

}

<#
.SYNOPSIS
Triggers the mechanism that checks whether a computer restart is required.
#>
function Invoke-Restart {

    Write-Host `
        "A computer restart is required to continue the installation.`n" `
        "Restart now?" `
        -Separator "" `
        -ForegroundColor Cyan

    Get-Restart-Status

}

<#
.SYNOPSIS
Runs a pipeline to install and configure WSL and Linux-like environment.
#>
function Main {

    Write-Host `
        "Install and configure WSL and Linux-like environment pipeline has been launched." `
        -ForegroundColor Blue

    # WSL installation:
    if (
        (
            Get-Command wsl.exe `
                -ErrorAction SilentlyContinue
        ) `
        -and (
            $null -eq (
                Get-ScheduledTask `
                    -TaskName $TaskName `
                    -ErrorAction SilentlyContinue
            )
        )
    ) {

        if (
            $Distribution -in (
                wsl `
                    --list `
                    --quiet
            )
        ) {

            Write-Host `
                "WSL and Linux-like environment already installed and configured.`n" `
                "Nothing to do." `
                -Separator "" `
                -ForegroundColor Green

        }
        else {

            Write-Host `
                "Configuring WSL..." `
                -ForegroundColor Cyan

            wsl `
                --update
            wsl `
                --set-default-version 2

            Write-Host `
                "Installing Linux-like environment..." `
                -ForegroundColor Cyan

            wsl `
                --install `
                -d $Distribution `
                --no-launch

        }

        Write-Host `
            "Install and configure WSL and Linux-like environment pipeline scenario completed." `
            -ForegroundColor Blue

        exit 0

    }
    else {

        Write-Host `
            "Installation of WSL..." `
            -ForegroundColor Cyan

        wsl `
            --install `
            --no-distribution

    }

    # Distribution configuration:
    if (
        $null -eq (
            Get-ScheduledTask `
                -TaskName $TaskName `
                -ErrorAction SilentlyContinue
        ) `
        -and (
            $Distribution -notin (
                wsl `
                    --list `
                    --quiet
            )
        )
    ) {

        Write-Host `
            "Setting a Task for the Task scheduler...." `
            -ForegroundColor Cyan

        Register-Task {

            Write-Host `
                "Install and configure WSL and Linux-like environment pipeline continues." `
                -ForegroundColor Blue

            Write-Host `
                "Configuring WSL..." `
                -ForegroundColor Cyan

            wsl `
                --update
            wsl `
                --set-default-version 2

            Write-Host `
                "Installing Linux-like environment..." `
                -ForegroundColor Cyan

            wsl `
                --install `
                -d $Distribution `
                --no-launch

            Write-Host `
                "Removing a Task from the Task Scheduler..." `
                -ForegroundColor Cyan

            Unregister-ScheduledTask `
                -TaskName $TaskName `
                -Confirm:$false

            Write-Host `
                "Install and configure WSL and Linux-like environment pipeline scenario completed." `
                -ForegroundColor Blue

        }

        Invoke-Restart

    }
    else {

        Write-Host `
            "The restart task has already been scheduled.`n" `
            "Nothing to do." `
            -Separator "" `
            -ForegroundColor Green

        Invoke-Restart

    }

    Write-Host `
        "Install and configure WSL and Linux-like environment pipeline scenario completed." `
        -ForegroundColor Blue

}

# Entry point:
Main
