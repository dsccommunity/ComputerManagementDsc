<#
    .EXAMPLE
    Example script that sets the Dsc Analytic eventlog
    to size maximum size 4096MB, with logmode circular
#>
Configuration Example
{
    Import-DSCResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        WinEventLog Enable-DscAnalytic
        {
            LogName             = 'Microsoft-Windows-Dsc/Analytic'
            IsEnabled           = $True
            LogMode             = 'Retain'
            MaximumSizeInBytes  = 4194304
            LogFilePath         = "%SystemRoot%\System32\Winevt\Logs\Microsoft-Windows-DSC%4Analytic.evtx"
        } # End of WinEventLog Resource
    } # End of Node
} # End of Configuration
