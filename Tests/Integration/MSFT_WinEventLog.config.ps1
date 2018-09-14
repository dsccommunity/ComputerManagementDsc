# Integration Test Config Template Version: 1.0.0
configuration MSFT_WinEventLog_Default
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        WinEventLog Integration_Test
        {
            LogName            = 'Application'
            IsEnabled          = $true
            LogMode            = 'Circular'
            MaximumSizeInBytes = '20971520'
            LogFilePath        = '%SystemRoot%\System32\Winevt\Logs\Application.evtx'
            SecurityDescriptor = 'O:BAG:SYD:(D;; 0xf0007;;;AN)(D;; 0xf0007;;;BG)(A;; 0xf0007;;;SY)(A;; 0x5;;;BA)(A;; 0x7;;;SO)(A;; 0x3;;;IU)(A;; 0x2;;;BA)(A;; 0x2;;;LS)(A;; 0x2;;;NS)'
        }
    }
}

configuration MSFT_WinEventLog_RetainSize
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        WinEventLog Integration_Test
        {
            LogName            = 'Application'
            IsEnabled          = $true
            LogMode            = 'Retain'
            MaximumSizeInBytes = '65536'
        }
    }
}

configuration MSFT_WinEventLog_AutobackupLogRetention
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        WinEventLog Integration_Test
        {
            LogName            = 'Application'
            IsEnabled          = $true
            LogMode            = 'AutoBackup'
            LogRetentionDays   = '30'
        }
    }
}

configuration MSFT_WinEventLog_CircularLogPath
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        WinEventLog Integration_Test
        {
            LogName            = 'Application'
            IsEnabled          = $true
            LogMode            = 'Circular'
            MaximumSizeInBytes = '20971520'
            LogFilePath        = 'C:\temp\Application.evtx'
        }
    }
}

configuration MSFT_WinEventLog_CircularSecurityDescriptor
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        WinEventLog Integration_Test
        {
            LogName            = 'Application'
            IsEnabled          = $true
            LogMode            = 'Circular'
            MaximumSizeInBytes = '20971520'
            SecurityDescriptor = 'O:BAG:SYD:(D;; 0xf0007;;;AN)(A;; 0x7;;;SO)(A;; 0x3;;;IU)'
        }
    }
}
