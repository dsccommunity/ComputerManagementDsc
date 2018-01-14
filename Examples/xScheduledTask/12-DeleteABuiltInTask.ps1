<#
    .EXAMPLE
    This example deletes the built-in scheduled task called
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

    Import-DscResource -ModuleName xComputerManagement

    Node $NodeName
    {
        xScheduledTask DeleteCreateExplorerShellUnelevatedTask
        {
            TaskName            = 'CreateExplorerShellUnelevatedTask'
            TaskPath            = '\'
            Ensure              = 'Absent'
        }
    }
}
