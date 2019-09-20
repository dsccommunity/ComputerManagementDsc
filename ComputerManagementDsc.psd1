@{
# Version number of this module.
moduleVersion = '7.0.0.0'

# ID used to uniquely identify this module
GUID = 'B5004952-489E-43EA-999C-F16A25355B89'

# Author of this module
Author = 'Microsoft Corporation'

# Company or vendor of this module
CompanyName = 'Microsoft Corporation'

# Copyright statement for this module
Copyright = '(c) Microsoft Corporation. All rights reserved.'

# Description of the functionality provided by this module
Description = 'The ComputerManagementDsc module contains DSC resources for configuration of a Windows computer. These DSC resources allow you to perform computer management tasks, such as renaming the computer, joining a domain and scheduling tasks as well as configuring items such as virtual memory, event logs, time zones and power settings.

All of the resources in the DSC Resource Kit are provided AS IS, and are not supported through any Microsoft standard support program or service.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '4.0'

# Minimum version of the common language runtime (CLR) required by this module
CLRVersion = '4.0'

# Functions to export from this module
FunctionsToExport = '*'

# Cmdlets to export from this module
CmdletsToExport = '*'

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('DesiredStateConfiguration', 'DSC', 'DSCResourceKit', 'DSCResource')

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/PowerShell/ComputerManagementDsc/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/PowerShell/ComputerManagementDsc'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = '- ScheduledTask:
  - Better compatibility with Group LogonType
    when passing BuiltIn groups through ExecuteAsCredential
    - Primary use case is "BUILTIN\Users"
    - Use the ExecuteAsCredential property to pass the username
      The PSCredential needs a non-null that is ignored
  - Delay property not handled properly on AtLogon and AtStartup trigger - Fixes
    [Issue 230](https://github.com/PowerShell/ComputerManagementDsc/issues/230)
  - Changed `Get-ScheduledTask` calls to `ScheduledTasks\Get-ScheduledTask` to
    avoid name clash with `Carbon` module. Fixes [Issue 248](https://github.com/PowerShell/ComputerManagementDsc/issues/248)
  - Cast `MultipleInstances` value returned by `Get-TargetResource` to `string` -
    fixes [Issue 255](https://github.com/PowerShell/ComputerManagementDsc/issues/255)
- PendingReboot:
  - Migrated xPendingReboot from [xPendingReboot](https://github.com/PowerShell/xPendingReboot)
    and renamed to PendingReboot.
  - Converted to meet HQRM guidelines - Fixes [Issue 12](https://github.com/PowerShell/xPendingReboot/issues/12).
  - Changed `SkipCcmClientSDK` parameter to default to `$true` - Fixes [Issue 13](https://github.com/PowerShell/xPendingReboot/issues/13).
  - Fixed `Test-TargetResource` so that if ConfigMgr requires a reboot then
    the pending reboot will be set - Fixes [Issue 26](https://github.com/PowerShell/xPendingReboot/issues/26).
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
    [Issue 224](https://github.com/PowerShell/ComputerManagementDsc/issues/224).
- Updated common function `Test-DscParameterState` to support ordered comparison
  of arrays by copying function and tests from `NetworkingDsc` - fixes [Issue 250](https://github.com/PowerShell/ComputerManagementDsc/issues/250).
- BREAKING CHANGE: ScheduledTask:
  - Correct output type of `DaysInterval`,`StartTime`,`WeeksDaysOfWeek`,
    and `WeeksInterval` parameters from `Get-TargetResource` to match MOF.
  - Refactored `Get-TargetResource` to remove parameters that
    are not key or required - fixes [Issue 249](https://github.com/PowerShell/ComputerManagementDsc/issues/249).
  - Added function `Test-DateStringContainsTimeZone` to determine if a string
    containing a date time includes a time zone.
  - Enable verbose preference to be passed through to `Test-DscParameterState`.
  - Changed `Test-TargetResource` so that `StartTime` is only compared for
    trigger types `Daily`,`Weekly` or `Once`.
- Fix minor style issues in statement case.

'

    } # End of PSData hashtable

} # End of PrivateData hashtable
}










