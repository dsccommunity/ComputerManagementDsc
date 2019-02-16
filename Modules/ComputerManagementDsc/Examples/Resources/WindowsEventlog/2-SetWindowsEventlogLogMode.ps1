<#
    .EXAMPLE
    Example script that sets the application Windows Event Log
    to mode AutoBackup and logsize to a maximum size of 2048MB
    with a logfile retention for 10 days and ensure it is enabled.
#>
Configuration Example
{
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName ComputerManagementDsc

    Node $NodeName
    {
        WindowsEventLog ApplicationEventlogMode
        {
            LogName            = 'Microsoft-Windows-MSPaint/Admin'
            IsEnabled          = $true
            LogMode            = 'AutoBackup'
            LogRetentionDays   = '10'
            MaximumSizeInBytes = 2048kb
        } # End of Windows Event Log Resource
    } # End of Node
} # End of Configuration
