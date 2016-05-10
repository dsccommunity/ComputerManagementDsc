configuration Sample_xScheduledTask
{
    param
    (
        [string[]]$NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName xComputerManagement

    Node $NodeName
    {
        xScheduledTask MaintenanceScriptExample
        {
          TaskName = "Custom maintenance tasks"
          ActionExecutable = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
          ActionArguments = "-File `"C:\scripts\my custom script.ps1`""
          ScheduleType = "Minutes"
          RepeatInterval = 15
        }
    }
}

Sample_xScheduledTask
Start-DscConfiguration -Path Sample_xScheduledTask -Wait -Verbose -Force
