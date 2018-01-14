<#
    .EXAMPLE
    This examples sets the active power plan to the 'High performance' plan.
#>
Configuration Example
{
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost'
    )

    Import-DscResource -ModuleName xComputerManagement

    Node $NodeName
    {
        xPowerPlan SetPlanHighPerformance
        {
          IsSingleInstance = 'Yes'
          Name             = 'High performance'
        }
    }
}
