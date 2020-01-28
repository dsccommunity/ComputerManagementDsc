# Integration Test Config Template Version: 1.0.0
configuration DSC_IEEnhancedSecurityConfiguration_Enable_Config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    node $AllNodes.NodeName
    {
        IEEnhancedSecurityConfiguration 'DisableForAdministrators'
        {
            Role            = 'Administrators'
            Enabled         = $true
            SuppressRestart = $true
        }
    }
}

configuration DSC_IEEnhancedSecurityConfiguration_Disable_Config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    node $AllNodes.NodeName
    {
        IEEnhancedSecurityConfiguration 'DisableForAdministrators'
        {
            Role            = 'Administrators'
            Enabled         = $false
            SuppressRestart = $true
        }
    }
}
