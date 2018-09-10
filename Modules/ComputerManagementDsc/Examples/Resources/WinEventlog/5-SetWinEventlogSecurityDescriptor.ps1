<#
    .EXAMPLE
    Example script that sets the application eventlog
    logmode to 'Autobackup' with 30 days retention
    and a Security Desriptor.
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
            SecurityDescriptor =
        } # End of WinEventLog Resource
    } # End of Node
} # End of Configuration
