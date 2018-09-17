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
            MaximumSizeInBytes = 2048kb
            LogFilePath        = '%SystemRoot%\System32\Winevt\Logs\Application.evtx'
            SecurityDescriptor = 'O:BAG:SYD:(A;;0xf0007;;;SY)(A;;0x7;;;BA)(A;;0x7;;;SO)(A;;0x3;;;IU)(A;;0x3;;;SU)(A;;0x3;;;S-1-5-3)(A;;0x3;;;S-1-5-33)(A;;0x1;;;S-1-5-32-573)'
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
            MaximumSizeInBytes = 4096kb
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
            MaximumSizeInBytes = 4096kb
            LogFilePath        = 'C:\temp\Application.evtx'
        }
    }
}

configuration MSFT_WinEventLog_EnableLog
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        WinEventLog Integration_Test
        {
            LogName            = 'Microsoft-Windows-Dsc/Analytic'
            IsEnabled          = $true
            LogMode            = 'Circular'
            MaximumSizeInBytes = 4096kb
        }
    }
}

configuration MSFT_WinEventLog_DisableLog
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        WinEventLog Integration_Test
        {
            LogName            = 'Microsoft-Windows-Dsc/Analytic'
            IsEnabled          = $false
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
            MaximumSizeInBytes = 2048kb
            SecurityDescriptor = 'O:BAG:SYD:(A;;0xf0007;;;SY)(A;;0x7;;;BA)(A;;0x3;;;BO)(A;;0x5;;;SO)(A;;0x1;;;IU)(A;;0x3;;;SU)(A;;0x1;;;S-1-5-3)(A;;0x2;;;S-1-5-33)(A;;0x1;;;S-1-5-32-573)'
        }
    }
}
