<#
    .EXAMPLE
    This example switches the computer from a domain to a workgroup.
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
        $WorkGroup,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [System.Management.Automation.PSCredential]
        $Credential
    )

    Import-DscResource -Module xComputerManagement

    Node $NodeName
    {
        xComputer JoinWorkgroup
        {
            Name          = $MachineName
            WorkGroupName = $WorkGroup
            Credential    = $Credential # Credential to unjoin from domain
        }
    }
}
