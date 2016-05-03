Configuration xHostFileEntry_Add {
    Import-DscResource -ModuleName xComputerManagement
    
    node "localhost" {
        xHostFileEntry TestAdd {
            HostName = "www.contoso.com"
            IPAddress = "192.168.0.156"
        }    
    }
}

Configuration xHostFileEntry_Edit {
    Import-DscResource -ModuleName xComputerManagement
    
    node "localhost" {
        xHostFileEntry TestAdd {
            HostName = "www.contoso.com"
            IPAddress = "192.168.0.155"
        }    
    }
}

Configuration xHostFileEntry_Remove {
    Import-DscResource -ModuleName xComputerManagement
    
    node "localhost" {
        xHostFileEntry TestAdd {
            HostName = "www.contoso.com"
            Ensure = "Absent"
        }    
    }
}

Configuration xHostFileEntry_AlreadyGone {
    Import-DscResource -ModuleName xComputerManagement
    
    node "localhost" {
        xHostFileEntry TestAdd {
            HostName = "www.notreallyawebsiteatall.com"
            Ensure = "Absent"
        }    
    }
}
