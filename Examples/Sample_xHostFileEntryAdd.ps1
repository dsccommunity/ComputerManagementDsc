configuration Sample_xHostFileEntryAdd
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
          IPAddress = "127.0.0.1"
        }
    }
}

Sample_xHostFileEntryAdd
Start-DscConfiguration -Path Sample_xHostFileEntryAdd -Wait -Verbose -Force
