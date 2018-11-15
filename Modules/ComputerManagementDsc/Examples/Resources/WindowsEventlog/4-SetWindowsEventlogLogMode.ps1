<#
    .EXAMPLE
    Example script that sets the application Windows Event Log
    logmode to 'Autobackup' with 30 days retention and enable it.
#>
Configuration Example
{
    Import-DSCResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        WindowsEventLog ApplicationEventlogSize
        {
            LogName            = 'Application'
            IsEnabled          = $true
            LogMode            = 'AutoBackup'
            LogRetentionDays   = 30
        } # End of Windows Event Log Resource
    } # End of Node
} # End of Configuration
