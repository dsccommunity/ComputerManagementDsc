<#
    .SYNOPSIS
        Example to set a power plan. 

    .DESCRIPTION
        This examples sets the active power plan to the 'High performance' plan. 
#>
Configuration Sample_xPowerPlan
{
    param
    (
        [Parameter()]
        [String[]]
        $NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName xComputerManagement

    Node $NodeName
    {
        xPowerPlan SetPlanHighPerformance
        {
          IsSingleInstance = 'Yes'
          Name = 'High performance'
        }
    }
}

Sample_xPowerPlan
Start-DscConfiguration -Path Sample_xPowerPlan -Wait -Verbose -Force
