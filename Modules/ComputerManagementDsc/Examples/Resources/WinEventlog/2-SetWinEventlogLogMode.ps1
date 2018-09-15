<#
    .EXAMPLE
    Example script that sets the application eventlog
    to mode AutoBackup and logsize to a maximum size of 2048MB
    with a logfile retention for 10 days.
#>
Configuration Example
{
    Import-DSCResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        WinEventLog ApplicationEventlogMode
        {
            LogName            = 'Microsoft-Windows-MSPaint/Admin'
            IsEnabled          = $true
            LogMode            = 'AutoBackup'
            LogRetentionDays   = '10'
            MaximumSizeInBytes = '2097152'
        } # End of WinEventLog Resource
    } # End of Node
} # End of Configuration
