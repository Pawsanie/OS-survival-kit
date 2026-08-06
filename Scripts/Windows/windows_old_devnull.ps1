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
$TargetPath = 'C:\Windows.old'
$AdministratorsPermissions = '*S-1-5-32-544:F'

# Workers srttings:
$PermissibleLoad = 2 / 3
$Flows = [int](
    [Environment]::ProcessorCount * $PermissibleLoad
)


<#
.SYNOPSIS
Get path massive for warkers.

.PARAMETER Path
Path to Windows.old directory.

.OUTPUTS
System.IO.DirectoryInfo pahs massive.
#>
function Get-File-Tree {
    param (
        [string]$Path
    )

    Write-Host `
        "Attempting to collect paths to the contents of the 'Windows.old' directory.`n" `
        "Directory path: '$Path'" `
        -ForegroundColor Blue

     @(
        Get-ChildItem `
            -LiteralPath $Path `
            -Force `
            -Recurse `
            -Directory `
            -ErrorAction SilentlyContinue `
            | Sort-Object FullName `
                -Descending
    )
}

<#
.SYNOPSIS

.PARAMETER Path
Path to file or directory.
#>
function Remove-File-System-Item {
    param (
        [string]$Path
    )

    Remove-Item `
        -LiteralPath $Path `
        -Force `
        -ErrorAction Stop `
        -Confirm:$false

}

<#
.SYNOPSIS
Takes ownership of the file system item
and grants Full Control permissions to the Administrators group.

.PARAMETER Path
Path to file or directory.
#>
function Grant-Permissions {
    param (
        [string]$Path
    )

    Write-Host `
        "Updating file system item permissions...`n" `
        "Item path: '$Path'" `
        -ForegroundColor White

    takeown.exe `
        /F "$Path" `
        | Out-Null

    icacls.exe $Path `
        /grant $AdministratorsPermissions `
        /C `
        | Out-Null

    Write-Host `
        "File system item permissions successfully updated.`n" `
        "Item path: '$Path'" `
        -ForegroundColor White

    }

<#
.SYNOPSIS
Deletes the file system item within the thread worker.

.PARAMETER Path
Path to file or directory.
#>
function Task {
    param (
        [string]$Path
    )

    Write-Host `
        "Attempt to delete file system item...`n" `
        "Item path: '$file'" `
        -ForegroundColor White

    try {
        try {
            Remove-File-System-Item `
                -Path $Path
        }
        catch {
            Write-Host `
                "Access denied!`n" `
                "Ownership and permissions must be acquired for the file system item.!`n" `
                "Item path: '$file'" `
                -ForegroundColor Yellow

            Grant-Permissions `
                -Path $Path

            Remove-File-System-Item `
                -Path $Path
        }

        Write-Host `
            "File system item deletion successful.`n" `
            "Item path: '$Path'" `
            -ForegroundColor Green
    }

    catch {
        Write-Host `
            "Failed to delete file system item!`n" `
            "Item path: '$file'" `
            -ForegroundColor Red
    }

}

<#
.SYNOPSIS
Create and run multi thread tasks.

.PARAMETER Paths
System.IO.DirectoryInfo pahs massive from Get-File-Tree.
#>
function Start-Tasks {
    param (
        [System.IO.DirectoryInfo[]]$Paths
    )

    # Multy thred Runspace ScriptBlock:
    $Worker = {
        param(
            [string]$Task,
            [System.IO.DirectoryInfo]$Path
        )

        Invoke-Expression $Task
        Task $Path
    }

    # Multythreds settings:
    $Pool = [RunspaceFactory]::CreateRunspacePool(
            1,
            $Flows
    )

    # Run tasks:
    $Pool.Open()

    $PowerShellTasks = foreach ($Path in $Paths) {

        $PowerShellWorker = [PowerShell]::Create()
        $PowerShellWorker.RunspacePool = $Pool

        $PowerShellWorker.AddScript($Worker.ToString()) `
            | Out-Null
        $PowerShellWorker.AddArgument(
                ${function:Task}.Ast.Extent.Text
        ) `
            | Out-Null
        $PowerShellWorker.AddArgument($Path) `
            | Out-Null
        $Handle = $PowerShellWorker.BeginInvoke()

        [PSCustomObject]@{
            PowerShell = $PowerShellWorker
            Handle     = $Handle
            Path       = $Path
        }

    }

    # Awaite tasks finish:
    foreach ($PSTask in $PowerShellTasks) {
        try {
            $PSTask.PowerShell.EndInvoke(
                    $PSTask.Handle
            )
        }
        finally {
            $PSTask.PowerShell.Dispose()
        }
    }

    $Pool.Close()
    $Pool.Dispose()

}

<#
.SYNOPSIS
Devnull "Windows.old"
#>
function Remove-WindowsOLD {
    if (Test-Path $TargetPath) {
        Write-Host `
            "The Windows.old directory deletion script has been launched."`
                -ForegroundColor White

        Start-Tasks `
            -Paths (
                Get-File-Tree `
                    -Path $TargetPath
            )

        if (
            -not (Test-Path $TargetPath)
        ) {
            Write-Host "Windows.old deleted successfully." `
                -ForegroundColor Green
        }
        else {
            Write-Host `
                "Failed to delete the Windows.old completely!" `
                -ForegroundColor Red
        }
    }

    else {
        Write-Host `
            "Unable to locate Windows.old!`n" `
            "Directory path: '$TargetPath'" `
            -ForegroundColor Blue
    }

    Write-Host `
        "Windows.old devnull Scenario completed." `
        -ForegroundColor Blue

}

# Entry point:
Remove-WindowsOLD
