<#PSScriptInfo
.VERSION 1.0.0
.GUID 1d426e51-df3b-4723-96ac-e7d790744f69
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
        Example script that disables the DSC Analytic log.
#>
Configuration WindowsEventLog_DisableWindowsEventLog_Config
{
    Import-DSCResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        WindowsEventLog DscAnalytic
        {
            LogName   = 'Microsoft-Windows-Dsc/Analytic'
            IsEnabled = $false
        }
    }
}
