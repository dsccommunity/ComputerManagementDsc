configuration DSC_UserAccountControl_Config
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
