<#
    .EXAMPLE
    Example script that sets the paging file to reside on
    drive C with the custom size 2048MB
#>
Configuration Example
{
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName xComputerManagement

    Node $NodeName
    {
        xVirtualMemory pagingSettings
        {
            Type        = 'CustomSize'
            Drive       = 'C'
            InitialSize = '2048'
            MaximumSize = '2048'
        }
    }
}
