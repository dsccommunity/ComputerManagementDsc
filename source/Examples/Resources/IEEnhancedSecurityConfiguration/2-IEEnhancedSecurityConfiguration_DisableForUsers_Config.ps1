<#PSScriptInfo
.VERSION 1.0.0
.GUID 4afcbf49-6290-4039-a1f1-965a721f6f49
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
        This configuration will disable the IE Enhanced Security Configuration for
        users.
#>
Configuration IEEnhancedSecurityConfiguration_DisableForUsers_Config
{
    Import-DscResource -Module ComputerManagementDsc

    Node localhost
    {
        IEEnhancedSecurityConfiguration 'DisableForUsers'
        {
            Role    = 'Users'
            Enabled = $false
        }
    }
}
