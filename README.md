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
 * TaskPath: The path to the task - defaults to the root directory
 * Description: The task description
 * ActionExecutable: The path to the .exe for this task
 * ActionArguments: The arguments to pass the executable
 * ActionWorkingPath: The working path to specify for the executable
 * ScheduleType: When should the task be executed ("Once", "Daily", "Weekly", "AtStartup", "AtLogOn")
 * RepeatInterval: How many units (minutes, hours, days) between each run of this task?
 * StartTime: The time of day this task should start at - defaults to 12:00 AM. Not valid for AtLogon and AtStartup tasks
 * Ensure: Present if the task should exist, false if it should be removed
 * Enable: True if the task should be enabled, false if it should be disabled
 * ExecuteAsCredential: The credential this task should execute as. If not specified defaults to running as the local system account
 * DaysInterval: Specifies the interval between the days in the schedule. An interval of 1 produces a daily schedule. An interval of 2 produces an every-other day schedule.
 * RandomDelay: Specifies a random amount of time to delay the start time of the trigger. The delay time is a random time between the time the task triggers and the time that you specify in this setting.
 * RepetitionDuration: Specifies how long the repetition pattern repeats after the task starts.
 * DaysOfWeek: Specifies an array of the days of the week on which Task Scheduler runs the task.
 * WeeksInterval: Specifies the interval between the weeks in the schedule. An interval of 1 produces a weekly schedule. An interval of 2 produces an every-other week schedule.
 * User: Specifies the identifier of the user for a trigger that starts a task when a user logs on.
 * DisallowDemandStart: Indicates whether the task is prohibited to run on demand or not. Defaults to $false
 * DisallowHardTerminate: Indicates whether the task is prohibited to be terminated or not. Defaults to $false
 * Compatibility: The task compatibility level. Defaults to Vista. Possible values: "AT","V1","Vista","Win7","Win8"
 * AllowStartIfOnBatteries: Indicates whether the task should start if the machine is on batteries or not. Defaults to $false
 * Hidden: Indicates that the task is hidden in the Task Scheduler UI. Defaults to $false
 * RunOnlyIfIdle: Indicates that Task Scheduler runs the task only when the computer is idle.
 * IdleWaitTimeout: Specifies the amount of time that Task Scheduler waits for an idle condition to occur. DateTime ;
 * NetworkName: Specifies the name of a network profile that Task Scheduler uses to determine if the task can run. The Task Scheduler UI uses this setting for display purposes. Specify a network name if you specify the RunOnlyIfNetworkAvailable parameter.
 * DisallowStartOnRemoteAppSession: Indicates that the task does not start if the task is triggered to run in a Remote Applications Integrated Locally (RAIL) session.
 * StartWhenAvailable: Indicates that Task Scheduler can start the task at any time after its scheduled time has passed.
 * DontStopIfGoingOnBatteries: Indicates that the task does not stop if the computer switches to battery power.
 * WakeToRun: Indicates that Task Scheduler wakes the computer before it runs the task.
 * IdleDuration: Specifies the amount of time that the computer must be in an idle state before Task Scheduler runs the task.
 * RestartOnIdle: Indicates that Task Scheduler restarts the task when the computer cycles into an idle condition more than once.
 * DontStopOnIdleEnd: Indicates that Task Scheduler does not terminate the task if the idle condition ends before the task is completed.
 * ExecutionTimeLimit: Specifies the amount of time that Task Scheduler is allowed to complete the task.
 * MultipleInstances: Specifies the policy that defines how Task Scheduler handles multiple instances of the task. Possible values: "IgnoreNew","Parallel","Queue"
 * Priority: Specifies the priority level of the task. Priority must be an integer from 0 (highest priority) to 10 (lowest priority). The default value is 7. Priority levels 7 and 8 are used for background tasks. Priority levels 4, 5, and 6 are used for interactive tasks.
 * RestartCount: Specifies the number of times that Task Scheduler attempts to restart the task.
 * RestartInterval: Specifies the amount of time that Task Scheduler attempts to restart the task.
 * RunOnlyIfNetworkAvailable: Indicates that Task Scheduler runs the task only when a network is available. Task Scheduler uses the NetworkID parameter and NetworkName parameter that you specify in this cmdlet to determine if the network is available.

## xPowerPlan
xPowerPlan resource has following properties:

 * IsSingleInstance: Specifies the resource is a single instance, the value must be 'Yes'.
 * Name: The name of the power plan to activate.
 
## xVirtualMemory

xVirtualMemory resource is used to set the properties of the paging file on the local computer.
xVirtualMemory has the following properties:

* Type: The type of the paging settings, mandatory, out of "AutoManagePagingFile","CustomSize","SystemManagedSize","NoPagingFile"
* Drive: The drive to enable paging on, mandatory. Ignored for "AutoManagePagingFile"
* InitialSize: The initial size in MB of the paging file. Ignored for Type "AutoManagePagingFile" and "SystemManagedSize"
* MaximumSize: The maximum size in MB of the paging file. Ignored for Type "AutoManagePagingFile" and "SystemManagedSize"

## Versions

### Unreleased

### 2.0.0.0
* Updated resources
  - BREAKING CHANGE: xScheduledTask: Added nearly all available parameters for tasks

### 1.10.0.0
* Added resources
  - xVirtualMemory

### 1.9.0.0
* Added resources
  - xPowerPlan

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
          ScheduleType = 'Once'
          RepeatInterval = [datetime]::Today.AddMinutes(15)
          RepetitionDuration = [datetime]::Today.AddHours(10)
        }
    }
}

Sample_xScheduledTask
Start-DscConfiguration -Path Sample_xScheduledTask -Wait -Verbose -Force
```


## Contributing
Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).
