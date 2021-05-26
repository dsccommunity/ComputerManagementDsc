<#PSScriptInfo
.VERSION 1.0.0
.GUID c3eab687-2f94-4321-b985-e0c128676bfe
.AUTHOR DSC Community
.COMPANYNAME DSC Community
.COPYRIGHT Copyright the DSC Community contributors. All rights reserved.
.TAGS DSCConfiguration
.LICENSEURI https://github.com/dsccommunity/ComputerManagementDsc/blob/master/LICENSE
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
        Creates a system restore point.
#>
Configuration SystemRestorePoint_CreateModifySettings_Config
{
    Import-DSCResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        SystemRestorePoint ModifySettings
        {
            Ensure           = 'Present'
            Description      = 'Modify system settings'
            RestorePointType = 'MODIFY_SETTINGS'
        }
    }
}
