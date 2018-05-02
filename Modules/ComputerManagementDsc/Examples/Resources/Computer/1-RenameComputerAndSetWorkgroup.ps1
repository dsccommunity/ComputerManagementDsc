<#
    .EXAMPLE
    This configuration will set the computer name to 'Server01'
    and make it part of 'ContosoWorkgroup' Workgroup.
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
        Computer NewNameAndWorkgroup
        {
            Name          = 'Server01'
            WorkGroupName = 'ContosoWorkgroup'
        }
    }
}
