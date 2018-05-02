<#
    .EXAMPLE
    This example will set the computer description
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
        Computer NewDescription
        {
            Name = 'localhost'
            Description = 'This is my computer.'
        }
    }
}
