configuration Sample_xPowerPlan
{
    param
    (
        [string[]] $NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName xComputerManagement

    Node $NodeName
    {
        xPowerPlan SetPlanHighPerformance
        {
          Ensure = 'Present'
          Name = 'High performance'
        }
    }
}

Sample_xPowerPlan
Start-DscConfiguration -Path Sample_xPowerPlan -Wait -Verbose -Force
