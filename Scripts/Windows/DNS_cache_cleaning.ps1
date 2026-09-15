#!/usr/bin/env pwsh
#requires -Version 5.1
# The script clears the DNS cache using the ipconfig utility.


Write-Host `
    "Windows DNS cache clearing script has been launched." `
    -ForegroundColor Blue

foreach (
    $command in (
        [ordered]@{
            "/flushdns" = "Flushing DNS cache..."
            "/release" = "Releasing IP address..."
            "/renew" = "Renewing IP address..."
        }
    ).GetEnumerator()
) {

    Write-Host `
        $command.Value `
        -ForegroundColor Cyan

    ipconfig `
        $command.Key

}

Write-Host `
    "Windows DNS cache clearing scenario completed." `
    -ForegroundColor Blue
