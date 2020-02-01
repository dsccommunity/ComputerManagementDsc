# Setting value that are somewhat safe to change temporarily in a build worker.
configuration DSC_UserAccountControl_GranularSettings_Config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    node $AllNodes.NodeName
    {
        UserAccountControl 'SetGranularSettings'
        {
            IsSingleInstance  = 'Yes'
            ConsentPromptBehaviorUser = $Node.ConsentPromptBehaviorUser
            EnableInstallerDetection = $Node.EnableInstallerDetection
            SuppressRestart = $true
        }
    }
}

configuration DSC_UserAccountControl_Cleanup_Config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    node $AllNodes.NodeName
    {
        UserAccountControl 'RevertToOriginalValues'
        {
            IsSingleInstance  = 'Yes'
            ConsentPromptBehaviorUser = $Node.OriginalConsentPromptBehaviorUser
            EnableInstallerDetection = $Node.OriginalEnableInstallerDetection
            SuppressRestart = $true
        }
    }
}

