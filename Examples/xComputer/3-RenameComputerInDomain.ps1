<#
    .EXAMPLE
    This example will change the machines name while remaining on the domain.
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
        [ValidateNotNullorEmpty()]
        [System.Management.Automation.PSCredential]
        $Credential
    )

    Import-DscResource -Module xComputerManagement

    Node $NodeName
    {
        xComputer NewName
        {
            Name       = $MachineName
            Credential = $Credential # Domain credential
        }
    }
}
