# OS Survival Kit

The repository contains and will be slowly updated with scripts that solve obscure problems<br>
in the practical operation of personal computer operating systems,<br>
the investigation and resolution of which can take hours.

:wink:Cloning without giving it a :star:? Nah, I’m not that lazy.:wink:

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

### Windows Scripts:
* [GPG Signature Management](#GPG-Signature-Management)
* [Light Windows Recovery](#Light-Windows-Recovery)
* [Windows WER ReportArchive read access problems](#Windows-WER-ReportArchive-read-access-problems)
* [Windows 11 Python cannot be invoked from CMD or PowerShell](#Windows-11-Python-cannot-be-invoked-from-CMD-or-PowerShell)
* [Undeletable Windows.old folder](#Undeletable-Windowsold-folder)

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
1) Press the "**Win+R**" keyboard keys combination.
2) In the window that opens, type "**PowerShell**" and press "**Ctrl+Shift+Enter**" keyboard keys combination.<br>
   Please note that this window is called "**Administrator Windows PowerShell**".
3) **Copy** and **paste** the command below into the window and then press Enter.
   ```powershell
   Get-ExecutionPolicy -Scope CurrentUser
   ```
   Remember the value that was shown in the output, especially if it was "**Undefined**" or "**Restricted**".<br>
   You will need it to restore the original policy later.
4) **Copy** and **paste** the command below into the window and then press Enter.
   ```powershell
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
    ```
5) Press the "**Win+R**" keyboard keys combination again.
6) In the window that opens, write "**notepad**" and press "**Enter**".<br>
   Due to the specific nature of the program, the window that opens will likely not have a name.<br>
   Just remember that its name is "**Notepad**".
7) By following the link from the documentation, or from the repository itself, to the script code,<br>
   copy its entire text by double-clicking on it with the left mouse button, and then pressing the "**Ctrl+A**" and "**Ctrl+C**".
8) Return to the notepad window and paste the copied code there by "**Ctrl+V**" key combination.
9) Press "**Enter**" twice to indent lines 2 times.
10) Press "**Ctrl+A**" and "**Ctrl+C**" again to copy code with 2 additional lines.<br>
    This is necessary for the script to work correctly,<br>
    since the code repository does not show line breaks after the text has actually ended when viewed through a web page.
11) Return to the "**Administrator Windows PowerShell**" window.
12) Paste the code there by "**Ctrl+V**" key combination and press "**Enter**" to execute it.
13) Restore the security policy to its previous state using the command:
    ```powershell
     Set-ExecutionPolicy <the value you remembered in step 3> -Scope CurrentUser
    ```
    As an example, your default value is likely:
    ```powershell
     Set-ExecutionPolicy Undefined -Scope CurrentUser
    ```

:hearts:Done: You are amazing!:hearts:

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
5) Run the script which you need through IDE or the PowerShell terminal.
6) After executing the required scenarios revert the policies to the default state "**Undefined**", or to state "**Restricted**" if necessary.
    ```powershell
    Set-ExecutionPolicy Undefined
    Set-ExecutionPolicy Undefined -Scope CurrentUser
    ```
   Or for a complete restricted:
    ```powershell
    Set-ExecutionPolicy Restricted
    Set-ExecutionPolicy Restricted -Scope CurrentUser
    ```
   
## Windows Administration:

### GPG Signature Management:
**OpenPGP** secret keys are used, for example, to sign commits for GitHub.<br>
On the client side, this process is managed using the GNU Privacy Guard (**GPG**) utilities.<br>
In the Microsoft Windows family of operating systems, GPG is usually installed via the **Gpg4win** installer.

When installing a new operating system, you may need to migrate GPG secret keys.<br>
And with a clean Windows installation, you may need to customize your Git config by adding explicit references to your GPG utility and OpenPGP secret key.

The following scripts have been written to automate this process:<br>
**./**:open_file_folder:Scripts<br>
   └── :file_folder:Windows<br>
            ├── :page_facing_up:[git_gpg_activate.ps1](Scripts/Windows/git_gpg_activate.ps1)<br>
            ├── :page_facing_up:[gpg_export.ps1](Scripts/Windows/gpg_export.ps1)<br>
            └── :page_facing_up:[gpg_import.ps1](Scripts/Windows/gpg_import.ps1)
<br><br>

### Light Windows Recovery:
You've probably heard of the magic command "**sfc /scannow**", which will help you fix Windows system issues.<br>
The problem is that it is unlikely to help on its own without the "**DISM /RestoreHealth**" command.<br>
The DISM utility may rely on "**Windows Update**" to obtain the required components.<br>
And before that, you'll probably need to clear the Windows Update **cache**.<br>
And you will need to run commands with elevated privileges.

The whole process is already automated in the script.<br>
**./**:open_file_folder:Scripts<br>
   └── :file_folder:Windows<br>
            └── :page_facing_up:[light_windows_recovery.ps1](Scripts/Windows/light_windows_recovery.ps1)
<br><br>

### Windows WER ReportArchive read access problems:
Windows Error Reporting (WER) collects, stores, and may send crash information to Microsoft.<br>
Sometimes, to diagnose or analyze problems with the operating system or individual applications,<br>
a user may need to access the contents of the "**ReportArchive**" directory.<br>
Due to the way file system permissions and access policies are implemented,<br>
the necessary reports may not be accessible through File Explorer in the simplest and most natural way<br>
on a desktop OS.<br>
Default ReportArchive location:
```text
C:\ProgramData\Microsoft\Windows\WER\ReportArchive
```

With an administrator account, you can access the files through an elevated PowerShell terminal, for example.<br>
However, entering cumbersome commands for each report is highly inconvenient.<br>
This is especially true if you want to open a report with a non-standard text editor.

It's much easier to have a script that automatically grants the current administrator full access to report folders <br>
within ReportArchive and their contents, recursively.

The whole process is already automated in the script.<br>
**./**:open_file_folder:Scripts<br>
   └── :file_folder:Windows<br>
            └── :page_facing_up:[WER_ReportArchive_grant_read_access.ps1](Scripts/Windows/WER_ReportArchive_grant_read_access.ps1)
<br><br>

### Windows 11 Python cannot be invoked from CMD or PowerShell:
For engineers running their automation scripts written in Python<br>
or users learning this programming language,<br>
it is sometimes natural to launch a program from a **CMD** or **PowerShell** terminal rather than from an IDE.

By default, in **Windows 11**,<br>
if you want to call Python from CMD or PowerShell in this way,<br>
you will encounter some fantastic OS behavior.

Namely, regardless of whether Python is installed or where and how it was installed,<br>
running the "**python**" command will always open the corresponding page in the **Microsoft Store**.<br>
When used inside scripts, however, it simply writes its name.

This happens because instead of the normal python.exe launch stub App Execution Aliases from the folder:
```text
C:\Users\<UserName>\AppData\Local\Microsoft\WindowsApps
```
If the OS is running normally and installed correctly, this shouldn't happen.<br>
Python installed from the Microsoft Store is configured correctly by default,<br>
while the installer adds the required PATH when the appropriate option is selected.<br>
However, during migrations from Windows 10 to 11 or after reinstalling OS,<br>
as well as in other rare cases, this often stops working as intended.

To solve this problem, simply delete the **stub** python EXE files.<br>
The whole process is already automated in the script.<br>
**./**:open_file_folder:Scripts<br>
   └── :file_folder:Windows<br>
            └── :page_facing_up:[win_11_python_stub_devnull.ps1](Scripts/Windows/win_11_python_stub_devnull.ps1)
<br><br>

### Undeletable Windows.old folder:
When you try to select the "**Windows.old**" folder and delete it,<br>
you will find that after a moment of consideration,<br>
the operating system will refuse to let you do so, even if you have opened Explorer as an administrator.

This happens because Windows 11 is designed to delete it first, using "**Settings** -> **System** -> **Storage**".<br>
However, you most likely won't find anything there,<br>
so if the operating system is running normally, you can and should use the built-in "**Disk Cleanup**" utility,<br>
using the following steps:
1) Open the "**Run**" window using the "**Win+R**" combination.
2) Type "**cleanmgr**" and press "**Enter**".
3) Select the disk where the OS is installed.
4) In the window that opens, click the "**Clean up system files**" button.
5) Select the Windows disk again.
6) In the list, find the checkbox "**Previous Windows installations**" and check it.
7) Confirm deletion.

However, in some cases involving migration from Windows 10 to 11,<br>
or in rare cases after reinstalling Windows, none of the above methods will help.<br>
So why can't you delete this folder in the most natural way for a Windows user?

This happens because even when running as administrator,<br>
File Explorer and PowerShell provide different capabilities for working<br>
with protected file system objects.<br>
But this is not the only problem, so there is no point in addressing this specifically.<br>
The problem is that you can't delete this folder using the "**Remove-Item**" cmdlet even from PowerShell running with elevated privileges.

The reason for this is that a significant portion of file system objects<br>
within the directory of interest owned by the system account "NT AUTHORITY\SYSTEM" or other technical accounts<br>
with corresponding access restrictions.

Therefore, you must first recursively acquire ownership of the entire contents<br>
of the "Windows.old" folder using the "**takeown**" utility.<br>
Then grant yourself the necessary permissions to their contents by the "**icacls**" utility.

But in addition to all of the above, "Remove-Item" may have problems with removing "hard links".<br>
To delete them, you will need to use the ".NET API" method "[System.IO.File]::Delete".

However, if we abstract from this and simply execute the sequence of commands, it will appear to be doing nothing for a long time.<br>
The problem is that this process will take an **INORDINATELY LONG** time,<br>
while the directory will remain untouched until the preceding commands have completed.

Therefore, it would be better to delete the files and folders from the deepest level back to the root,<br>
processing independent branches in parallel via multithreading.

The whole process is already automated in the script.<br>
**./**:open_file_folder:Scripts<br>
   └── :file_folder:Windows<br>
            └── :page_facing_up:[windows_old_devnull.ps1](Scripts/Windows/windows_old_devnull.ps1)
<br><br>


***

:hearts: **Thank you** for your interest in my work! :hearts:<br><br>
