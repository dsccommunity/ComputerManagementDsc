# xComputerManagement

The **xComputerManagement** module contains the following resources:

* xComputer - allows you to configure a computer by changing its name and
  modifying its domain or workgroup.
* xOfflineDomainJoin - allows you to join computers to an AD Domain using
  an [Offline Domain Join](https://technet.microsoft.com/en-us/library/offline-domain-join-djoin-step-by-step(v=ws.10).aspx)
  request file.
* xScheduledTask - used to define basic recurring scheduled tasks on the
  local computer.
* xPowerPlan - specifies a power plan to activate.
* xVirtualMemory - used to set the properties of the paging file on the
  local computer.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/)
or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any
additional questions or comments.

## Branches

### master

[![Build status](https://ci.appveyor.com/api/projects/status/cg28qxeco39wgo9l/branch/master?svg=true)](https://ci.appveyor.com/project/PowerShell/xsqlserver/branch/master)
[![codecov](https://codecov.io/gh/PowerShell/xComputerManagement/branch/master/graph/badge.svg)](https://codecov.io/gh/PowerShell/xComputerManagement/branch/master)

This is the branch containing the latest release - no contributions should be made
directly to this branch.

### dev

[![Build status](https://ci.appveyor.com/api/projects/status/cg28qxeco39wgo9l/branch/dev?svg=true)](https://ci.appveyor.com/project/PowerShell/xComputerManagement/branch/dev)
[![codecov](https://codecov.io/gh/PowerShell/xComputerManagement/branch/dev/graph/badge.svg)](https://codecov.io/gh/PowerShell/xComputerManagement/branch/dev)

This is the development branch to which contributions should be proposed by contributors
as pull requests. This development branch will periodically be merged to the master
branch, and be released to [PowerShell Gallery](https://www.powershellgallery.com/).

## Contributing

Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).

## xComputer

xComputer resource has following properties:

* Name: The desired computer name.
* DomainName: The name of the domain to join.
* JoinOU: The distinguished name of the organizational unit that the computer
  account will be created in.
* WorkGroupName: The name of the workgroup.
* Credential: Credential to be used to join a domain.
* UnjoinCredential: Credential to be used to leave a domain.
* CurrentOU: A read-only property that specifies the organizational unit that
  the computer account is currently in.
* Description: The value assigned here will be set as the local computer description.

### xComputer Examples

* [Set the Name and the Workgroup Name](/Examples/xComputer/1-RenameComputerAndSetWorkgroup.ps1)
* [Switch from a Workgroup to a Domain](/Examples/xComputer/2-JoinDomain.ps1)
* [Set the Name while staying on the Domain](/Examples/xComputer/3-RenameComputerInDomain.ps1)
* [Set the Name while staying on the Workgroup](/Examples/xComputer/4-RenameComputerInWorkgroup.ps1)
* [Switch from a Domain to a Workgroup](/Examples/xComputer/5-UnjoinDomainAndJoinWorkgroup.ps1)
* [Set a Description for the Workstation](/Examples/xComputer/6-SetComputerDescriptionInWorkgroup.ps1)

## xOfflineDomainJoin

xOfflineDomainJoin resource is a [Single Instance](https://msdn.microsoft.com/en-us/powershell/dsc/singleinstance)
resource that can only be used once in a configuration and has following properties:

* IsSingleInstance: Must be set to 'Yes'. Required.
* RequestFile: The full path to the Offline Domain Join request file. Required.

### xOfflineDomainJoin Examples

* [Join a Domain using an ODJ Request File](/Examples/xOfflineDomainJoin/1-JoinDomainUsingODJBlob.ps1)

## xScheduledTask

xScheduledTask resource is used to define basic recurring scheduled tasks on the
local computer.
Tasks are created to run based on the schedule defined.
xScheduledTask has the following properties:

* TaskName: The name of the task
* TaskPath: The path to the task - defaults to the root directory
* Description: The task description
* ActionExecutable: The path to the .exe for this task
* ActionArguments: The arguments to pass the executable
* ActionWorkingPath: The working path to specify for the executable
* ScheduleType: When should the task be executed
  ("Once", "Daily", "Weekly", "AtStartup", "AtLogOn")
* RepeatInterval: How many units (minutes, hours, days) between each run of this
  task?
* StartTime: The time of day this task should start at - defaults to 12:00 AM.
  Not valid for AtLogon and AtStartup tasks
* Ensure: Present if the task should exist, false if it should be removed - defaults
  to Present.
* Enable: True if the task should be enabled, false if it should be
  disabled
* ExecuteAsCredential: The credential this task should execute as. If not
  specified defaults to running as the local system account
* DaysInterval: Specifies the interval between the days in the schedule. An
  interval of 1 produces a daily schedule. An interval of 2 produces an
  every-other day schedule.
* RandomDelay: Specifies a random amount of time to delay the start time of the
  trigger. The delay time is a random time between the time the task triggers
  and the time that you specify in this setting.
* RepetitionDuration: Specifies how long the repetition pattern repeats after
  the task starts. May be set to `Indefinitely` to specify an indefinite duration.
* DaysOfWeek: Specifies an array of the days of the week on which Task Scheduler
  runs the task.
* WeeksInterval: Specifies the interval between the weeks in the schedule. An
  interval of 1 produces a weekly schedule. An interval of 2 produces an
  every-other week schedule.
* User: Specifies the identifier of the user for a trigger that starts a task
  when a user logs on.
* DisallowDemandStart: Indicates whether the task is prohibited to run on demand
  or not. Defaults to $false
* DisallowHardTerminate: Indicates whether the task is prohibited to be terminated
  or not. Defaults to $false
* Compatibility: The task compatibility level. Defaults to Vista. Possible
  values: "AT","V1","Vista","Win7","Win8"
* AllowStartIfOnBatteries: Indicates whether the task should start if the machine
  is on batteries or not. Defaults to $false
* Hidden: Indicates that the task is hidden in the Task Scheduler UI. Defaults
  to $false
* RunOnlyIfIdle: Indicates that Task Scheduler runs the task only when the
  computer is idle.
* IdleWaitTimeout: Specifies the amount of time that Task Scheduler waits for an
  idle condition to occur. DateTime ;
* NetworkName: Specifies the name of a network profile that Task Scheduler uses
  to determine if the task can run. The Task Scheduler UI uses this setting for
  display purposes. Specify a network name if you specify theRunOnlyIfNetworkAvailable
  parameter.
* DisallowStartOnRemoteAppSession: Indicates that the task does not start if the
  task is triggered to run in a Remote Applications Integrated Locally (RAIL) session.
* StartWhenAvailable: Indicates that Task Scheduler can start the task at any
  time after its scheduled time has passed.
* DontStopIfGoingOnBatteries: Indicates that the task does not stop if the
  computer switches to battery power.
* WakeToRun: Indicates that Task Scheduler wakes the computer before it runs the
  task.
* IdleDuration: Specifies the amount of time that the computer must be in an idle
  state before Task Scheduler runs the task.
* RestartOnIdle: Indicates that Task Scheduler restarts the task when the computer
  cycles into an idle condition more than once.
* DontStopOnIdleEnd: Indicates that Task Scheduler does not terminate the task if
  the idle condition ends before the task is completed.
* ExecutionTimeLimit: Specifies the amount of time that Task Scheduler is allowed
  to complete the task.
* MultipleInstances: Specifies the policy that defines how Task Scheduler handles
  multiple instances of the task. Possible values: "IgnoreNew","Parallel","Queue"
* Priority: Specifies the priority level of the task. Priority must be an integer
  from 0 (highest priority) to 10 (lowest priority). The default value is 7.
  Priority levels 7 and 8 are used for background tasks. Priority levels 4, 5,
  and 6 are used for interactive tasks.
* RestartCount: Specifies the number of times that Task Scheduler attempts to
  restart the task.
* RestartInterval: Specifies the amount of time that Task Scheduler attempts to
  restart the task.
* RunOnlyIfNetworkAvailable: Indicates that Task Scheduler runs the task only
  when a network is available. Task Scheduler uses the NetworkID parameter and
  NetworkName parameter that you specify in this cmdlet to determine if the
  network is available.

### xScheduledTask Examples

* [Create a task that starts PowerShell once every 15 minutes from 00:00 for 8 hours](/Examples/xScheduledTask/1-CreateScheduledTaskOnce.ps1)
* [Create a task that starts PowerShell daily every 15 minutes from 00:00 for 8 hours](/Examples/xScheduledTask/2-CreateScheduledTaskDaily.ps1)
* [Create a task that starts PowerShell daily every 15 minutes from 00:00 indefinitely](/Examples/xScheduledTask/3-CreateScheduledTasksDailyIndefinitely.ps1)
* [Create a task that starts PowerShell weekly on Monday, Wednesday and Saturday every 15 minutes from 00:00 for 8 hours](/Examples/xScheduledTask/4-CreateScheduledTasksWeekly.ps1)
* [Create a task that starts PowerShell at logon and runs every 15 minutes from 00:00 for 8 hours](/Examples/xScheduledTask/5-CreateScheduledTasksAtLogon.ps1)
* [Create a task that starts PowerShell at startup and runs every 15 minutes from 00:00 for 8 hours](/Examples/xScheduledTask/6-CreateScheduledTasksAtStartup.ps1)
* [Run a PowerShell script every 15 minutes for 4 days on a server](/Examples/xScheduledTask/7-RunPowerShellTaskEvery15Minutes.ps1)
* [Run a PowerShell script every 15 minutes indefinitely on a server](/Examples/xScheduledTask/8-RunPowerShellTaskEvery15MinutesIndefinitely.ps1)

## xPowerPlan

xPowerPlan resource has following properties:

* IsSingleInstance: Specifies the resource is a single instance, the value must
  be 'Yes'.
* Name: The name of the power plan to activate.

### xPowerPlan Examples

* [Sets Active Power Plan to the High Performance plan](/Examples/xPowerPlan/1-SetPowerPlan.ps1)

## xVirtualMemory

xVirtualMemory resource is used to set the properties of the paging file on the
local computer.
xVirtualMemory has the following properties:

* Type: The type of the paging settings, mandatory, out of "AutoManagePagingFile",
  "CustomSize","SystemManagedSize","NoPagingFile"
* Drive: The drive to enable paging on, mandatory. Ignored for "AutoManagePagingFile"
* InitialSize: The initial size in MB of the paging file. Ignored for Type
  "AutoManagePagingFile" and "SystemManagedSize"
* MaximumSize: The maximum size in MB of the paging file. Ignored for Type
  "AutoManagePagingFile" and "SystemManagedSize"

### xVirtualMemory Examples

* [Set Page File to be 2GB on C Drive](/Examples/xVirtualMemory/1-SetVirtualMemory.ps1)

## Versions

### Unreleased

### 3.1.0.0

* xOfflineDomainJoin:
  * Updated to meet HQRM guidelines.

### 3.0.0.0

* xComputer: Added parameter to set the local computer description along with documentation
 and unit tests for this change.
* BREAKING CHANGE: xScheduledTask:
  * Converted all Interval/Duration type parameters over to be string format
    to prevent the Timezone the MOF file was created in from being stored.
    This is to fix problems where MOF files are created in one timezone but
    deployed nodes to a different timezone - See [Issue #85](https://github.com/PowerShell/xComputerManagement/issues/85)
  * Added ConvertTo-TimeSpanFromScheduledTaskString function and refactored
    to reduce code duplication.
  * Added support for setting repetition duration to `Indefinitely`.
* xComputer:
  * Moved strings to localization file.
  * Updated to meet HQRM guidelines.
* xVirtualMemory:
  * Refactored shared common code into new utility functions to
    reduce code duplication and improve testability.
  * Moved strings into localizable strings file.
  * Converted calls to `throw` to use `New-InvalidOperationException`
    in CommonResourceHelper.
  * Improved unit test coverage.
  * Updated to meet HQRM guidelines.

### 2.1.0.0

* xComputer: Changed comparison that validates if we are in the correct AD
  Domain to work correctly if FQDN wasn't used.
* Updated AppVeyor.yml to use AppVeyor.psm1 module in DSCResource.Tests.
* Removed Markdown.md errors.
* Added CodeCov.io support.
* xScheduledTask
  * Fixed incorrect TaskPath handling - [Issue #45](https://github.com/PowerShell/xComputerManagement/issues/45)
* Change examples to meet HQRM standards and optin to Example validation
  tests.
* Replaced examples in README.MD to links to Example files.
* Added the VS Code PowerShell extension formatting settings that cause PowerShell
  files to be formatted as per the DSC Resource kit style guidelines - [Issue #91](https://github.com/PowerShell/xComputerManagement/issues/91).
* Opted into Common Tests 'Validate Module Files' and 'Validate Script Files'.
* Converted files with UTF8 with BOM over to UTF8 - fixes [Issue #90](https://github.com/PowerShell/xComputerManagement/issues/90).
* Updated Year to 2017 in License and Manifest - fixes [Issue #87](https://github.com/PowerShell/xComputerManagement/issues/87).
* Added .github support files - fixes [Issue #88](https://github.com/PowerShell/xComputerManagement/issues/88):
  * CONTRIBUTING.md
  * ISSUE_TEMPLATE.md
  * PULL_REQUEST_TEMPLATE.md
* Resolved all PSScriptAnalyzer warnings and style guide warnings.
* xOfflineDomainJoin:
  * Changed to use CommonResourceHelper to load localization strings.
  * Renamed en-US to be correct case so that localization strings can be loaded.
  * Suppress PSScriptAnalyzer rule PSAvoidGlobalVars for
    `$global:DSCMachineStatus = 1`.
* xComputer:
  * Suppress PSScriptAnalyzer rule PSAvoidGlobalVars for
    `$global:DSCMachineStatus = 1`.
* xVirtualMemory:
  * Suppress PSScriptAnalyzer rule PSAvoidGlobalVars for
    `$global:DSCMachineStatus = 1`.

### 2.0.0.0

* Updated resources
  * BREAKING CHANGE: xScheduledTask: Added nearly all available parameters for tasks
* xVirtualMemory:
  * Fixed failing tests.

### 1.10.0.0

* Added resources:
  * xVirtualMemory

### 1.9.0.0

* Added resources
  * xPowerPlan

### 1.8.0.0

* Converted AppVeyor.yml to pull Pester from PSGallery instead of
  Chocolatey.
* Changed AppVeyor.yml to use default image
* xScheduledTask: Fixed bug with different OS versions returning repeat interval
  differently

### 1.7.0.0

* Added support for enabling or disabling scheduled tasks
* The Name parameter resolves to $env:COMPUTERNAME when the value is localhost

### 1.6.0.0

* Added the following resources:
  * MSFT_xOfflineDomainJoin resource to join computers to an AD Domain using an
    Offline Domain Join request file.
  * MSFT_xScheduledTask resource to control scheduled tasks on the local server
* MSFT_xOfflineDomainJoin: Corrected localizedData.DomainAlreadyJoinedhMessage name.
* xComputer: Changed credential generation code in tests to avoid triggering
  PSSA rule PSAvoidUsingConvertToSecureStringWithPlainText.
  Renamed unit test file to match the name of Resource file.

### 1.5.0.0

* Update Unit tests to use the standard folder structure and test templates.
* Added .gitignore to prevent commit of DSCResource.Tests.

### 1.4.0.0

* Added validation to the Name parameter
* Added the JoinOU parameter which allows you to specify the organizational unit
  that the computer account will be created in
* Added the CurrentOU read-only property that shows the organizational unit that
  the computer account is currently in

### 1.3.0

* xComputer
  * Fixed issue with Test-TargetResource when not specifying Domain or
    Workgroup name
  * Added tests

### 1.2.2

* Added types to Get/Set/Test definitions to allow xResourceDesigner validation
  to succeed

### 1.2

* Added functionality to enable moving computer from one domain to another
* Modified Test-DscConfiguration logics when testing domain join

### 1.0.0.0

* Initial release with the following resources:
  * xComputer
