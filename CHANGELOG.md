# Versions

## Unreleased

- Fix master branch AppVeyor badge link URL in README.MD - See [Issue #140](https://github.com/PowerShell/xComputerManagement/issues/140).
- Fix deletion of scheduled task with unknown or empty task trigger.
  Get-TargetResource returns an empty ScheduleType string if the task
  trigger is empty or unknown - See [Issue
  #137](https://github.com/PowerShell/xComputerManagement/issues/137).

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
