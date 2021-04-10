<#PSScriptInfo
.VERSION 1.0.0
.GUID f05286e4-e357-40f8-ba62-e49d4d50eb0f
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
        Example script that sets the DSC Analytic log
        to size maximum size 4096MB, log mode to 'Retain' and
        ensures it is enabled.
#>
Configuration WindowsEventLog_EnableWindowsEventLog_Config
{
    Import-DSCResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        WindowsEventLog DscAnalytic
        {
            LogName            = 'Microsoft-Windows-Dsc/Analytic'
            IsEnabled          = $true
            LogMode            = 'Retain'
            MaximumSizeInBytes = 4096MB
            LogFilePath        = '%SystemRoot%\System32\Winevt\Logs\Microsoft-Windows-DSC%4Analytic.evtx'
        }
    }
}
