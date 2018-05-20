<#
.EXAMPLE
    This example shows how to configure powershell's execution policy using the default scope level.
#>

Configuration PowershellExecutionPolicyWithoutScopeExample
{
    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        PowerShellExecutionPolicy ExecutionPolicy
        {
            ExecutionPolicy = 'RemoteSigned'
        } # End of PowerShellExecutionPolicy
    } # End of Node
} # End of PowershellExecutionPolicyExample

PowershellExecutionPolicyWithoutScopeExample
Start-DscConfiguration PowershellExecutionPolicyWithoutScopeExample -Wait -Verbose -Force
