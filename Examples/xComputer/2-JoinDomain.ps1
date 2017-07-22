<#
    .EXAMPLE
    This configuration sets the machine name and joins a domain.
    Note: this requires a credential.
#>
Configuration Example
{
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost',

        [Parameter(Mandatory = $true)]
        [System.String]
        $MachineName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DomainName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [System.Management.Automation.PSCredential]
        $Credential
    )

    Import-DscResource -Module xComputerManagement

    Node $NodeName
    {
        xComputer JoinDomain
        {
            Name       = $MachineName
            DomainName = $DomainName
            Credential = $Credential # Credential to join to domain
        }
    }
}
