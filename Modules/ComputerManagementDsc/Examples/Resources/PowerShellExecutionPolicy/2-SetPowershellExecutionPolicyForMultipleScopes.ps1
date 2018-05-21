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
            ExecutionPolicy      = 'RemoteSigned'
            ExecutionPolicyScope = 'CurrentUser'
        } # End of ExecutionPolicyCurrentUser Resource

        PowerShellExecutionPolicy ExecutionPolicyLocalMachine
        {
            ExecutionPolicy      = 'RemoteSigned'
            ExecutionPolicyScope = 'LocalMachine'
        } # End of ExecutionPolicyLocalMachine Resource
    } # End of Node
} # End of Configuration

#Example
#Start-DscConfiguration Example -Wait -Verbose -Force
