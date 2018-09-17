<#
    .EXAMPLE
    Example script that sets the application eventlog
    logmode to 'Circular' with 30 days retention
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
            LogMode            = 'Circular'
            MaximumSizeInBytes = 2048kb
            SecurityDescriptor = 'O:BAG:SYD:(A;;0x7;;;BA)(A;;0x7;;;SO)(A;;0x3;;;IU)(A;;0x3;;;SU)(A;;0x3;;;S-1-5-3)(A;;0x3;;;S-1-5-33)(A;;0x1;;;S-1-5-32-573)'
        } # End of WinEventLog Resource
    } # End of Node
} # End of Configuration
