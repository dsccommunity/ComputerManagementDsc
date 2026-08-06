<#PSScriptInfo
.VERSION 1.0.0
.GUID 3b2e8a4c-7f1d-4e2a-9c6b-8d5f3a1e7b9d
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
        This configuration sets the machine name to 'Server01' and
        joins the 'Contoso' domain while reusing any existing computer
        account in Active Directory. This preserves the machine SID,
        group memberships, and GPO links.
        Note: this requires an AD credential to join the domain.
#>
Configuration Computer_JoinDomainKeepExistingAccount_Config
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
        Computer JoinDomain
        {
            Name                         = 'Server01'
            DomainName                   = 'Contoso'
            Credential                   = $Credential # Credential to join to domain
            ReuseExistingComputerAccount = $true       # Reuse existing AD computer account
        }
    }
}
