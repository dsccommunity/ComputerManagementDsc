<#
    .EXAMPLE
    Example script that sets the application Windows Event Log
    to a maximum size 4096MB, the logmode to 'Circular' and enable it.
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
            MaximumSizeInBytes = 4096KB
        } # End of Windows Event Log Resource
    } # End of Node
} # End of Configuration
