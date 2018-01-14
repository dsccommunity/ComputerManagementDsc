<#
    .EXAMPLE
    This example will change the machines name 'Server01' while remaining
    joined to the current domain.
    Note: this requires a credential for renaming the machine on the
    domain.
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
        xComputer NewName
        {
            Name       = 'Server01'
            Credential = $Credential # Domain credential
        }
    }
}
