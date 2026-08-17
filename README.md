# OS Survival Kit

The repository contains and will be slowly updated with scripts that solve obscure problems<br>
in the practical operation of personal computer operating systems,<br>
the investigation and resolution of which can take hours.

:wink:Cloning without to give it a :star:? Nah, I’m not that lazy.:wink:

## Disclaimer:
:warning:**Using** some or all of the elements of this code, **You** assume **responsibility for any consequences!**<br>

:warning:The **licenses** for the technologies on which the code **depends** are subject to **change by their authors**.<br><br>

## Contents:
### Requirements:
Contains information about requirements to execute scripts and how to check them.
* [Required](#Required)

### Quick Start:
Contains information about requirements to execute scripts and how to check them.
* [Quick Start for the Technically Uninitiated](#Quick-Start-for-the-Technically-Uninitiated)
* [Quick Start for Engineers](#Quick-Start-for-Engineers)

___
<br>

## Required:
You must have an account with Administrator or Root rights to execute scripts.<br>
If you don't know how to check whether your account is a member of the Administrators group, follow these steps.

For **Windows**:
1) Press the "**Win+R**" keyboard keys combination simultaneously.
2) In the window that opens, write "**cmd.exe**" and press **Enter**.
3) **Copy** and **paste** the command below into the terminal window that opens and press **Enter**.
    ```cmd
    whoami /groups | findstr S-1-5-32-544 >nul && echo True || echo False
    ```
If the terminal displays "**True**" then you are a member of the Administrators group.<br>
and you can execute scripts from this repository.<br>
However, if you see "**False**" instead, then you need to contact your administrator or PC owner to resolve your issue.

## Quick Start for the Technically Uninitiated

## Quick Start for Engineers

1) Press the "**Win+R**" keyboard keys combination.
2) In the window that opens, write "**PowerShell**" and press "**Ctrl+Shift+Enter**" keyboard keys combination.
3) Check the PowerShell script execution policies for **CurrentUser** and **LocalMachine** using the command.
    ```powershell
    Get-ExecutionPolicy -List
    ```
    At least one of these two policies must be different from "**Undefined**" or "**Restricted**".
4) You need to convert the policies to one of them, depending on how you got the scripts using by one of commands:
    * If you copied and saved the script locally, or in most cases when cloning a repository.<br>
       For all PC users:
       ```powershell
       Set-ExecutionPolicy RemoteSigned
       ```
      Or only for You:
       ```powershell
       Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
       ```
    * If the script is marked as "downloaded from the Internet", for example during a regular download.<br>
      :warning:This is a less secure policy.:warning:<br>
       For all PC users:
       ```powershell
       Set-ExecutionPolicy Bypass
       ```
      Or only for You:
       ```powershell
       Set-ExecutionPolicy Bypass -Scope CurrentUser
       ```
5) After executing the required scenarios revert the policies to the default state "**Undefined**", or to state "**Restricted**" if necessary.
    ```powershell
    Set-ExecutionPolicy Undefined
    Set-ExecutionPolicy Undefined -Scope CurrentUser
    ```
   Or for a complete restricted:
    ```powershell
    Set-ExecutionPolicy Restricted
    Set-ExecutionPolicy Restricted -Scope CurrentUser
    ```
