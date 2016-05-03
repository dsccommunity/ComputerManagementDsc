Configuration xHostFileEntry_Add {
    Import-DscResource -ModuleName xComputerManagement
    
    xHostFileEntry TestAdd {
        HostName = "www.contoso.com"
        IPAddress = "192.168.0.156"
    }
}
            