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