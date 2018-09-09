<#
    .EXAMPLE
    Example script that sets the application eventlog
    to mode AutoBackup and logsize to a maximum size of 4096MB
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
            MaximumSizeInBytes = '20971520'
        } # End of WinEventLog Resource
    } # End of Node
} # End of Configuration
