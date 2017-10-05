@{
# Version number of this module.
ModuleVersion = '3.0.0.0'

# ID used to uniquely identify this module
GUID = 'B5004952-489E-43EA-999C-F16A25355B89'

# Author of this module
Author = 'Microsoft Corporation'

# Company or vendor of this module
CompanyName = 'Microsoft Corporation'

# Copyright statement for this module
Copyright = '(c) 2017 Microsoft Corporation. All rights reserved.'

# Description of the functionality provided by this module
Description = 'The xComputerManagement module is originally part of the Windows PowerShell Desired State Configuration (DSC) Resource Kit. This version has been modified for use in Azure. This module contains the xComputer and xDisk resources. These DSC Resources allow you to perform computer management tasks, like joining a domain or initializing disks.

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
        LicenseUri = 'https://github.com/PowerShell/xComputerManagement/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/PowerShell/xComputerManagement'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = '* xComputer: Added parameter to set the local computer description along with documentation
 and unit tests for this change.
* BREAKING CHANGE: xScheduledTask:
  * Converted all Interval/Duration type parameters over to be string format
    to prevent the Timezone the MOF file was created in from being stored.
    This is to fix problems where MOF files are created in one timezone but
    deployed nodes to a different timezone - See [Issue 85](https://github.com/PowerShell/xComputerManagement/issues/85)
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
'

    } # End of PSData hashtable

} # End of PrivateData hashtable
}







