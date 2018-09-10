<#
    .EXAMPLE
    Example script that sets the application eventlog
    to a maximum size 4096MB.
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
            MaximumSizeInBytes = '4194304'
        } # End of WinEventLog Resource
    } # End of Node
} # End of Configuration
