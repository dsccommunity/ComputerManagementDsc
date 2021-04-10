<#PSScriptInfo
.VERSION 1.0.0
.GUID 13b87555-fdf1-4cc7-b033-73074573e0e3
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
        source with a message resource file on the Application log.
#>
Configuration WindowsEventLog_RegisterEventSourceWithMessageFile_Config
{
    Import-DSCResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        File MyEventSourceMessageDll
        {
            Ensure          = 'Present'
            Type            = 'File'
            SourcePath      = '\\PULLSERVER\Files\MyEventSource.dll'
            DestinationPath = 'C:\Windows\System32\MyEventSource.dll'
        }

        WindowsEventLog Application
        {
            LogName             = 'Application'
            RegisteredSource    = 'MyEventSource'
            MessageResourceFile = 'C:\Windows\System32\MyEventSource.dll'
            DependsOn           = '[File]MyEventSourceMessageDll'
        }
    }
}
