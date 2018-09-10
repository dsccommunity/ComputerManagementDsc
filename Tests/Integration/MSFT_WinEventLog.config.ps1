# Integration Test Config Template Version: 1.0.0
configuration MSFT_WinEventLog_config
 {
    Import-DscResource -ModuleName ComputerManagementDsc

    node 'localhost'
    {
        WinEventLog Integration_Test
        {
            LogName            = 'Application'
            IsEnabled          = $true
            LogMode            = 'Circular'
            MaximumSizeInBytes = '209741943041520'
        }
    }
}
