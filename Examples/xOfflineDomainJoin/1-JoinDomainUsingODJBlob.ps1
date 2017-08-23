<#
    .EXAMPLE
    This example will join the computer to a domain using the ODJ
    request file C:\ODJ\ODJRequest.txt.
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
        xOfflineDomainJoin ODJ
        {
          IsSingleInstance = 'Yes'
          RequestFile      = 'C:\ODJ\ODJBlob.txt'
        }
    }
}
