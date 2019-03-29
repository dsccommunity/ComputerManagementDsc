<#PSScriptInfo
.VERSION 1.0.0
.GUID fc143221-396c-4407-9aa8-c5878326e4ff
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
        This example will join the computer to a domain using the ODJ
        request file C:\ODJ\ODJRequest.txt.
#>
Configuration OfflineDomainJoin_JoinDomainUsingODJBlob_Config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        OfflineDomainJoin ODJ
        {
          IsSingleInstance = 'Yes'
          RequestFile      = 'C:\ODJ\ODJBlob.txt'
        }
    }
}
