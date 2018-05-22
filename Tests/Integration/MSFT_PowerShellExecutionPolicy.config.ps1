# Integration Test Config Template Version: 1.0.0
configuration MSFT_PowerShellExecutionPolicy_config
 {
    Import-DscResource -ModuleName ComputerManagementDsc

    node 'localhost'
    {
        PowerShellExecutionPolicy Integration_Test
        {
            ExecutionPolicy      = 'RemoteSigned'
            ExecutionPolicyScope = 'LocalMachine'
        }
    }
}
