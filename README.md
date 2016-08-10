[![Build status](https://ci.appveyor.com/api/projects/status/cg28qxeco39wgo9l/branch/master?svg=true)](https://ci.appveyor.com/project/PowerShell/xcomputermanagement/branch/master)

# xComputerManagement

The xComputerManagement module is a part of the Windows PowerShell Desired State Configuration (DSC) Resource Kit, which is a collection of DSC Resources produced by the PowerShell Team.
This module contains the xComputer resource.
This DSC Resource allows you to rename a computer and add it to a domain or workgroup.

All of the resources in the DSC Resource Kit are provided AS IS, and are not supported through any Microsoft standard support program or service.
The ""x" in xComputerManagement stands for experimental, which means that these resources will be fix forward and monitored by the module owner(s).

Please leave comments, feature requests, and bug reports in the Issues tab for this module.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

If you would like to modify xComputerManagement module, feel free.
When modifying, please update the module name, resource friendly name, and MOF class name (instructions below).
As specified in the license, you may copy or modify this resource as long as they are used on the Windows Platform.

PowerShell Blog (this is a good starting point).
There are also great community resources, such as PowerShell.org, or PowerShell Magazine.
For more information on the DSC Resource Kit, check out this blog post.

## Installation
To install xComputerManagement module

Unzip the content under $env:ProgramFiles\WindowsPowerShell\Modules folder
To confirm installation:

Run Get-DSCResource to see that xComputer is among the DSC Resources listed
Requirements
This module requires the latest version of PowerShell (v4.0, which ships in Windows 8.1 or Windows Server 2012R2).
To easily use PowerShell 4.0 on older operating systems, install WMF 4.0.
Please read the installation instructions that are present on both the download page and the release notes for WMF 4.0

## Description
The xComputerManagement module contains the following resources:
* xComputer - allows you to configure a computer by changing its name and modifying its domain or workgroup.
* xOfflineDomainJoin - allows you to join computers to an AD Domain using an [Offline Domain Join](https://technet.microsoft.com/en-us/library/offline-domain-join-djoin-step-by-step(v=ws.10).aspx) request file.

## xComputer
xComputer resource has following properties:

* Name: The desired computer name
* DomainName: The name of the domain to join
* JoinOU: The distinguished name of the organizational unit that the computer account will be created in
* WorkGroupName: The name of the workgroup
* Credential: Credential to be used to join or leave domain
* CurrentOU: A read-only property that specifies the organizational unit that the computer account is currently in

## xOfflineDomainJoin
xOfflineDomainJoin resource is a [Single Instance](https://msdn.microsoft.com/en-us/powershell/dsc/singleinstance) resource that can only be used once in a configuration and has following properties:

* IsSingleInstance: Must be set to 'Yes'. Required.
* RequestFile: The full path to the Offline Domain Join request file. Required.

## xScheduledTask
xScheduledTask resource is used to define basic recurring scheduled tasks on the local computer.
Tasks are created to run indefinitly based on the schedule defined.
xScheduledTask has the following properties:

 * TaskName: The name of the task
 * TaskPath: The path to the task - optional, defaults to '\'
 * ActionExecutable: The path to the .exe for this task
 * ActionArguments: The arguments to pass the executable - optional
 * ActionWorkingPath: The working path to specify for the executable - optional
 * ScheduleType: How frequently should this task be executed? Minutes, Hourly or Daily
 * RepeatInterval: How many units (minutes, hours, days) between each run of this task?
 * StartTime: The time of day this task should start at - optional, defaults to '12:00 AM'
 * Ensure: Present if the task should exist, false if it should be removed - optional, defaults to 'Ensure'
 * ExecuteAsCredential: The credential this task should execute as - Optional, defaults to running as 'NT AUTHORITY\SYSTEM'


## Versions

### Unreleased

### 1.8.0.0
* Converted AppVeyor.yml to pull Pester from PSGallery instead of Chocolatey.
* Changed AppVeyor.yml to use default image
* xScheduledTask: Fixed bug with different OS versions returning repeat interval differently

### 1.7.0.0
* Added support for enabling or disabling scheduled tasks
* The Name parameter resolves to $env:COMPUTERNAME when the value is localhost

### 1.6.0.0
* Added the following resources:
    * MSFT_xOfflineDomainJoin resource to join computers to an AD Domain using an Offline Domain Join request file.
    * MSFT_xScheduledTask resource to control scheduled tasks on the local server
* MSFT_xOfflineDomainJoin: Corrected localizedData.DomainAlreadyJoinedhMessage name.
* xComputer: Changed credential generation code in tests to avoid triggering PSSA rule PSAvoidUsingConvertToSecureStringWithPlainText.
             Renamed unit test file to match the name of Resource file.

### 1.5.0.0
* Update Unit tests to use the standard folder structure and test templates.
* Added .gitignore to prevent commit of DSCResource.Tests.

### 1.4.0.0
* Added validation to the Name parameter
* Added the JoinOU parameter which allows you to specify the organizational unit that the computer account will be created in
* Added the CurrentOU read-only property that shows the organizational unit that the computer account is currently in

### 1.3.0
* xComputer
    * Fixed issue with Test-TargetResource when not specifying Domain or Workgroup name
    * Added tests

### 1.2.2

Added types to Get/Set/Test definitions to allow xResourceDesigner validation to succeed

### 1.2

Added functionality to enable moving computer from one domain to another
Modified Test-DscConfiguration logics when testing domain join

### 1.0.0.0

Initial release with the following resources
* xComputer


## Examples
### Change the Name and the Workgroup Name

This configuration will set a machine name and changes the workgroup it is in.

```powershell
configuration Sample_xComputer_ChangeNameAndWorkGroup
{
    param
    (
        [string[]]$NodeName ='localhost',

        [Parameter(Mandatory)]
        [string]$MachineName,

        [Parameter(Mandatory)]
        [string]$WorkGroupName
    )

    #Import the required DSC Resources
    Import-DscResource -Module xComputerManagement

    Node $NodeName
    {
        xComputer NewNameAndWorkgroup
        {
            Name          = $MachineName
            WorkGroupName = $WorkGroupName
        }
    }
}
```

### Switch from a Workgroup to a Domain
This configuration sets the machine name and joins a domain.
Note: this requires a credential.

```powershell
configuration Sample_xComputer_WorkgroupToDomain
{
    param
    (
        [string[]]$NodeName="localhost",

        [Parameter(Mandatory)]
        [string]$MachineName,

        [Parameter(Mandatory)]
        [string]$Domain,

        [Parameter(Mandatory)]
        [pscredential]$Credential
    )

    #Import the required DSC Resources
    Import-DscResource -Module xComputerManagement

    Node $NodeName
    {
        xComputer JoinDomain
        {
            Name          = $MachineName
            DomainName    = $Domain
            Credential    = $Credential  # Credential to join to domain
        }
    }
}


<#****************************
To save the credential in plain-text in the mof file, use the following configuration data

$ConfigData = @{
                 AllNodes = @(
                              @{
                                 NodeName = "localhost"
                                 # Allows credential to be saved in plain-text in the the *.mof instance document.

                                 PSDscAllowPlainTextPassword = $true
                              }
                            )
              }

Sample_xComputer_WorkgroupToDomain -ConfigurationData $ConfigData -MachineName <machineName> -credential (Get-Credential) -Domain <domainName>
****************************#>
```

### Change the Name while staying on the Domain

This example will change the machines name while remaining on the domain.
Note: this requires a credential.

```powershell
function Sample_xComputer_ChangeNameInDomain
{
    param
    (
        [string[]]$NodeName="localhost",

        [Parameter(Mandatory)]
        [string]$MachineName,

        [Parameter(Mandatory)]
        [pscredential]$Credential
    )

    #Import the required DSC Resources
    Import-DscResource -Module xComputerManagement

    Node $NodeName
    {
        xComputer NewName
        {
            Name          = $MachineName
            Credential    = $Credential # Domain credential
        }
    }
}

<#****************************
To save the credential in plain-text in the mof file, use the following configuration data

$ConfigData = @{
                AllNodes = @(
                             @{
                                NodeName = "localhost";

                                # Allows credential to be saved in plain-text in the the *.mof instance document.

                                PSDscAllowPlainTextPassword = $true;
                          }
                 )
            }

Sample_xComputer_ChangeNameInDomain -ConfigurationData $ConfigData -MachineName <machineName>  -Credential (Get-Credential)

*****************************#>
```

### Change the Name while staying on the Workgroup
This example will change the machines name while remaining on the workgroup.

```powershell
function Sample_xComputer_ChangeNameInWorkgroup
{
    param
    (
        [string[]]$NodeName="localhost",

        [Parameter(Mandatory)]
        [string]$MachineName
    )

    #Import the required DSC Resources
    Import-DscResource -Module xComputerManagement

    Node $NodeName
    {
        xComputer NewName
        {
            Name = $MachineName
        }
    }
}
```

### Switch from a Domain to a Workgroup
This example switches the computer from a domain to a workgroup.
Note: this requires a credential.

```powershell
function  Sample_xComputer_DomainToWorkgroup
{
    param
    (
        [string[]]$NodeName="localhost",

        [Parameter(Mandatory)]
        [string]$MachineName,

        [Parameter(Mandatory)]
        [string]$WorkGroup,

        [Parameter(Mandatory)]
        [pscredential]$Credential
    )

    #Import the required DSC Resources
    Import-DscResource -Module xComputerManagement

    Node $NodeName
    {
        xComputer JoinWorkgroup
        {
            Name          = $MachineName
            WorkGroupName = $WorkGroup
            Credential    = $Credential # Credential to unjoin from domain
        }
    }
}

<#****************************
To save the credential in plain-text in the mof file, use the following configuration data

$ConfigData = @{
                AllNodes = @(
                             @{
                                NodeName = "localhost";
                                # Allows credential to be saved in plain-text in the the *.mof instance document.

                                PSDscAllowPlainTextPassword = $true;
                              }
                           )
                }

Sample_xComputer_DomainToWorkgroup -ConfigurationData $ConfigData -MachineName <machineName> -credential (Get-Credential) -WorkGroup <workgroupName>
****************************#>
```

### Join a Domain using an ODJ Request File
This example will join the computer to a domain using the ODJ request file C:\ODJ\ODJRequest.txt.

```powershell
configuration Sample_xOfflineDomainJoin
{
    param
    (
        [string[]]$NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName xComputerManagement

    Node $NodeName
    {
        xOfflineDomainJoin ODJ
        {
          RequestFile = 'C:\ODJ\ODJRequest.txt'
          IsSingleInstance = 'Yes'
        }
    }
}

Sample_xOfflineDomainJoin
Start-DscConfiguration -Path Sample_xOfflineDomainJoin -Wait -Verbose -Force
```

### Run a PowerShell script every 15 minutes on a server
This example will create a scheduled task that will call PowerShell.exe every 15 minutes to run a script saved locally.
The script will be called as the local system account

```powershell
configuration Sample_xScheduledTask
{
    param
    (
        [string[]]$NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName xComputerManagement

    Node $NodeName
    {
        xScheduledTask MaintenanceScriptExample
        {
          TaskName = "Custom maintenance tasks"
          ActionExecutable = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
          ActionArguments = "-File `"C:\scripts\my custom script.ps1`""
          ScheduleType = "Minutes"
          RepeatInterval = 15
        }
    }
}

Sample_xScheduledTask
Start-DscConfiguration -Path Sample_xScheduledTask -Wait -Verbose -Force
```


## Contributing
Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).
