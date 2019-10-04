# Versions

## Unreleased

- ComputerManagementDsc:
  - Update psd1 description - Fixes [Issue #269](https://github.com/PowerShell/ComputerManagementDsc/issues/269).
- Fix minor style issues with missing spaces between `param` statements and '('.
- SmbServerConfiguration:
  - New resource for configuring the SMB Server settings.
  - Added examples for SMB Server Configuration.
- Minor corrections to CHANGELOG.MD.
- ScheduledTask:
  - Fixed bug when description has any form of whitespace at beginning or
    end the resource would not go into state - Fixes [Issue #258](https://github.com/PowerShell/ComputerManagementDsc/issues/258).

## 7.0.0.0

- ScheduledTask:
  - Better compatibility with Group LogonType
    when passing BuiltIn groups through ExecuteAsCredential
    - Primary use case is 'BUILTIN\Users'
    - Use the ExecuteAsCredential property to pass the username
      The PSCredential needs a non-null that is ignored
  - Delay property not handled properly on AtLogon and AtStartup trigger - Fixes
    [Issue #230](https://github.com/PowerShell/ComputerManagementDsc/issues/230).
  - Changed `Get-ScheduledTask` calls to `ScheduledTasks\Get-ScheduledTask` to
    avoid name clash with `Carbon` module. Fixes [Issue #248](https://github.com/PowerShell/ComputerManagementDsc/issues/248).
  - Cast `MultipleInstances` value returned by `Get-TargetResource` to `string` -
    fixes [Issue #255](https://github.com/PowerShell/ComputerManagementDsc/issues/255).
- PendingReboot:
  - Migrated xPendingReboot from [xPendingReboot](https://github.com/PowerShell/xPendingReboot)
    and renamed to PendingReboot.
  - Converted to meet HQRM guidelines - Fixes [Issue #12](https://github.com/PowerShell/xPendingReboot/issues/12).
  - Changed `SkipCcmClientSDK` parameter to default to `$true` - Fixes [Issue #13](https://github.com/PowerShell/xPendingReboot/issues/13).
  - Fixed `Test-TargetResource` so that if ConfigMgr requires a reboot then
    the pending reboot will be set - Fixes [Issue #26](https://github.com/PowerShell/xPendingReboot/issues/26).
  - Refactored `Test-TargetResource` to reduce code duplication and move to a
    data driven design.
  - Refactored `Get-TargetResource` by adding a new function `Get-PendingRebootState`
    so that `Test-TargetResource` no longer needed to use `Get-TargetResource`. This
    eliminated the need to include write parameters in `Get-TargetResource`.
  - Converted the call to `Invoke-WmiMethod` to `Invoke-CimMethod`.
  - Deleted the code that removes the `regRebootLocations` variable at the end of
    the resource as it appears to serve no purpose.
- Correct all tests to meet Pester 4.0 standards.
- RemoteDesktopAdmin:
  - New resource for configuring Remote Desktop for Administration - fixes
    [Issue #224](https://github.com/PowerShell/ComputerManagementDsc/issues/224).
- Updated common function `Test-DscParameterState` to support ordered comparison
  of arrays by copying function and tests from `NetworkingDsc` - fixes [Issue #250](https://github.com/PowerShell/ComputerManagementDsc/issues/250).
- BREAKING CHANGE: ScheduledTask:
  - Correct output type of `DaysInterval`,`StartTime`,`WeeksDaysOfWeek`,
    and `WeeksInterval` parameters from `Get-TargetResource` to match MOF.
  - Refactored `Get-TargetResource` to remove parameters that
    are not key or required - fixes [Issue #249](https://github.com/PowerShell/ComputerManagementDsc/issues/249).
  - Added function `Test-DateStringContainsTimeZone` to determine if a string
    containing a date time includes a time zone.
  - Enable verbose preference to be passed through to `Test-DscParameterState`.
  - Changed `Test-TargetResource` so that `StartTime` is only compared for
    trigger types `Daily`,`Weekly` or `Once`.
- Fix minor style issues in statement case.

## 6.5.0.0

- Computer:
  - Fix for 'directory service is busy' error when joining a domain and renaming
    a computer when JoinOU is specified - Fixes [Issue #221](https://github.com/PowerShell/ComputerManagementDsc/issues/221).
- Added new resource SmbShare
  - Moved and improved from deprecated module xSmbShare.
- Changes to ComputerManagementDsc.Common
  - Updated Test-DscParameterState so it now can compare zero item
    collections (arrays).
- Changes to WindowsEventLog
  - Minor style guideline cleanup.
- Opt-in to common test to validate localization. Fixed localization strings
  in resources - Fixes [Issue #217](https://github.com/PowerShell/ComputerManagementDsc/issues/217).
- PowerShellExecutionPolicy:
  - Removed `SupportsShouldProcess` as it cannot be used with DSC - Fixes
    [Issue #219](https://github.com/PowerShell/ComputerManagementDsc/issues/219).
- Combined all ComputerManagementDsc.ResourceHelper module functions into
  ComputerManagementDsc.Common module - Fixes [Issue #218](https://github.com/PowerShell/ComputerManagementDsc/issues/218).
  - Minor code cleanup against style guideline.
  - Remove code from `New-InvalidOperationException` because it was a
    code path that could never could be used due to the parameter
    validation preventing the helper function being called that way.
  - Updated all `Get-LocalizationData` to latest version from
    [DSCResource.Template](https://github.com/PowerShell/DSCResource.Template).
  - Fixed an issue with the helper function `Test-IsNanoServer` that
    prevented it to work. Though the helper function is not used, so this
    issue was not caught until now when unit tests was added.
  - Improved code coverage.

## 6.4.0.0

- ScheduledTask:
  - IdleWaitTimeout returned from Get-TargetResource always null - Fixes [Issue #186](https://github.com/PowerShell/ComputerManagementDsc/issues/186).
  - Added BuiltInAccount Property to allow running task as one of the build in
    service accounts - Fixes [Issue #130](https://github.com/PowerShell/ComputerManagementDsc/issues/130).
- Refactored module folder structure to move resource to root folder of
  repository and remove test harness - fixes [Issue #188](https://github.com/PowerShell/ComputerManagementDsc/issues/188).
- Added a CODE\_OF\_CONDUCT.md with the same content as in the README.md and
  linked to it from README.MD instead.
- Updated test header for all unit tests to version 1.2.4.
- Updated test header for all integration to version 1.3.3.
- Enabled example publish to PowerShell Gallery by adding `gallery_api`
  environment variable to `AppVeyor.yml`.

## 6.3.0.0

- Correct PSSA custom rule violations - fixes [Issue #209](https://github.com/PowerShell/ComputerManagementDsc/issues/209).
- Correct long example filenames for PowerShellExecutionPolicy examples.
- Opted into Common Tests 'Required Script Analyzer Rules',
  'Flagged Script Analyzer Rules', 'New Error-Level Script Analyzer Rules'
  'Custom Script Analyzer Rules' and 'Relative Path Length' -
  fixes [Issue #152](https://github.com/PowerShell/ComputerManagementDsc/issues/152).
- PowerPlan:
  - Added support to specify the desired power plan either as name or guid.
    Fixes [Issue #59](https://github.com/PowerShell/ComputerManagementDsc/issues/59)
  - Changed the resource so it uses Windows APIs instead of WMI/CIM
    (Workaround for Server 2012R2 Core, Nano Server, Server 2019 and Windows 10).
    Fixes [Issue #155](https://github.com/PowerShell/ComputerManagementDsc/issues/155)
    and [Issue #65](https://github.com/PowerShell/ComputerManagementDsc/issues/65)

## 6.2.0.0

- WindowsEventLog:
  - Migrated the xWinEventLog from [xWinEventLog](https://github.com/PowerShell/xWinEventLog)
    and renamed to WindowsEventLog.
  - Moved strings in localization file.
  - LogMode is now set with Limit-EventLog,
  - Fixes [Issue #18](https://github.com/PowerShell/ComputerManagementDsc/issues/18).
- Updated examples to format required for publishing to PowerShell Gallery - fixes
  [Issue #206](https://github.com/PowerShell/ComputerManagementDsc/issues/206).
- Opted into Common Tests 'Validate Example Files To Be Published' and
  'Validate Markdown Links'.

## 6.1.0.0

- Updated LICENSE file to match the Microsoft Open Source Team standard.
  Fixes [Issue #197](https://github.com/PowerShell/ComputerManagementDsc/issues/197).
- Explicitly removed extra hidden files from release package

## 6.0.0.0

- ScheduledTask:
  - Added support for Group Managed Service Accounts, implemented using the ExecuteAsGMSA
    parameter. Fixes [Issue #111](https://github.com/PowerShell/ComputerManagementDsc/issues/111)
  - Added support to set the Synchronize Across Time Zone option. Fixes [Issue #109](https://github.com/PowerShell/ComputerManagementDsc/issues/109)
- Added .VSCode settings for applying DSC PSSA rules - fixes [Issue #189](https://github.com/PowerShell/ComputerManagementDsc/issues/189).
- BREAKING CHANGE: PowerPlan:
  - Added IsActive Read-Only Property - Fixes [Issue #171](https://github.com/PowerShell/ComputerManagementDsc/issues/171).
  - InActive power plans are no longer returned with their Name set to null.
    Now, the name is always returned and the Read-Only property of IsActive
    is set accordingly.

## 5.2.0.0

- PowershellExecutionPolicy:
  - Updated to meet HQRM guidelines.
  - Migrated the xPowershellExecutionPolicy from [xPowershellExecutionPolicy](https://github.com/PowerShell/xPowerShellExecutionPolicy)
    and renamed to PowershellExecutionPolicy.
  - Moved strings to localization file.
- Changed the scope from Global to Script in MSFT_ScheduledTask.Integration.Tests.ps1
- Changed the scope from Global to Script ComputerManagementDsc.Common.Tests.ps1
- ScheduledTask:
  - Added support for event based triggers, implemented using the ScheduleType OnEvent
    fixes [Issue #167](https://github.com/PowerShell/ComputerManagementDsc/issues/167)

## 5.1.0.0

- TimeZone:
  - Migrated xTimeZone resource from [xTimeZone](https://github.com/PowerShell/xTimeZone)
    and renamed to TimeZone - fixes [Issue #157](https://github.com/PowerShell/ComputerManagementDsc/issues/157).
- Moved Test-Command from ComputerManagementDsc.ResourceHelper to
  ComputerManagementDsc.Common module to match what TimeZone requires.
  It was not exported in ComputerManagementDsc.ResourceHelper and not
  used.
- Add `server` parameter to `Computer` resource - fixes [Issue #161](https://github.com/PowerShell/ComputerManagementDsc/issues/161)

## 5.0.0.0

- BREAKING CHANGE:
  - Renamed ComputerManagement to ComputerManagementDsc - fixes [Issue #119](https://github.com/PowerShell/ComputerManagementDsc/issues/119).
  - Changed all MSFT\_xResourceName to MSFT\_ResourceName.
  - Updated DSCResources, Examples, Modules and Tests with new naming.
  - Updated Year to 2018 in License and Manifest.
  - Updated README.md from xComputerManagement to ComputerManagementDsc.
- OfflineDomainJoin:
  - Cleaned up spacing in strings file to make consistent with other
    resources.
- VirtualMemory:
  - Converted strings to single quotes in integration test.

## 4.1.0.0

- xScheduledTask:
  - Update existing Scheduled Task using SetScheduleTask
    instead of UnRegister/Register - See [Issue #134](https://github.com/PowerShell/xComputerManagement/issues/134).
- Fix master branch AppVeyor badge link URL in README.MD - See [Issue #140](https://github.com/PowerShell/xComputerManagement/issues/140).
- Fix deletion of scheduled task with unknown or empty task trigger.
  Get-TargetResource returns an empty ScheduleType string if the task
  trigger is empty or unknown - See [Issue
  #137](https://github.com/PowerShell/xComputerManagement/issues/137).
- Added dependency information for xScheduledTask to README.MD.

## 4.0.0.0

- BREAKING CHANGE: xScheduledTask:
  - Breaking change because `Get-TargetResource` no longer outputs
    `ActionExecutable` and `ScheduleType` properties when the scheduled
    task does not exist. It will also include `TaskPath` in output when
    scheduled task does not exist.
- xScheduledTask:
  - Add support to disable built-in scheduled tasks - See [Issue #74](https://github.com/PowerShell/xComputerManagement/issues/74).
  - Fix unit test mocked schedule task object structure.
  - Fix error message when trigger type is unknown - See [Issue #121](https://github.com/PowerShell/xComputerManagement/issues/121).
  - Moved strings into separate strings file.
  - Updated to meet HQRM guidelines.
- xComputer:
  - Resolved bug in Get-ComputerDomain where LocalSystem doesn't have
    rights to the domain.
- Updated tests to meet Pester V4 guidelines - See [Issue #106](https://github.com/PowerShell/xComputerManagement/issues/106).
- Converted module to use auto documentation format.

## 3.2.0.0

- xScheduledTask:
  - Enable Execution Time Limit of task to be set to indefinite
    by setting `ExecutionTimeLimit` to '00:00:00' - See [Issue #115](https://github.com/PowerShell/xComputerManagement/issues/115).
- xPowerPlan:
  - Updated to meet HQRM guidelines.
  - Converted calls to `throw` to use `New-InvalidOperationException`
    in CommonResourceHelper.
- Move Common Resource Helper functions into modules folder.
- Changed resources to use Common Resource Helper functions.
- Moved strings for Common Resource Helper functions into separate
  strings file.
- Added unit tests for Common Helper functions.

## 3.1.0.0

- xOfflineDomainJoin:
  - Updated to meet HQRM guidelines.
- xScheduledTask:
  - Applied autoformatting to examples to improve readability.
  - Added LogonType and RunLevel parameters for controlling
    task execution.
  - Correct `Assert-VerifiableMocks` to `Assert-VerifiableMock`

## 3.0.0.0

- xComputer: Added parameter to set the local computer description along with documentation
 and unit tests for this change.
- BREAKING CHANGE: xScheduledTask:
  - Converted all Interval/Duration type parameters over to be string format
    to prevent the Timezone the MOF file was created in from being stored.
    This is to fix problems where MOF files are created in one timezone but
    deployed nodes to a different timezone - See [Issue #85](https://github.com/PowerShell/xComputerManagement/issues/85)
  - Added ConvertTo-TimeSpanFromScheduledTaskString function and refactored
    to reduce code duplication.
  - Added support for setting repetition duration to `Indefinitely`.
- xComputer:
  - Moved strings to localization file.
  - Updated to meet HQRM guidelines.
- xVirtualMemory:
  - Refactored shared common code into new utility functions to
    reduce code duplication and improve testability.
  - Moved strings into localizable strings file.
  - Converted calls to `throw` to use `New-InvalidOperationException`
    in CommonResourceHelper.
  - Improved unit test coverage.
  - Updated to meet HQRM guidelines.

## 2.1.0.0

- xComputer: Changed comparison that validates if we are in the correct AD
  Domain to work correctly if FQDN wasn't used.
- Updated AppVeyor.yml to use AppVeyor.psm1 module in DSCResource.Tests.
- Removed Markdown.md errors.
- Added CodeCov.io support.
- xScheduledTask
  - Fixed incorrect TaskPath handling - [Issue #45](https://github.com/PowerShell/xComputerManagement/issues/45)
- Change examples to meet HQRM standards and optin to Example validation
  tests.
- Replaced examples in README.MD to links to Example files.
- Added the VS Code PowerShell extension formatting settings that cause PowerShell
  files to be formatted as per the DSC Resource kit style guidelines - [Issue #91](https://github.com/PowerShell/xComputerManagement/issues/91).
- Opted into Common Tests 'Validate Module Files' and 'Validate Script Files'.
- Converted files with UTF8 with BOM over to UTF8 - fixes [Issue #90](https://github.com/PowerShell/xComputerManagement/issues/90).
- Updated Year to 2017 in License and Manifest - fixes [Issue #87](https://github.com/PowerShell/xComputerManagement/issues/87).
- Added .github support files - fixes [Issue #88](https://github.com/PowerShell/xComputerManagement/issues/88):
  - CONTRIBUTING.md
  - ISSUE_TEMPLATE.md
  - PULL_REQUEST_TEMPLATE.md
- Resolved all PSScriptAnalyzer warnings and style guide warnings.
- xOfflineDomainJoin:
  - Changed to use CommonResourceHelper to load localization strings.
  - Renamed en-US to be correct case so that localization strings can be loaded.
  - Suppress PSScriptAnalyzer rule PSAvoidGlobalVars for
    `$global:DSCMachineStatus = 1`.
- xComputer:
  - Suppress PSScriptAnalyzer rule PSAvoidGlobalVars for
    `$global:DSCMachineStatus = 1`.
- xVirtualMemory:
  - Suppress PSScriptAnalyzer rule PSAvoidGlobalVars for
    `$global:DSCMachineStatus = 1`.

## 2.0.0.0

- Updated resources
  - BREAKING CHANGE: xScheduledTask: Added nearly all available parameters for tasks
- xVirtualMemory:
  - Fixed failing tests.

## 1.10.0.0

- Added resources:
  - xVirtualMemory

## 1.9.0.0

- Added resources
  - xPowerPlan

## 1.8.0.0

- Converted AppVeyor.yml to pull Pester from PSGallery instead of
  Chocolatey.
- Changed AppVeyor.yml to use default image
- xScheduledTask: Fixed bug with different OS versions returning repeat interval
  differently

## 1.7.0.0

- Added support for enabling or disabling scheduled tasks
- The Name parameter resolves to $env:COMPUTERNAME when the value is localhost

## 1.6.0.0

- Added the following resources:
  - MSFT_xOfflineDomainJoin resource to join computers to an AD Domain using an
    Offline Domain Join request file.
  - MSFT_xScheduledTask resource to control scheduled tasks on the local server
- MSFT_xOfflineDomainJoin: Corrected localizedData.DomainAlreadyJoinedhMessage name.
- xComputer: Changed credential generation code in tests to avoid triggering
  PSSA rule PSAvoidUsingConvertToSecureStringWithPlainText.
  Renamed unit test file to match the name of Resource file.

## 1.5.0.0

- Update Unit tests to use the standard folder structure and test templates.
- Added .gitignore to prevent commit of DSCResource.Tests.

## 1.4.0.0

- Added validation to the Name parameter
- Added the JoinOU parameter which allows you to specify the organizational unit
  that the computer account will be created in
- Added the CurrentOU read-only property that shows the organizational unit that
  the computer account is currently in

## 1.3.0

- xComputer
  - Fixed issue with Test-TargetResource when not specifying Domain or
    Workgroup name
  - Added tests

## 1.2.2

- Added types to Get/Set/Test definitions to allow xResourceDesigner validation
  to succeed

## 1.2

- Added functionality to enable moving computer from one domain to another
- Modified Test-DscConfiguration logics when testing domain join

## 1.0.0.0

- Initial release with the following resources:
  - xComputer
