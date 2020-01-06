<#PSScriptInfo
.VERSION 1.0.0
.GUID 7e77ef8f-69ac-4e86-8a95-e38d3350118f
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
        This example will change the machines name 'Server01' while remaining
        joined to the current domain.
        Note: this requires a credential for renaming the machine on the
        domain.
#>
Configuration Computer_RenameComputerInDomain_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [System.Management.Automation.PSCredential]
        $Credential
    )

    Import-DscResource -Module ComputerManagementDsc

    Node localhost
    {
        Computer NewName
        {
            Name       = 'Server01'
            Credential = $Credential # Domain credential
        }
    }
}
