<#
.EXAMPLE
    This example shows how to configure powershell's execution policy for the specified execution policy scope.
#>

Configuration PowershellExecutionPolicyExample
{
    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        PowerShellExecutionPolicy ExecutionPolicy
        {
            ExecutionPolicy      = 'RemoteSigned'
            ExecutionPolicyScope = 'LocalMachine'
        } # End of PowershellExecutionPolicy Resource
    } # End of Node
} # End of Configuration

PowershellExecutionPolicyExample
Start-DscConfiguration PowershellExecutionPolicyExample -Wait -Verbose -Force
