# Integration Test Config Template Version: 1.0.0
configuration DSC_IEEnhancedSecurityConfiguration_Config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    node $AllNodes.NodeName
    {
        IEEnhancedSecurityConfiguration 'AdministratorsSetting'
        {
            Role            = $Node.Role
            Enabled         = $Node.Enabled
            SuppressRestart = $true
        }
    }
}

