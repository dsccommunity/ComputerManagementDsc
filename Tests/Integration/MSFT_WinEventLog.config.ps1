# Integration Test Config Template Version: 1.0.0
configuration MSFT_WinEventLog_config
{
    Import-DSCResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        WinEventLog ApplicationEventlog
        {
            LogName            = "Application"
            IsEnabled          = $true
            LogMode            = "AutoBackup"
            MaximumSizeInBytes = 4096mb
        }
    }
}
