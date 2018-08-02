@{
# Version number of this module.
moduleVersion = '5.2.0.0'

# ID used to uniquely identify this module
GUID = 'B5004952-489E-43EA-999C-F16A25355B89'

# Author of this module
Author = 'Microsoft Corporation'

# Company or vendor of this module
CompanyName = 'Microsoft Corporation'

# Copyright statement for this module
Copyright = '(c) 2018 Microsoft Corporation. All rights reserved.'

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
        ReleaseNotes = '- PowershellExecutionPolicy:
  - Updated to meet HQRM guidelines.
  - Migrated the xPowershellExecutionPolicy from [xPowershellExecutionPolicy](https://github.com/PowerShell/xPowerShellExecutionPolicy)
    and renamed to PowershellExecutionPolicy.
  - Moved strings to localization file.
- Changed the scope from Global to Script in MSFT_ScheduledTask.Integration.Tests.ps1
- Changed the scope from Global to Script ComputerManagementDsc.Common.Tests.ps1
- ScheduledTask:
  - Added support for event based triggers, implemented using the ScheduleType OnEvent
    fixes [Issue 167](https://github.com/PowerShell/ComputerManagementDsc/issues/167)

'

    } # End of PSData hashtable

} # End of PrivateData hashtable
}



