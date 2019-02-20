<#
    .EXAMPLE
    Example script that sets the application Windows Event Log
    to a maximum size 4096MB, the logmode to 'Circular' and ensure that it is enabled.
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
        WindowsEventLog ApplicationEventlogSize
        {
            LogName            = 'Application'
            IsEnabled          = $true
            LogMode            = 'Circular'
            MaximumSizeInBytes = 4096KB
        } # End of Windows Event Log Resource
    } # End of Node
} # End of Configuration
