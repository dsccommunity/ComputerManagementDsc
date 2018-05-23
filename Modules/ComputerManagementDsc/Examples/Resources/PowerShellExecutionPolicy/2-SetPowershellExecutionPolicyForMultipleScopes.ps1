<#
.EXAMPLE
    This example shows how to configure multiple powershell's execution policy for a specified execution policy scope.
#>

Configuration Example
{
    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        PowerShellExecutionPolicy ExecutionPolicyCurrentUser
        {
            ExecutionPolicyScope = 'CurrentUser'
            ExecutionPolicy      = 'RemoteSigned'
        } # End of ExecutionPolicyCurrentUser Resource

        PowerShellExecutionPolicy ExecutionPolicyLocalMachine
        {
            ExecutionPolicyScope = 'LocalMachine'
            ExecutionPolicy      = 'RemoteSigned'
        } # End of ExecutionPolicyLocalMachine Resource
    } # End of Node
} # End of Configuration
