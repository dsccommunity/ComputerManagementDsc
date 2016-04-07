configuration Sample_xOfflineDomainJoin
{
    param
    (
        [string[]]$NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName xComputerManagement

    Node $NodeName
    {
        xOfflineDomainJoin ODJ
        {
          RequestFile = 'C:\ODJ\ODJBlob.txt'
          IsSingleInstance = 'Yes'
        }
    }
}

Sample_xOfflineDomainJoin
Start-DscConfiguration -Path Sample_xOfflineDomainJoin -Wait -Verbose -Force
