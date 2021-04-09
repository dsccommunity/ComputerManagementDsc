<#PSScriptInfo
.VERSION 1.0.0
.GUID 98af759c-cb49-41cb-94ea-c80f3f22bcbb
.AUTHOR DSC Community
.COMPANYNAME DSC Community
.COPYRIGHT DSC Community contributors. All rights reserved.
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
        This configuration will change the notification level for the User
        Account Control (UAC).
#>
Configuration UserAccountControl_GranularSettings_Config
{
    Import-DscResource -Module ComputerManagementDsc

    Node localhost
    {
        UserAccountControl 'SetGranularSettings'
        {
            IsSingleInstance  = 'Yes'
            FilterAdministratorToken = 0
            ConsentPromptBehaviorAdmin = 5
            ConsentPromptBehaviorUser = 3
            EnableInstallerDetection = 1
            ValidateAdminCodeSignatures = 0
            EnableLua = 1
            PromptOnSecureDesktop = 1
            EnableVirtualization = 1
        }
    }
}
