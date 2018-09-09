<#
    .EXAMPLE
    Example script that sets the application eventlog
    to size maximum size 4096MB
#>
Configuration Example
{
    Import-DSCResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        WinEventLog ApplicationEventlog
        {
            LogName            = "Application"
            IsEnabled          = $true
            LogMode            = "Circular"
            MaximumSizeInBytes = 4096mb
        } # End of WinEventLog Resource
    } # End of Node
} # End of Configuration

Example -OutputPath C:\Temp

Start-DscConfiguration -Path C:\Temp\localhost.mof -Verbose


$before = Get-WinEvent -ListLog "Microsoft-Windows-MSPaint/Admin"
configuration Demo1
{
    Import-DscResource -module ComputerManagementDsc

    WinEventLog Demo1
    {
        LogName            = "Microsoft-Windows-MSPaint/Admin"
        IsEnabled          = $true
        LogMode            = "AutoBackup"
        MaximumSizeInBytes = 20mb
    }
}

Demo1 -OutputPath C:\Temp

Start-DscConfiguration -Path C:\Temp -ComputerName localhost -Verbose -wait -debug


$after = Get-WinEvent -ListLog "Microsoft-Windows-MSPaint/Admin"
$before,$after | format-table -AutoSize LogName,IsEnabled,MaximumSizeInBytes,ProviderLatency,LogMode
Get-DscConfiguration
