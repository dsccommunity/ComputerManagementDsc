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
            LogName            = 'Application'
            IsEnabled          = $true
            LogMode            = 'Circular'
            MaximumSizeInBytes = 4096mb
        } # End of WinEventLog Resource
    } # End of Node
} # End of Configuration
