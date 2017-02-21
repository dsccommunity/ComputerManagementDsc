function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Drive,

        [ValidateSet("AutoManagePagingFile","CustomSize","SystemManagedSize","NoPagingFile")]
        [System.String]
        $Type,

        [System.Int64]
        $InitialSize,

        [System.Int64]
        $MaximumSize
    )

    $returnValue = @{
        Drive = [string]::Empty
        Type = [string]::Empty
        InitialSize = 0
        MaximumSize = 0
    }

    [bool]$isSystemManaged = (Get-CimInstance -ClassName Win32_ComputerSystem).AutomaticManagedPagefile
    
    if($isSystemManaged) {
        $returnValue.Type = 'AutoManagePagingFile'
        return $returnValue
    }
    
    $driveItem = [System.IO.DriveInfo]$Drive
    $virtualMemoryInstance = Get-CimInstance -ClassName Win32_PageFileSetting | 
    Where-Object {([System.IO.DriveInfo](Split-Path -Name $PSItem.Name)).Name -eq $driveItem.Name}
    
    if(-not $virtualMemoryInstance) {
        $returnValue.Type = 'NoPagingFile'
        return $returnValue
    }

    if($virtualMemoryInstance.InitialSize -eq 0 -and $virtualMemoryInstance.MaximumSize -eq 0) {
        $returnValue.Type = 'SystemManagedSize'
    }
    else {
        $returnValue.Type = "CustomSize"
    }

    $returnValue.InitialSize = $virtualMemoryInstance.InitialSize
    $returnValue.MaximumSize = $virtualMemoryInstance.MaximumSize

    $returnValue
    
}


function Set-TargetResource {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Drive,

        [ValidateSet("AutoManagePagingFile","CustomSize","SystemManagedSize","NoPagingFile")]
        [System.String]
        $Type,

        [System.Int64]
        $InitialSize,

        [System.Int64]
        $MaximumSize
    )
    $SystemInfo = Get-CimInstance -Class Win32_ComputerSystem

    switch($Type) {
        "AutoManagePagingFile" {
            $SystemInfo.AutomaticManagedPageFile = $true
            $SystemInfo | Set-CimInstance
            break
        }
        "CustomSize" {
            if($SystemInfo.AutomaticManagedPageFile) {
                $SystemInfo.AutomaticManagedPageFile = $false
                $SystemInfo | Set-CimInstance
            }

            $driveInfo = [System.IO.DriveInfo]$Drive
            $PageFile = Get-CimInstance -Class Win32_PageFileSetting -Filter "SettingID='pagefile.sys @ $($driveInfo.Name.Substring(0,2))'"
                
            $PageFile.InitialSize = $InitialSize
            $PageFile.MaximumSize = $MaximumSize
            $PageFile | Set-CimInstance
            break
        }
        "SystemManagedSize" {
            if($SystemInfo.AutomaticManagedPageFile) {
                $SystemInfo.AutomaticManagedPageFile = $false
                $SystemInfo | Set-CimInstance
            }

            $driveInfo = [System.IO.DriveInfo]$Drive
            $PageFile = Get-CimInstance -Class Win32_PageFileSetting -Filter "SettingID='pagefile.sys @ $($driveInfo.Name.Substring(0,2))'"
                
            $PageFile.InitialSize = 0
            $PageFile.MaximumSize = 0
            $PageFile | Set-CimInstance
            break
        }
        "NoPagingFile" {
            if($SystemInfo.AutomaticManagedPageFile) {
                $SystemInfo.AutomaticManagedPageFile = $false
                $SystemInfo | Set-CimInstance
            }

            $driveInfo = [System.IO.DriveInfo]$Drive
            $PageFile = Get-CimInstance -Class Win32_PageFileSetting -Filter "SettingID='pagefile.sys @ $($driveInfo.Name.Substring(0,2))'"
                
            if($PageFile) {
                $PageFile | Remove-CimInstance
            }
            break
        }
        default {
            return
        }
    }
    
    $global:DSCMachineStatus = 1
}


function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Drive,

        [ValidateSet("AutoManagePagingFile","CustomSize","SystemManagedSize","NoPagingFile")]
        [System.String]
        $Type,

        [System.Int64]
        $InitialSize,

        [System.Int64]
        $MaximumSize
    )
    $SystemInfo = Get-CimInstance -Class Win32_ComputerSystem
    $result = $false

    switch($Type) {
        "AutoManagePagingFile" {
            $result = $SystemInfo.AutomaticManagedPagefile
            break
        }
        "CustomSize" {
            if($SystemInfo.AutomaticManagedPageFile) {
                $result = $false
                break
            }

            $driveInfo = [System.IO.DriveInfo]$Drive
            $PageFile = Get-CimInstance -Class Win32_PageFileSetting -Filter "SettingID='pagefile.sys @ $($driveInfo.Name.Substring(0,2))'"
            if(-not $PageFile) {
                $result = $false
                break
            }

            if(-not $PageFile.InitialSize -eq $InitialSize -and -not $PageFile.MaximumSize -eq $MaximumSize) {
                $result = $false
                break
            }
            
            $result = $true
            break
        }
        "SystemManagedSize" {
            if($SystemInfo.AutomaticManagedPageFile) {
                $result = $false
                break
            }

            $driveInfo = [System.IO.DriveInfo]$Drive
            $PageFile = Get-CimInstance -Class Win32_PageFileSetting -Filter "SettingID='pagefile.sys @ $($driveInfo.Name.Substring(0,2))'"
            if(-not $PageFile) {
                $result = $false
                break
            }

            if(-not $PageFile.InitialSize -eq 0 -and -not $PageFile.MaximumSize -eq 0) {
                $result = $false
                break
            }
            
            $result = $true
            break
        }
        "NoPagingFile" {
            if($SystemInfo.AutomaticManagedPageFile) {
                $result = $false
                break
            }

            $driveInfo = [System.IO.DriveInfo]$Drive
            $PageFile = Get-CimInstance -Class Win32_PageFileSetting -Filter "SettingID='pagefile.sys @ $($driveInfo.Name.Substring(0,2))'"
                
            if($PageFile) {
                $result = $false
                break
            }

            $result = $true
            break
        }
        default {
            break
        }
    }

    $result
}


Export-ModuleMember -Function *-TargetResource

