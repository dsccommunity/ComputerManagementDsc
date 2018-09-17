<#
    .EXAMPLE
    Example script that sets the application Eventlog
    logmode to 'Autobackup' with 30 days retention.
#>
Configuration Example
{
    Import-DSCResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        WinEventLog ApplicationEventlogSize
        {
            LogName            = 'Application'
            IsEnabled          = $true
            LogMode            = 'AutoBackup'
            LogRetentionDays   = 30
        } # End of WinEventLog Resource
    } # End of Node
} # End of Configuration
