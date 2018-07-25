<#
.EXAMPLE
    This example shows how to configure powershell's execution policy for the specified execution policy scope.
#>

Configuration Example
{
    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        PowerShellExecutionPolicy ExecutionPolicy
        {
            ExecutionPolicyScope = 'CurrentUser'
            ExecutionPolicy      = 'RemoteSigned'
        } # End of PowershellExecutionPolicy Resource
    } # End of Node
} # End of Configuration
