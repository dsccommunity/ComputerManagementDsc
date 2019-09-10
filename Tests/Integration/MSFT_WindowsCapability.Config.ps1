# Integration Test Config Template Version: 1.0.0
configuration MSFT_WindowsCapability_Default
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        WindowsCapability Integration_Test
        {
            Name    = 'Application'
            Ensure  = 'Present'
            LogMode = 'Circular'
        }
    }
}

configuration MSFT_WindowsCapability_EnableCapability
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        WindowsCapability Integration_Test
        {
            LogName = 'Microsoft-Windows-Backup'
            Ensure  = 'Present'
            LogMode = 'AutoBackup'
        }
    }
}

configuration MSFT_WindowsCapability_DisableCapability
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        WindowsCapability Integration_Test
        {
            LogName   = 'Microsoft-Windows-Backup'
            Ensure    = 'Absent'
            IsEnabled = $false
        }
    }
}
