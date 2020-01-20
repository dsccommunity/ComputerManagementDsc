Configuration setToAuto
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node "localhost" {
        VirtualMemory vMem
        {
            Type = 'AutoManagePagingFile'
            Drive = 'C'
        }
    }
}

Configuration setToCustom
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node "localhost" {
        VirtualMemory vMem
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
    Import-DscResource -ModuleName ComputerManagementDsc
    node "localhost" {
        VirtualMemory vMem
        {
            Type = 'SystemManagedSize'
            Drive = 'C'
        }
    }
}

Configuration setToNone
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node "localhost" {
        VirtualMemory vMem
        {
            Type = 'NoPagingFile'
            Drive = 'C'
        }
    }
}
