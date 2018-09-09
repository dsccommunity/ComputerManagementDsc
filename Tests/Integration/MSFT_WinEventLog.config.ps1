# Integration Test Config Template Version: 1.0.0
configuration MSFT_WinEventLog_configLogSize
{
    Import-DSCResource -ModuleName ComputerManagementDsc
    node localhost
    {
        WinEventLog WinEventLog_configLogSize
        {
            LogName            = "Application"
            IsEnabled          = $true
            LogMode            = "Circular"
            MaximumSizeInBytes = '209741943041520'
        }
    }
}

configuration MSFT_WinEventLog_configLogModeLogSize
{
    Import-DSCResource -ModuleName ComputerManagementDsc
    node localhost
    {
        WinEventLog WinEventLog_configLogModeLogSize
        {
            LogName            = "Microsoft-Windows-MSPaint/Admin"
            IsEnabled          = $true
            LogMode            = "AutoBackup"
            MaximumSizeInBytes = '4194304'
        }
    }
}
