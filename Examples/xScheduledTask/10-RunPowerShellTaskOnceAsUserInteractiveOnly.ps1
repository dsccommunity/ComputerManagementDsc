<#
    .EXAMPLE
    This example creates a scheduled task called 'Test task interactive' in the folder
    task folder 'MyTasks' that starts a new powershell process once. The task will
    execute using the credential passed into the $Credential parameter, but only when
    the user contained in the $Credential is logged on.
#>
Configuration Example
{
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [System.Management.Automation.PSCredential]
        $Credential
    )

    Import-DscResource -ModuleName xComputerManagement

    Node $NodeName
    {
        xScheduledTask MaintenanceScriptExample
        {
            TaskName            = 'Test task Interactive'
            TaskPath            = '\MyTasks'
            ActionExecutable    = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType        = 'Once'
            ActionWorkingPath   = (Get-Location).Path
            Enable              = $true
            ExecuteAsCredential = $Credential
            LogonType           = 'Interactive'
        }
    }
}
