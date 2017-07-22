<#
    .EXAMPLE
    This example will change the machines name while remaining
    in the workgroup.
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
        $MachineName
    )

    Import-DscResource -Module xComputerManagement

    Node $NodeName
    {
        xComputer NewName
        {
            Name = $MachineName
        }
    }
}
