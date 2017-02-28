<#
.SYNOPSIS
    Example to set the paging file
.DESCRIPTION
    Example script that sets the paging file to reside on drive C with the custom size 2048MB
#>
configuration Sample_xVirtualMemory
{
    param
    (
        [Parameter()]
        [String[]]
        $NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName xComputerManagement

    node $NodeName
    {
        xVirtualMemory pagingSettings
        {
            Type = "CustomSize"
            Drive = "C"
            InitialSize = "2048"
            MaximumSize = "2048"
        }
    }
}

Sample_xVirtualMemory
Start-DscConfiguration -Path Sample_xVirtualMemory -Wait -verbose -Force
