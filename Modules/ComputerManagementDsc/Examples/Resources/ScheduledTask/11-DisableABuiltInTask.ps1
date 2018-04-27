<#
    .EXAMPLE
    This example disables the built-in scheduled task called
    'CreateExplorerShellUnelevatedTask'.
#>
Configuration Example
{
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost'
    )

    Import-DscResource -ModuleName ComputerManagementDsc

    Node $NodeName
    {
        ScheduledTask DisableCreateExplorerShellUnelevatedTask
        {
            TaskName            = 'CreateExplorerShellUnelevatedTask'
            TaskPath            = '\'
            Enable              = $false
        }
    }
}
