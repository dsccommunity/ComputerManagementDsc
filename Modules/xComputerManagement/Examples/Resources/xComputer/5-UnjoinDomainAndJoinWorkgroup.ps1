<#
    .EXAMPLE
    This example switches the computer 'Server01' from a domain and joins it
    to the 'ContosoWorkgroup' Workgroup.
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
        [ValidateNotNullorEmpty()]
        [System.Management.Automation.PSCredential]
        $Credential
    )

    Import-DscResource -Module xComputerManagement

    Node $NodeName
    {
        xComputer JoinWorkgroup
        {
            Name          = 'Server01'
            WorkGroupName = 'ContosoWorkgroup'
            Credential    = $Credential # Credential to unjoin from domain
        }
    }
}
