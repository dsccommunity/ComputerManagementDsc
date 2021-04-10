<#PSScriptInfo
.VERSION 1.0.0
.GUID cabb6778-8f48-4ce7-ad3d-2cc444bc78e9
.AUTHOR DSC Community
.COMPANYNAME DSC Community
.COPYRIGHT Copyright the DSC Community contributors. All rights reserved.
.TAGS DSCConfiguration
.LICENSEURI https://github.com/dsccommunity/ComputerManagementDsc/blob/main/LICENSE
.PROJECTURI https://github.com/dsccommunity/ComputerManagementDsc
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES First version.
.PRIVATEDATA 2016-Datacenter,2016-Datacenter-Server-Core
#>

#Requires -module ComputerManagementDsc

<#
    .DESCRIPTION
        Example script that registers MyEventSource as an event
        source with all resource files on the Application log.
#>
Configuration WindowsEventLog_RegisterEventSourceWithAllFiles_Config
{
    Import-DSCResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        File MyEventSourceCategoryDll
        {
            Ensure          = 'Present'
            Type            = 'File'
            SourcePath      = '\\PULLSERVER\Files\MyEventSource.Category.dll'
            DestinationPath = 'C:\Windows\System32\MyEventSource.Category.dll'
        }

        File MyEventSourceMessageDll
        {
            Ensure          = 'Present'
            Type            = 'File'
            SourcePath      = '\\PULLSERVER\Files\MyEventSource.Message.dll'
            DestinationPath = 'C:\Windows\System32\MyEventSource.Message.dll'
        }

        File MyEventSourceParameterDll
        {
            Ensure          = 'Present'
            Type            = 'File'
            SourcePath      = '\\PULLSERVER\Files\MyEventSource.Parameter.dll'
            DestinationPath = 'C:\Windows\System32\MyEventSource.Parameter.dll'
        }

        WindowsEventLog Application
        {
            LogName               = 'Application'
            RegisteredSource      = 'MyEventSource'
            CategoryResourceFile  = 'C:\Windows\System32\MyEventSource.Category.dll'
            MessageResourceFile   = 'C:\Windows\System32\MyEventSource.Messages.dll'
            ParameterResourceFile = 'C:\Windows\System32\MyEventSource.Parameters.dll'
            DependsOn             = '[File]MyEventSourceCategoryDll',
                                    '[File]MyEventSourceMessageDll',
                                    '[File]MyEventSourceParameterDll'
        }
    }
}
