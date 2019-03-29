# Integration Test Config Template Version: 1.0.0
configuration MSFT_WindowsEventLog_Default
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        WindowsEventLog Integration_Test
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

configuration MSFT_WindowsEventLog_RetainSize
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        WindowsEventLog Integration_Test
        {
            LogName            = 'Application'
            IsEnabled          = $true
            LogMode            = 'Retain'
            MaximumSizeInBytes = 4096kb
        }
    }
}

configuration MSFT_WindowsEventLog_AutobackupLogRetention
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        WindowsEventLog Integration_Test
        {
            LogName            = 'Application'
            IsEnabled          = $true
            LogMode            = 'AutoBackup'
            LogRetentionDays   = '30'
        }
    }
}

configuration MSFT_WindowsEventLog_CircularLogPath
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        WindowsEventLog Integration_Test
        {
            LogName            = 'Application'
            IsEnabled          = $true
            LogMode            = 'Circular'
            MaximumSizeInBytes = 4096kb
            LogFilePath        = 'C:\temp\Application.evtx'
        }
    }
}

configuration MSFT_WindowsEventLog_EnableLog
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        WindowsEventLog Integration_Test
        {
            LogName            = 'Microsoft-Windows-CAPI2/Operational'
            IsEnabled          = $true
            LogMode            = 'Circular'
            MaximumSizeInBytes = 1028kb
        }
    }
}

configuration MSFT_WindowsEventLog_DisableLog
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        WindowsEventLog Integration_Test
        {
            LogName            = 'Microsoft-Windows-CAPI2/Operational'
            IsEnabled          = $false
        }
    }
}

configuration MSFT_WindowsEventLog_CircularSecurityDescriptor
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        WindowsEventLog Integration_Test
        {
            LogName            = 'Application'
            IsEnabled          = $true
            LogMode            = 'Circular'
            MaximumSizeInBytes = 2048kb
            SecurityDescriptor = 'O:BAG:SYD:(A;;0xf0007;;;SY)(A;;0x7;;;BA)(A;;0x3;;;BO)(A;;0x5;;;SO)(A;;0x1;;;IU)(A;;0x3;;;SU)(A;;0x1;;;S-1-5-3)(A;;0x2;;;S-1-5-33)(A;;0x1;;;S-1-5-32-573)'
        }
    }
}

configuration MSFT_WindowsEventLog_EnableBackupLog
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        WindowsEventLog Integration_Test
        {
            LogName            = 'Microsoft-Windows-Backup'
            IsEnabled          = $true
            LogMode            = 'AutoBackup'
            LogRetentionDays   = '30'
        }
    }
}

configuration MSFT_WindowsEventLog_DisableBackupLog
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        WindowsEventLog Integration_Test
        {
            LogName            = 'Microsoft-Windows-Backup'
            IsEnabled          = $false
        }
    }
}
