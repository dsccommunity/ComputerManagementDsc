<#
    .EXAMPLE
    Example script that sets the application Windows Event Log
    logmode to 'Circular' with 30 days retention,
    with a Security Desriptor and enable the log.
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
            LogMode            = 'Circular'
            MaximumSizeInBytes = 2048kb
            SecurityDescriptor = 'O:BAG:SYD:(A;;0x7;;;BA)(A;;0x7;;;SO)(A;;0x3;;;IU)(A;;0x3;;;SU)(A;;0x3;;;S-1-5-3)(A;;0x3;;;S-1-5-33)(A;;0x1;;;S-1-5-32-573)'
        } # End of Windows Event Log Resource
    } # End of Node
} # End of Configuration
