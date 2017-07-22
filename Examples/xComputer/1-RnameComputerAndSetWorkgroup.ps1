<#
    .EXAMPLE
    This configuration will set a machine name and changes the
    workgroup it is in.
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
        $WorkGroup
    )

    Import-DscResource -Module xComputerManagement

    Node $NodeName
    {
        xComputer NewNameAndWorkgroup
        {
            Name          = $MachineName
            WorkGroupName = $WorkGroup
        }
    }
}
