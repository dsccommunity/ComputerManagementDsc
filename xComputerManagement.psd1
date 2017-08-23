@{
# Version number of this module.
ModuleVersion = '2.1.0.0'

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
        ReleaseNotes = '* xComputer: Changed comparison that validates if we are in the correct AD
  Domain to work correctly if FQDN wasn"t used.
* Updated AppVeyor.yml to use AppVeyor.psm1 module in DSCResource.Tests.
* Removed Markdown.md errors.
* Added CodeCov.io support.
* xScheduledTask
  * Fixed incorrect TaskPath handling - [Issue 45](https://github.com/PowerShell/xComputerManagement/issues/45)
* Change examples to meet HQRM standards and optin to Example validation
  tests.
* Replaced examples in README.MD to links to Example files.
* Added the VS Code PowerShell extension formatting settings that cause PowerShell
  files to be formatted as per the DSC Resource kit style guidelines - [Issue 91](https://github.com/PowerShell/xComputerManagement/issues/91).
* Opted into Common Tests "Validate Module Files" and "Validate Script Files".
* Converted files with UTF8 with BOM over to UTF8 - fixes [Issue 90](https://github.com/PowerShell/xComputerManagement/issues/90).
* Updated Year to 2017 in License and Manifest - fixes [Issue 87](https://github.com/PowerShell/xComputerManagement/issues/87).
* Added .github support files - fixes [Issue 88](https://github.com/PowerShell/xComputerManagement/issues/88):
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

'

    } # End of PSData hashtable

} # End of PrivateData hashtable
}






