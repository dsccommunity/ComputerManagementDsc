# Integration Test Config Template Version: 1.0.0
Configuration DSC_WindowsCapability_Config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    node $AllNodes.NodeName
    {
        WindowsCapability TestInstallation
        {
            Name     = $Node.Name
            LogLevel = $Node.LogLevel
            LogPath  = $Node.LogPath
            Ensure   = $Node.Ensure
            Source   = $Node.Source
        }
    }
}
