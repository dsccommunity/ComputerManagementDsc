@{
# Version number of this module.
moduleVersion = '6.5.0.0'

# ID used to uniquely identify this module
GUID = 'B5004952-489E-43EA-999C-F16A25355B89'

# Author of this module
Author = 'Microsoft Corporation'

# Company or vendor of this module
CompanyName = 'Microsoft Corporation'

# Copyright statement for this module
Copyright = '(c) Microsoft Corporation. All rights reserved.'

# Description of the functionality provided by this module
Description = 'The ComputerManagementDsc module is originally part of the Windows PowerShell Desired State Configuration (DSC) Resource Kit. This version has been modified for use in Azure. This module contains the xComputer and xDisk resources. These DSC Resources allow you to perform computer management tasks, like joining a domain or initializing disks.

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
        ReleaseNotes = '- Computer:
  - Fix for "directory service is busy" error when joining a domain and renaming
    a computer when JoinOU is specified - Fixes [Issue 221](https://github.com/PowerShell/ComputerManagementDsc/issues/221).
- Added new resource SmbShare
  - Moved and improved from deprecated module xSmbShare.
- Changes to ComputerManagementDsc.Common
  - Updated Test-DscParameterState so it now can compare zero item
    collections (arrays).
- Changes to WindowsEventLog
  - Minor style guideline cleanup.
- Opt-in to common test to validate localization. Fixed localization strings
  in resources - Fixes [Issue 217](https://github.com/PowerShell/ComputerManagementDsc/issues/217).
- PowerShellExecutionPolicy:
  - Removed `SupportsShouldProcess` as it cannot be used with DSC - Fixes
    [Issue 219](https://github.com/PowerShell/ComputerManagementDsc/issues/219).
- Combined all ComputerManagementDsc.ResourceHelper module functions into
  ComputerManagementDsc.Common module - Fixes [Issue 218](https://github.com/PowerShell/ComputerManagementDsc/issues/218).
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

'

    } # End of PSData hashtable

} # End of PrivateData hashtable
}









