<#
    .EXAMPLE
    This configuration sets the machine name to 'Server01' and
    joins the 'Contoso' domain using the domain controller 'dc1.contoso.com'.
    Note: this requires an AD credential to join the domain.
#>
Configuration Example
{
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [System.Management.Automation.PSCredential]
        $Credential
    )

    Import-DscResource -Module ComputerManagementDsc

    Node $NodeName
    {
        Computer JoinDomain
        {
            Name       = 'Server01'
            DomainName = 'Contoso'
            Credential = $Credential # Credential to join to domain
            Server     = 'dc1.contoso.com'
        }
    }
}
