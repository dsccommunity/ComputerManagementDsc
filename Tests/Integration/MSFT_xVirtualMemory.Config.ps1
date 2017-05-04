Configuration setToAuto
{
    Import-DscResource -ModuleName xComputerManagement
    node "localhost" {
        xVirtualMemory vMem
        {
            Type = 'AutoManagePagingFile'
            Drive = 'C'
        }
    }
}

Configuration setToCustom
{
    Import-DscResource -ModuleName xComputerManagement
    node "localhost" {
        xVirtualMemory vMem
        {
            Type = 'CustomSize'
            Drive = 'C'
            InitialSize = 128
            MaximumSize = 1024
        }
    }
}

Configuration setToSystemManaged
{
    Import-DscResource -ModuleName xComputerManagement
    node "localhost" {
        xVirtualMemory vMem
        {
            Type = 'SystemManagedSize'
            Drive = 'C'
        }
    }
}

Configuration setToNone
{
    Import-DscResource -ModuleName xComputerManagement
    node "localhost" {
        xVirtualMemory vMem
        {
            Type = 'NoPagingFile'
            Drive = 'C'
        }
    }
}
