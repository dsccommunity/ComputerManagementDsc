<#PSScriptInfo
.VERSION 1.0.0
.GUID e1ed9aff-7171-425b-a513-6965662816d8
.AUTHOR Microsoft Corporation
.COMPANYNAME Microsoft Corporation
.COPYRIGHT (c) Microsoft Corporation. All rights reserved.
.TAGS DSCConfiguration
.LICENSEURI https://github.com/PowerShell/ComputerManagementDsc/blob/master/LICENSE
.PROJECTURI https://github.com/PowerShell/ComputerManagementDsc
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
        This example configures the SMB Server to disable SMB1.
#>
Configuration SmbServerConfiguration_DisableSmb1_Config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        SmbServerConfiguration SmbServer
        {
            IsSingleInstance                = 'Yes'
            AuditSmb1Access                 = $false
            EnableSMB1Protocol              = $false
        }
    }
}
