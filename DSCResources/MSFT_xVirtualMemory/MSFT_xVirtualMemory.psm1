function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Drive,

        [ValidateSet("AutoManagePagingFile", "CustomSize", "SystemManagedSize", "NoPagingFile")]
        [parameter(Mandatory = $true)]
        [System.String]
        $Type
    )

    Write-Verbose -Message 'Getting current page file settings'

    $returnValue = @{
        Drive = [string]::Empty
        Type = [string]::Empty
        InitialSize = 0
        MaximumSize = 0
    }

    [bool] $isSystemManaged = (Get-CimInstance -ClassName Win32_ComputerSystem).AutomaticManagedPagefile
    
    if ($isSystemManaged)
    {
        $returnValue.Type = 'AutoManagePagingFile'
        return $returnValue
    }    

    $driveItem = [System.IO.DriveInfo] $Drive

    Write-Verbose -Message "Pagefile was not automatically managed. Retrieving detailed page file settings with query Select * from Win32_PageFileSetting where SettingID='pagefile.sys @ $($driveItem.Name.Substring(0,2))'"

    # Find existing page file settings by drive letter
    $virtualMemoryInstance = Get-CimInstance -Namespace root\cimv2 -Query "Select * from Win32_PageFileSetting where SettingID='pagefile.sys @ $($driveItem.Name.Substring(0,2))'"
    
    if (-not $virtualMemoryInstance)
    {
        $returnValue.Type = 'NoPagingFile'
        return $returnValue
    }

    if ($virtualMemoryInstance.InitialSize -eq 0 -and $virtualMemoryInstance.MaximumSize -eq 0)
    {
        $returnValue.Type = 'SystemManagedSize'
    }
    else
    {
        $returnValue.Type = "CustomSize"
    }

    $returnValue.Drive = $virtualMemoryInstance.Name.Substring(0, 3)
    $returnValue.InitialSize = $virtualMemoryInstance.InitialSize
    $returnValue.MaximumSize = $virtualMemoryInstance.MaximumSize

    $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Drive,

        [ValidateSet("AutoManagePagingFile", "CustomSize", "SystemManagedSize", "NoPagingFile")]
        [parameter(Mandatory = $true)]
        [System.String]
        $Type,

        [System.Int64]
        $InitialSize,

        [System.Int64]
        $MaximumSize
    )

    Write-Verbose -Message 'Setting page file'

    $SystemInfo = Get-CimInstance -Class Win32_ComputerSystem

    switch ($Type)
    {
        "AutoManagePagingFile" 
        {
            $setParams = @{ 
                Namespace = 'root\cimv2' 
                Query = 'Select * from Win32_ComputerSystem' 
                Property = @{AutomaticManagedPageFile = $true} 
            } 

            Write-Verbose -Message 'Enabling AutoManagePagingFile'

            Set-CimInstance @setParams
            $global:DSCMachineStatus = 1
            break
        }
        "CustomSize"
        {
            if ($SystemInfo.AutomaticManagedPageFile)
            {
                # First set AutomaticManagedPageFile to $false to be able to set a custom one later

                $setParams = @{ 
                    Namespace = 'root\cimv2' 
                    Query = 'Select * from Win32_ComputerSystem' 
                    Property = @{AutomaticManagedPageFile = $false} 
                } 

                Write-Verbose -Message 'Disabling AutoManagePagingFile'

                Set-CimInstance @setParams
            }

            $driveInfo = [System.IO.DriveInfo] $Drive
            if (-not $driveInfo.IsReady)
            {
                throw "Drive $($driveInfo.Name) is not ready. Please ensure that the drive exists and is available"
            }

            $pageFileName = Join-Path -Path $driveInfo.Name -ChildPath 'pagefile.sys'

            Write-Verbose -Message ('Checking if a paging file already exists at {0}' -f $pageFileName)
            $existingPageFileSetting = Get-CimInstance -Namespace root\cimv2 -Query "Select * from Win32_PageFileSetting where SettingID='pagefile.sys @ $($driveInfo.Name.Substring(0,2))'"
            if (-not $existingPageFileSetting)
            {
                [void] (New-CimInstance -Namespace 'root\cimv2' -ClassName 'Win32_PageFileSetting' -Property @{Name = $pageFileName})
            }            

            <# 
            New-CimInstance does not support properties InitialSize and MaximumSize. Therefore, create
            a New-CimInstance with the page file name only if it does not exist and Set-CimInstance on the instance
            #>
            $setParams = @{ 
                Namespace = 'root\cimv2' 
                Query = "Select * from Win32_PageFileSetting where SettingID='pagefile.sys @ $($driveInfo.Name.Substring(0,2))'"
                Property = @{
                    InitialSize = $InitialSize
                    MaximumSize = $MaximumSize
                } 
            } 

            Write-Verbose -Message ("Setting page file to {0}. Initial size {1}MB, maximum size {2}MB" -f $pageFileName, $InitialSize, $MaximumSize)

            Set-CimInstance @setParams
            $global:DSCMachineStatus = 1
            break
        }
        "SystemManagedSize"
        {
            if ($SystemInfo.AutomaticManagedPageFile)
            {
                $setParams = @{ 
                    Namespace = 'root\cimv2' 
                    Query = 'Select * from Win32_ComputerSystem' 
                    Property = @{AutomaticManagedPageFile = $false} 
                } 

                Write-Verbose -Message 'Disabling AutoManagePagingFile'

                Set-CimInstance @setParams
            }

            $driveInfo = [System.IO.DriveInfo] $Drive
            if (-not $driveInfo.IsReady)
            {
                throw "Drive $($driveInfo.Name) is not ready. Please ensure that the drive exists and is available"
            }

            $pageFileName = Join-Path -Path $driveInfo.Name -ChildPath 'pagefile.sys'

            Write-Verbose -Message ('Checking if a paging file already exists at {0}' -f $pageFileName)

            $existingPageFileSetting = Get-CimInstance -Namespace root\cimv2 -Query "Select * from Win32_PageFileSetting where SettingID='pagefile.sys @ $($driveInfo.Name.Substring(0,2))'"
            if (-not $existingPageFileSetting)
            {
                [void] (New-CimInstance -Namespace 'root\cimv2' -ClassName 'Win32_PageFileSetting' -Property @{Name = $pageFileName})
            }
            

            $setParams = @{ 
                Namespace = 'root\cimv2' 
                Query = "Select * from Win32_PageFileSetting where SettingID='pagefile.sys @ $($driveInfo.Name.Substring(0,2))'"
                Property = @{
                    InitialSize = 0
                    MaximumSize = 0
                } 
            } 

            Write-Verbose -Message "Enabling system-managed page file on $pageFileName"

            Set-CimInstance @setParams
            $global:DSCMachineStatus = 1
            break
        }
        "NoPagingFile"
        {
            if ($SystemInfo.AutomaticManagedPageFile)
            {
                $setParams = @{ 
                    Namespace = 'root\cimv2' 
                    Query = 'Select * from Win32_ComputerSystem' 
                    Property = @{AutomaticManagedPageFile = $false} 
                } 

                Set-CimInstance @setParams
            }

            $driveInfo = [System.IO.DriveInfo] $Drive
            if (-not $driveInfo.IsReady)
            {
                throw "Drive $($driveInfo.Name) is not ready. Please ensure that the drive exists and is available"
            }

            $PageFile = Get-CimInstance -Class Win32_PageFileSetting -Filter "SettingID='pagefile.sys @ $($driveInfo.Name.Substring(0,2))'"
                
            $existingPageFileSetting = Get-CimInstance -Namespace root\cimv2 -Query "Select * from Win32_PageFileSetting where SettingID='pagefile.sys @ $($driveInfo.Name.Substring(0,2))'"
            if ($existingPageFileSetting)
            {
                Write-Verbose -Message "Removing existing page file $($existingPageFileSetting.Name)"
                Remove-CimInstance -InputObject $existingPageFileSetting
                $global:DSCMachineStatus = 1
            }

            Write-Verbose -Message "Disabled page file for drive $Drive"

            break
        }
        default
        {
            throw "A wrong type '$Type' has been selected."
        }
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Drive,

        [ValidateSet("AutoManagePagingFile", "CustomSize", "SystemManagedSize", "NoPagingFile")]
        [parameter(Mandatory = $true)]
        [System.String]
        $Type,

        [System.Int64]
        $InitialSize,

        [System.Int64]
        $MaximumSize
    )

    $SystemInfo = Get-CimInstance -Class Win32_ComputerSystem
    $result = $false

    switch ($Type)
    {
        "AutoManagePagingFile"
        {
            $result = $SystemInfo.AutomaticManagedPagefile
            break
        }
        "CustomSize"
        {
            if ($SystemInfo.AutomaticManagedPageFile)
            {
                $result = $false
                break
            }

            $driveInfo = [System.IO.DriveInfo] $Drive
            $PageFile = Get-CimInstance -Class Win32_PageFileSetting -Filter "SettingID='pagefile.sys @ $($driveInfo.Name.Substring(0,2))'"
            if (-not $PageFile)
            {
                $result = $false
                break
            }

            if (-not ($PageFile.InitialSize -eq $InitialSize -and $PageFile.MaximumSize -eq $MaximumSize))
            {
                $result = $false
                break
            }
            
            $result = $true
            break
        }
        "SystemManagedSize"
        {
            if ($SystemInfo.AutomaticManagedPageFile)
            {
                $result = $false
                break
            }

            $driveInfo = [System.IO.DriveInfo] $Drive
            $PageFile = Get-CimInstance -Class Win32_PageFileSetting -Filter "SettingID='pagefile.sys @ $($driveInfo.Name.Substring(0,2))'"
            if (-not $PageFile)
            {
                $result = $false
                break
            }

            if (-not ($PageFile.InitialSize -eq 0 -and $PageFile.MaximumSize -eq 0))
            {
                $result = $false
                break
            }
            
            $result = $true
            break
        }
        "NoPagingFile"
        {
            if ($SystemInfo.AutomaticManagedPageFile)
            {
                $result = $false
                break
            }

            $driveInfo = [System.IO.DriveInfo] $Drive
            $PageFile = Get-CimInstance -Class Win32_PageFileSetting -Filter "SettingID='pagefile.sys @ $($driveInfo.Name.Substring(0,2))'"
                
            if ($PageFile)
            {
                $result = $false
                break
            }

            $result = $true
            break
        }
        default
        {
            break
        }
    }

    $result
}

Export-ModuleMember -Function *-TargetResource
