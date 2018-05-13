<#
    .EXAMPLE
    This example will set the machine name to 'Server01' while remaining
    in the workgroup.
#>
Configuration Example
{
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost'
    )

    Import-DscResource -Module ComputerManagementDsc

    Node $NodeName
    {
        Computer NewName
        {
            Name = 'Server01'
        }
    }
}
