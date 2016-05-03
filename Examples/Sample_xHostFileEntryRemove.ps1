configuration Sample_xHostFileEntryRemove
{
    param
    (
        [string[]]$NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName xComputerManagement

    Node $NodeName
    {
        xHostFileEntry Contoso
        {
          HostName = "www.contoso.com"
          Ensure = "Absent"
        }
    }
}

Sample_xHostFileEntryRemove
Start-DscConfiguration -Path Sample_xHostFileEntryRemove -Wait -Verbose -Force
