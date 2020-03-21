<#PSScriptInfo
.VERSION 1.0.0
.GUID 9539d054-70d9-4b54-abf2-9236c44b4289
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
        This configuration will add the feature MSMQ-Server.
#>
Configuration DismFeature_AddFeature_Config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        DismFeature 'MSMQ-Server'
        {
            Ensure = 'Present'
            Name   = 'MSMQ-Server'
        }
    }
}
