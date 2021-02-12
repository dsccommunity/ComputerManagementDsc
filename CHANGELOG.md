# Change log for ComputerManagementDsc

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- ScheduledTask
  - Fixed issue with disabling scheduled tasks that have "Run whether user is
    logged on or not" configured - Fixes [Issue #306](https://github.com/dsccommunity/ComputerManagementDsc/issues/306).
  - Fixed issue with `ExecuteAsCredential` not returning fully qualified username
    on newer versions of Windows 10 and Windows Server 2019 - Fixes [Issue #352](https://github.com/dsccommunity/ComputerManagementDsc/issues/352).
  - Fixed issue with `StartTime` failing Test-Resource if not specified in the
    resource - Fixes [Issue #148](https://github.com/dsccommunity/ComputerManagementDsc/issues/148).
- PendingReboot
  - Fixed issue with loading localized data on non en-US operating systems -
    Fixes [Issue #350](https://github.com/dsccommunity/ComputerManagementDsc/issues/350).

## [8.4.0] - 2020-08-03

### Changed

- ComputerManagementDsc
  - Automatically publish documentation to GitHub Wiki - Fixes [Issue #342](https://github.com/dsccommunity/ComputerManagementDsc/issues/342).

## [8.3.0] - 2020-06-30

### Changed

- ComputerManagementDsc
  - Updated to use the common module _DscResource.Common_ - Fixes [Issue #327](https://github.com/dsccommunity/ComputerManagementDsc/issues/327).
  - Fixed build failures caused by changes in `ModuleBuilder` module v1.7.0
    by changing `CopyDirectories` to `CopyPaths` - Fixes [Issue #332](https://github.com/dsccommunity/ComputerManagementDsc/issues/332).
  - Pin `Pester` module to 4.10.1 because Pester 5.0 is missing code
    coverage - Fixes [Issue #336](https://github.com/dsccommunity/ComputerManagementDsc/issues/336).
- ScheduledTask
  - Add "StopExisting" to valid values for MultipleInstances parameter - Fixes [Issue #333](https://github.com/dsccommunity/ComputerManagementDsc/issues/333).

### Fixed

- ComputerManagementDsc
  - Improved integration test reliability by resetting the DSC LCM
    before executing each test using the `Reset-DscLcm` function - Fixes [Issue #329](https://github.com/dsccommunity/ComputerManagementDsc/issues/329).
  - Split integration test MOF compilation out of application to standardize
    pattern and make it easier to determine cause of failure.

## [8.2.0] - 2020-05-05

### Changed

- Change Azure DevOps Pipeline definition to include `source/*` - Fixes [Issue #324](https://github.com/dsccommunity/ComputerManagementDsc/issues/324).
- Updated pipeline to use `latest` version of `ModuleBuilder` - Fixes [Issue #324](https://github.com/dsccommunity/ComputerManagementDsc/issues/324).
- Merge `HISTORIC_CHANGELOG.md` into `CHANGELOG.md` - Fixes [Issue #325](https://github.com/dsccommunity/ComputerManagementDsc/issues/325).
- ScheduledTask:
  - Fix ServiceAccount behavior on Windows Server 2016 - Fixes [Issue #323](https://github.com/dsccommunity/ComputerManagementDsc/issues/323).
  - Fixed problems in integration test configuration naming.
  - Changed `ScheduledTaskExecuteAsGroupAdd` and `ScheduledTaskExecuteAsGroupMod`
    to use a group name that does not include a domain name `BUILTIN\`.
  - Added known issues to the documentation for describing `ExecuteAsCredential`
    behavior - Fixes [Issue #294](https://github.com/dsccommunity/ComputerManagementDsc/issues/294).
- PendingReboot:
  - Changed integration tests to clear pending file rename reboot flag before
    executing tests and restoring when complete.

## [8.1.0] - 2020-03-26

### Added

- ComputerManagementDsc
  - Added build task `Generate_Conceptual_Help` to generate conceptual help
    for the DSC resource.
  - Added build task `Generate_Wiki_Content` to generate the wiki content
    that can be used to update the GitHub Wiki.

### Changed

- ComputerManagementDsc
  - Updated CI pipeline files.
  - No longer run integration tests when running the build task `test`, e.g.
    `.\build.ps1 -Task test`. To manually run integration tests, run the
    following:
    ```powershell
    .\build.ps1 -Tasks test -PesterScript 'tests/Integration' -CodeCoverageThreshold 0
    ```

### Fixed

- ScheduledTask:
  - Added missing 'NT Authority\' domain prefix when testing tasks that use
    the BuiltInAccount property - Fixes [Issue #317](https://github.com/dsccommunity/ComputerManagementDsc/issues/317)

## [8.0.0] - 2020-02-14

### Added

- Added new resource IEEnhancedSecurityConfiguration (moved from module
  xSystemSecurity).
- Added new resource UserAccountControl (moved from module
  xSystemSecurity).

### Changed

- SmbShare:
  - Add parameter ScopeName to support creating shares in a different
    scope - Fixes [Issue #284](https://github.com/dsccommunity/ComputerManagementDsc/issues/284).
- Added `.gitattributes` to ensure CRLF is used when pulling repository - Fixes
  [Issue #290](https://github.com/dsccommunity/ComputerManagementDsc/issues/290).
- SystemLocale:
  - Migrated SystemLocale from [SystemLocaleDsc](https://github.com/PowerShell/SystemLocaleDsc).
- RemoteDesktopAdmin:
  - Correct Context messages in integration tests by adding 'When'.
- WindowsCapability:
  - Change `Test-TargetResource` to remove test for valid LogPath.
- BREAKING CHANGE: Changed resource prefix from MSFT to DSC.
- Updated to use continuous delivery pattern using Azure DevOps - Fixes
  [Issue #295](https://github.com/dsccommunity/ComputerManagementDsc/issues/295).

### Deprecated

- None

### Removed

- None

### Fixed

- WindowsCapability:
  - Fix `A parameter cannot be found that matches parameter name 'Ensure'.`
    error in `Test-TargetResource` - Fixes [Issue #297](https://github.com/dsccommunity/ComputerManagementDsc/issues/297).

### Security

- None

## [7.1.0.0] - 2019-10-30

### Changed

- ComputerManagementDsc:
  - Update psd1 description - Fixes [Issue #269](https://github.com/dsccommunity/ComputerManagementDsc/issues/269).
- Fix minor style issues with missing spaces between `param` statements and '('.
- SmbServerConfiguration:
  - New resource for configuring the SMB Server settings.
  - Added examples for SMB Server Configuration.
- Minor corrections to CHANGELOG.MD.
- ScheduledTask:
  - Fixed bug when description has any form of whitespace at beginning or
    end the resource would not go into state - Fixes [Issue #258](https://github.com/dsccommunity/ComputerManagementDsc/issues/258).
- SmbShare:
  - Fixed bug where the resource would not update the path of a share if the
    share exists on a different path. Adds a parameter Force to the SmbShare
    resource to allow updating of the path - Fixes [Issue #215](https://github.com/dsccommunity/ComputerManagementDsc/issues/215)
  - Removal of duplicate code in Add-SmbShareAccessPermission helper function
    fixes [Issue #226](https://github.com/dsccommunity/ComputerManagementDsc/issues/226).

## [7.0.0.0] - 2019-09-19

### Changed

- ScheduledTask:
  - Better compatibility with Group LogonType
    when passing BuiltIn groups through ExecuteAsCredential
    - Primary use case is 'BUILTIN\Users'
    - Use the ExecuteAsCredential property to pass the username
      The PSCredential needs a non-null that is ignored
  - Delay property not handled properly on AtLogon and AtStartup trigger - Fixes
    [Issue #230](https://github.com/dsccommunity/ComputerManagementDsc/issues/230).
  - Changed `Get-ScheduledTask` calls to `ScheduledTasks\Get-ScheduledTask` to
    avoid name clash with `Carbon` module. Fixes [Issue #248](https://github.com/dsccommunity/ComputerManagementDsc/issues/248).
  - Cast `MultipleInstances` value returned by `Get-TargetResource` to `string` -
    fixes [Issue #255](https://github.com/dsccommunity/ComputerManagementDsc/issues/255).
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
    [Issue #224](https://github.com/dsccommunity/ComputerManagementDsc/issues/224).
- Updated common function `Test-DscParameterState` to support ordered comparison
  of arrays by copying function and tests from `NetworkingDsc` - fixes [Issue #250](https://github.com/dsccommunity/ComputerManagementDsc/issues/250).
- BREAKING CHANGE: ScheduledTask:
  - Correct output type of `DaysInterval`,`StartTime`,`WeeksDaysOfWeek`,
    and `WeeksInterval` parameters from `Get-TargetResource` to match MOF.
  - Refactored `Get-TargetResource` to remove parameters that
    are not key or required - fixes [Issue #249](https://github.com/dsccommunity/ComputerManagementDsc/issues/249).
  - Added function `Test-DateStringContainsTimeZone` to determine if a string
    containing a date time includes a time zone.
  - Enable verbose preference to be passed through to `Test-DscParameterState`.
  - Changed `Test-TargetResource` so that `StartTime` is only compared for
    trigger types `Daily`,`Weekly` or `Once`.
- Fix minor style issues in statement case.

## [6.5.0.0] - 2019-08-08

### Changed

- Computer:
  - Fix for 'directory service is busy' error when joining a domain and renaming
    a computer when JoinOU is specified - Fixes [Issue #221](https://github.com/dsccommunity/ComputerManagementDsc/issues/221).
- Added new resource SmbShare
  - Moved and improved from deprecated module xSmbShare.
- Changes to ComputerManagementDsc.Common
  - Updated Test-DscParameterState so it now can compare zero item
    collections (arrays).
- Changes to WindowsEventLog
  - Minor style guideline cleanup.
- Opt-in to common test to validate localization. Fixed localization strings
  in resources - Fixes [Issue #217](https://github.com/dsccommunity/ComputerManagementDsc/issues/217).
- PowerShellExecutionPolicy:
  - Removed `SupportsShouldProcess` as it cannot be used with DSC - Fixes
    [Issue #219](https://github.com/dsccommunity/ComputerManagementDsc/issues/219).
- Combined all ComputerManagementDsc.ResourceHelper module functions into
  ComputerManagementDsc.Common module - Fixes [Issue #218](https://github.com/dsccommunity/ComputerManagementDsc/issues/218).
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

## [6.4.0.0] - 2019-05-15

### Changed

- ScheduledTask:
  - IdleWaitTimeout returned from Get-TargetResource always null - Fixes [Issue #186](https://github.com/dsccommunity/ComputerManagementDsc/issues/186).
  - Added BuiltInAccount Property to allow running task as one of the build in
    service accounts - Fixes [Issue #130](https://github.com/dsccommunity/ComputerManagementDsc/issues/130).
- Refactored module folder structure to move resource to root folder of
  repository and remove test harness - fixes [Issue #188](https://github.com/dsccommunity/ComputerManagementDsc/issues/188).
- Added a CODE\_OF\_CONDUCT.md with the same content as in the README.md and
  linked to it from README.MD instead.
- Updated test header for all unit tests to version 1.2.4.
- Updated test header for all integration to version 1.3.3.
- Enabled example publish to PowerShell Gallery by adding `gallery_api`
  environment variable to `AppVeyor.yml`.

## [6.3.0.0] - 2019-04-03

### Changed

- Correct PSSA custom rule violations - fixes [Issue #209](https://github.com/dsccommunity/ComputerManagementDsc/issues/209).
- Correct long example filenames for PowerShellExecutionPolicy examples.
- Opted into Common Tests 'Required Script Analyzer Rules',
  'Flagged Script Analyzer Rules', 'New Error-Level Script Analyzer Rules'
  'Custom Script Analyzer Rules' and 'Relative Path Length' -
  fixes [Issue #152](https://github.com/dsccommunity/ComputerManagementDsc/issues/152).
- PowerPlan:
  - Added support to specify the desired power plan either as name or guid.
    Fixes [Issue #59](https://github.com/dsccommunity/ComputerManagementDsc/issues/59)
  - Changed the resource so it uses Windows APIs instead of WMI/CIM
    (Workaround for Server 2012R2 Core, Nano Server, Server 2019 and Windows 10).
    Fixes [Issue #155](https://github.com/dsccommunity/ComputerManagementDsc/issues/155)
    and [Issue #65](https://github.com/dsccommunity/ComputerManagementDsc/issues/65)

## [6.2.0.0] - 2019-02-20

### Changed

- WindowsEventLog:
  - Migrated the xWinEventLog from [xWinEventLog](https://github.com/PowerShell/xWinEventLog)
    and renamed to WindowsEventLog.
  - Moved strings in localization file.
  - LogMode is now set with Limit-EventLog,
  - Fixes [Issue #18](https://github.com/dsccommunity/ComputerManagementDsc/issues/18).
- Updated examples to format required for publishing to PowerShell Gallery - fixes
  [Issue #206](https://github.com/dsccommunity/ComputerManagementDsc/issues/206).
- Opted into Common Tests 'Validate Example Files To Be Published' and
  'Validate Markdown Links'.

## [6.1.0.0] - 2019-01-10

### Changed

- Updated LICENSE file to match the Microsoft Open Source Team standard.
  Fixes [Issue #197](https://github.com/dsccommunity/ComputerManagementDsc/issues/197).
- Explicitly removed extra hidden files from release package

## [6.0.0.0] - 2018-10-25

### Changed

- ScheduledTask:
  - Added support for Group Managed Service Accounts, implemented using the ExecuteAsGMSA
    parameter. Fixes [Issue #111](https://github.com/dsccommunity/ComputerManagementDsc/issues/111)
  - Added support to set the Synchronize Across Time Zone option. Fixes [Issue #109](https://github.com/dsccommunity/ComputerManagementDsc/issues/109)
- Added .VSCode settings for applying DSC PSSA rules - fixes [Issue #189](https://github.com/dsccommunity/ComputerManagementDsc/issues/189).
- BREAKING CHANGE: PowerPlan:
  - Added IsActive Read-Only Property - Fixes [Issue #171](https://github.com/dsccommunity/ComputerManagementDsc/issues/171).
  - InActive power plans are no longer returned with their Name set to null.
    Now, the name is always returned and the Read-Only property of IsActive
    is set accordingly.

## [5.2.0.0] - 2018-07-25

### Changed

- PowershellExecutionPolicy:
  - Updated to meet HQRM guidelines.
  - Migrated the xPowershellExecutionPolicy from [xPowershellExecutionPolicy](https://github.com/PowerShell/xPowerShellExecutionPolicy)
    and renamed to PowershellExecutionPolicy.
  - Moved strings to localization file.
- Changed the scope from Global to Script in DSC_ScheduledTask.Integration.Tests.ps1
- Changed the scope from Global to Script ComputerManagementDsc.Common.Tests.ps1
- ScheduledTask:
  - Added support for event based triggers, implemented using the ScheduleType OnEvent
    fixes [Issue #167](https://github.com/dsccommunity/ComputerManagementDsc/issues/167)

## [5.1.0.0] - 2018-06-13

### Changed

- TimeZone:
  - Migrated xTimeZone resource from [xTimeZone](https://github.com/PowerShell/xTimeZone)
    and renamed to TimeZone - fixes [Issue #157](https://github.com/dsccommunity/ComputerManagementDsc/issues/157).
- Moved Test-Command from ComputerManagementDsc.ResourceHelper to
  ComputerManagementDsc.Common module to match what TimeZone requires.
  It was not exported in ComputerManagementDsc.ResourceHelper and not
  used.
- Add `server` parameter to `Computer` resource - fixes [Issue #161](https://github.com/dsccommunity/ComputerManagementDsc/issues/161)

## [5.0.0.0] - 2018-05-03

### Changed

- BREAKING CHANGE:
  - Renamed ComputerManagement to ComputerManagementDsc - fixes [Issue #119](https://github.com/dsccommunity/ComputerManagementDsc/issues/119).
  - Changed all MSFT\_xResourceName to MSFT\_ResourceName.
  - Updated DSCResources, Examples, Modules and Tests with new naming.
  - Updated Year to 2018 in License and Manifest.
  - Updated README.md from xComputerManagement to ComputerManagementDsc.
- OfflineDomainJoin:
  - Cleaned up spacing in strings file to make consistent with other
    resources.
- VirtualMemory:
  - Converted strings to single quotes in integration test.

## [4.1.0.0] - 2018-03-22

### Changed

- xScheduledTask:
  - Update existing Scheduled Task using SetScheduleTask
    instead of UnRegister/Register - See [Issue #134](https://github.com/PowerShell/xComputerManagement/issues/134).
- Fix master branch AppVeyor badge link URL in README.MD - See [Issue #140](https://github.com/PowerShell/xComputerManagement/issues/140).
- Fix deletion of scheduled task with unknown or empty task trigger.
  Get-TargetResource returns an empty ScheduleType string if the task
  trigger is empty or unknown - See [Issue
  #137](https://github.com/PowerShell/xComputerManagement/issues/137).
- Added dependency information for xScheduledTask to README.MD.

## [4.0.0.0] - 2018-02-08

### Changed

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

## [3.2.0.0] - 2017-12-20

### Changed

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

## [3.1.0.0] - 2017-11-15

### Changed

- xOfflineDomainJoin:
  - Updated to meet HQRM guidelines.
- xScheduledTask:
  - Applied autoformatting to examples to improve readability.
  - Added LogonType and RunLevel parameters for controlling
    task execution.
  - Correct `Assert-VerifiableMocks` to `Assert-VerifiableMock`

## [3.0.0.0] - 2017-10-05

### Changed

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

## [2.1.0.0] - 2017-08-23

### Changed

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

## [2.0.0.0] - 2017-07-12

### Changed

- Updated resources
  - BREAKING CHANGE: xScheduledTask: Added nearly all available parameters for tasks
- xVirtualMemory:
  - Fixed failing tests.

## [1.10.0.0] - 2017-05-31

### Changed

- Added resources:
  - xVirtualMemory

## [1.9.0.0] - 2016-12-14

### Changed

- Added resources
  - xPowerPlan

## [1.8.0.0] - 2016-08-10

### Changed

- Converted AppVeyor.yml to pull Pester from PSGallery instead of
  Chocolatey.
- Changed AppVeyor.yml to use default image
- xScheduledTask: Fixed bug with different OS versions returning repeat interval
  differently

## [1.7.0.0] - 2016-06-29

### Changed

- Added support for enabling or disabling scheduled tasks
- The Name parameter resolves to $env:COMPUTERNAME when the value is localhost

## [1.6.0.0] - 2016-05-18

### Changed

- Added the following resources:
  - DSC_xOfflineDomainJoin resource to join computers to an AD Domain using an
    Offline Domain Join request file.
  - DSC_xScheduledTask resource to control scheduled tasks on the local server
- DSC_xOfflineDomainJoin: Corrected localizedData.DomainAlreadyJoinedhMessage name.
- xComputer: Changed credential generation code in tests to avoid triggering
  PSSA rule PSAvoidUsingConvertToSecureStringWithPlainText.
  Renamed unit test file to match the name of Resource file.

## [1.5.0.0] - 2016-03-31

### Changed

- Update Unit tests to use the standard folder structure and test templates.
- Added .gitignore to prevent commit of DSCResource.Tests.

## [1.4.0.0] - 2016-02-03

### Changed

- Added validation to the Name parameter
- Added the JoinOU parameter which allows you to specify the organizational unit
  that the computer account will be created in
- Added the CurrentOU read-only property that shows the organizational unit that
  the computer account is currently in

## [1.3.0.0] - 2015-06-08

### Changed

- xComputer
  - Fixed issue with Test-TargetResource when not specifying Domain or
    Workgroup name
  - Added tests

## [1.2.2.0] - 2015-02-19

### Changed

- Added types to Get/Set/Test definitions to allow xResourceDesigner validation
  to succeed

## [1.2.0.0] - 2014-05-13

### Changed

- Added functionality to enable moving computer from one domain to another
- Modified Test-DscConfiguration logics when testing domain join

## [1.0.0.0] - 2014-01-01

### Changed

- Initial release with the following resources:
  - xComputer
