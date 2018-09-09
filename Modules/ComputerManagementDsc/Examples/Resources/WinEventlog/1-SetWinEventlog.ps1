<#
    .EXAMPLE
    Example script that sets the application eventlog
    to size maximum size 4096MB
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
        WinEventLog ApplicationEventlog
        {
            LogName            = "Microsoft-Windows-MSPaint/Admin"
            IsEnabled          = $true
            LogMode            = "AutoBackup"
            MaximumSizeInBytes = 4096mb
        }
    }
}
