# Integration Test Config Template Version: 1.0.0
configuration DSC_DismFeature_Config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    node $AllNodes.NodeName
    {
        DismFeature 'AdministratorsSetting'
        {
            Name                    = $Node.Name
            Ensure                  = $Node.Ensure
            EnableAllParentFeatures = $Node.EnableAllParentFeatures
            SuppressRestart         = $true
        }
    }
}

