<#
.EXAMPLE
    This example shows how to configure powershell's execution policy using the default scope level.
#>

Configuration Example
{
    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        PowerShellExecutionPolicy ExecutionPolicy
        {
            ExecutionPolicy = 'RemoteSigned'
        }
    }
}
