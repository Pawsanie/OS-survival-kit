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
Get path string massive for warkers multi thread Queue.

.PARAMETER Path
Path to Windows.old directory.

.PARAMETER DirectoriesQueue
Multi thread Queue from main function for Directories.

.PARAMETER FilesQueue
Multi thread Queue from main function for Files.
#>
function Get-Files-Tree {
    param (
        [string]$Path,
        [System.Collections.Concurrent.ConcurrentQueue[string]]$DirectoriesQueue,
        [System.Collections.Concurrent.ConcurrentQueue[string]]$FilesQueue
    )

    Write-Host `
        "Attempting to collect paths to the contents of the 'Windows.old' directory.`n" `
        "Directory path: '$Path'" `
        -ForegroundColor Blue

    foreach (
        $Item in Get-ChildItem `
            -LiteralPath $Path `
            -Force `
            -Recurse `
            -Directory `
            -ErrorAction SilentlyContinue `
            | Sort-Object `
                -Property {
                    $CurrentPath = if ($_.FullName) {$_.FullName} `
                        else {$_.PSPath}
                    $Depth = [regex]::Matches(
                            $CurrentPath,
                            [regex]::Escape(
                                    [System.IO.Path]::DirectorySeparatorChar
                            )
                        ).Count
                    $Depth
                } `
                -Descending
    ) {

        try {

            if ($Item.PSIsContainer) {
                 $DirectoriesQueue.Enqueue(
                         $Item.FullName
                )
             }

             else {
                     $FilesQueue.Enqueue(
                            $Item.FullName
                )
             }

             Write-Host `
                "The path has been added to multithreaded processing queue.`n" `
                "Item path: '$($Item.FullName)'" `
                -ForegroundColor White

        }

        catch {
            Write-Host `
                "Failed to add path to multithreaded processing queue!`n" `
                "Item path: '$($Item.FullName)'" `
                -ForegroundColor Red
        }


    }

}

<#
.SYNOPSIS
Devnulls some Windows.old file system item.

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

.PARAMETER LogsQueue
Multi thread Queue from Start-Workers function for Logs.
#>
function Grant-Permissions {
    param (
        [string]$Path,
        [System.Collections.Concurrent.ConcurrentQueue[psobject]]$LogsQueue
    )

     $LogsQueue.Enqueue(
         [PSCustomObject]@{
            Message = "Updating file system item permissions...`n" `
                      + "Item path: '$Path'"
            Color = [ConsoleColor]::White
        }
    )

    takeown.exe `
        /F "$Path" `
        | Out-Null

    icacls.exe $Path `
        /grant $AdministratorsPermissions `
        /C `
        | Out-Null

    $LogsQueue.Enqueue(
        [PSCustomObject]@{
            Message = "File system item permissions successfully updated.`n" `
                      + "Item path: '$Path'"
            Color = [ConsoleColor]::White
        }
    )

}

<#
.SYNOPSIS
Deletes the file system item within the thread worker.

.PARAMETER Path
Path to file or directory.

.PARAMETER LogsQueue
Multi thread Queue from Start-Workers function for Logs.
#>
function Task {
    param (
        [string]$Path,
        [System.Collections.Concurrent.ConcurrentQueue[psobject]]$LogsQueue
    )

    $LogsQueue.Enqueue(
            [PSCustomObject]@{
                Message = "Attempt to delete file system item...`n" `
                          + "Item path: '$Path'"
                Color = [ConsoleColor]::White
            }
    )

    try {
        try {
            Remove-File-System-Item `
                -Path $Path
        }
        catch {
            $LogsQueue.Enqueue(
                [PSCustomObject]@{
                    Message = "Access denied!`n" `
                              + "Ownership and permissions must be acquired for the file system item.!`n" `
                              + "Item path: '$Path'"
                    Color = [ConsoleColor]::Yellow
                }
            )

            Grant-Permissions `
                -Path $Path `
                -LogsQueue $LogsQueue

            Remove-File-System-Item `
                -Path $Path
        }

        $LogsQueue.Enqueue(
            [PSCustomObject]@{
                Message = "File system item deletion successful.`n" `
                          + "Item path: '$Path'"
                Color = [ConsoleColor]::Green
            }
        )
    }

    catch {
        $LogsQueue.Enqueue(
            [PSCustomObject]@{
                Message = "Failed to delete file system item!`n" `
                          + "Item path: '$Path'`n" `
                          + "Error: $($_.Exception.ToString())"
                Color = [ConsoleColor]::Red
            }
        )
    }

}

<#
.SYNOPSIS
Assign tasks to multithreaded workers.

.PARAMETER Flows
Max threds number.

.PARAMETER Pool
Threds pool.

.PARAMETER Worker
Multy thred Runspace ScriptBlock.

.PARAMETER Queue
Multi thread Queue from main function for Files or Directories.

.PARAMETER LogsQueue
Multi thread Queue from Start-Workers function for Logs.
#>
function Start-Tasks {
    param(
        [int]$Flows,
        [System.Management.Automation.Runspaces.RunspacePool]$Pool,
        [scriptblock]$Worker,
        [System.Collections.Concurrent.ConcurrentQueue[string]]$Queue,
        [System.Collections.Concurrent.ConcurrentQueue[psobject]]$LogsQueue
    )

    foreach ($index in 1..$Flows) {

        $PowerShellWorker = [PowerShell]::Create()
        $PowerShellWorker.RunspacePool = $Pool

        $PowerShellWorker.AddScript(
                $Worker.ToString()
        ) `
            | Out-Null
        $PowerShellWorker.AddArgument(
                @(
                    ${function:Task}.Ast.Extent.Text,
                    ${function:Grant-Permissions}.Ast.Extent.Text,
                    ${function:Remove-File-System-Item}.Ast.Extent.Text
                )
        ) `
            | Out-Null
        $PowerShellWorker.AddArgument(
                $Queue
        ) `
            | Out-Null
        $PowerShellWorker.AddArgument(
                $LogsQueue
        ) `
            | Out-Null
        $Handle = $PowerShellWorker.BeginInvoke()

        [PSCustomObject]@{
            PowerShell = $PowerShellWorker
            Handle = $Handle
        }

    }

}

<#
.SYNOPSIS
Create and run multi thread tasks.

.PARAMETER DirectoriesQueue
Multi thread Queue from main function for Directories.

.PARAMETER FilesQueue
Multi thread Queue from main function for Files.
#>
function Start-Workers {
    param (
        [System.Collections.Concurrent.ConcurrentQueue[string]]$DirectoriesQueue,
        [System.Collections.Concurrent.ConcurrentQueue[string]]$FilesQueue
    )

    # Multy thred Runspace ScriptBlock:
    $Worker = {
        param(
            [string[]]$Functions,
            [System.Collections.Concurrent.ConcurrentQueue[string]]$Queue,
            [System.Collections.Concurrent.ConcurrentQueue[psobject]]$LogsQueue
        )

        foreach ($functionStr in $Functions) {
            Invoke-Expression $functionStr
        }

        while ($true) {

            $CurrentPath = $null
            if (
                -not $Queue.TryDequeue(
                        [ref]$CurrentPath
                )
            ) {
                break
            }

            Task `
                -Path $CurrentPath `
                -LogsQueue $LogsQueue
        }
    }

    # Multythreds settings:
    $LogsQueue = [System.Collections.Concurrent.ConcurrentQueue[psobject]]::new()
    $Pool = [RunspaceFactory]::CreateRunspacePool(
            1,
            $Flows
    )
    $Pool.Open()

    foreach (
        $Queue in @(
            $FilesQueue,
            $DirectoriesQueue
        )
    ) {

        # Run tasks:
        $PowerShellTasks = Start-Tasks `
                        -Flows $Flows `
                        -Pool $Pool `
                        -Worker $Worker `
                        -Queue $Queue `
                        -LogsQueue $LogsQueue

        # Awaite tasks finish:
        while (
            $PowerShellTasks.Handle.IsCompleted `
                -contains $false
        ) {

            $logData = $null
            while (
                $LogsQueue.TryDequeue(
                    [ref]$logData
                )
            ) {

                Write-Host `
                    $logData.Message `
                    -ForegroundColor $logData.Color

            }

            Start-Sleep `
                -Milliseconds 20

        }

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

    }

    $Pool.Close()
    $Pool.Dispose()

}

<#
.SYNOPSIS
Devnulls Windows.old folder.
#>
function Remove-WindowsOLD {

    $DirectoriesQueue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
    $FilesQueue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()

    Get-Files-Tree `
        -Path $TargetPath `
        -DirectoriesQueue $DirectoriesQueue `
        -FilesQueue $FilesQueue

    Start-Workers `
        -DirectoriesQueue $DirectoriesQueue `
        -FilesQueue $FilesQueue

    try {
        Remove-File-System-Item `
            -Path $TargetPath

        Write-Host `
            "Windows.old deleted successfully." `
            -ForegroundColor Green
    }

    catch {
        Write-Host `
            "Failed to delete the Windows.old completely!" `
            -ForegroundColor Red
    }

}

<#
.SYNOPSIS
Runs devnull Windows.old pipeline.
#>
function Main {

    Write-Host `
        "The Windows.old directory deletion script has been launched."`
        -ForegroundColor White

    if (Test-Path $TargetPath) {
        Remove-WindowsOLD
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
Main
