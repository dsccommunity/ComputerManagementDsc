$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the ComputerManagementDsc Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'ComputerManagementDsc.Common' `
            -ChildPath 'ComputerManagementDsc.Common.psm1'))

Import-Module -Name (Join-Path -Path $modulePath -ChildPath 'DscResource.Common')

# Import Localization Strings
$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        Gets the requested restore point.

    .PARAMETER Ensure
        Indicates whether a restore point should be created or deleted.

    .PARAMETER Description
        Specifies the description of the restore point.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Description
    )

    $returnValue = @{
        Ensure = 'Absent'
    }

    $productType = (Get-CimInstance -ClassName Win32_OperatingSystem).ProductType

    if ($productType -eq 1)
    {
        $latestRestorePoint = Get-ComputerRestorePoint | Select-Object -Last 1

        if ($Description -eq $latestRestorePoint.Description)
        {
            $returnValue.Ensure = 'Present'
            $returnValue.Description = $latestRestorePoint.Description
            $returnValue.RestorePointType = ConvertTo-RestorePointName -Type $latestRestorePoint.RestorePointType
        }
        else
        {
            Write-Verbose -Message $script:localizedData.NoRestorePointsFound
        }
    }
    else
    {
        Write-Warning -Message $script:localizedData.NotWorkstationOS
    }

    return $returnValue
}

<#
    .SYNOPSIS
        Sets the desired state of a restore point.

    .PARAMETER Ensure
        Indicates whether a restore point should be created or deleted.

    .PARAMETER Description
        Specifies the description of the restore point.

    .PARAMETER RestorePointType
        Specifies the restore point type to act upon.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Description,

        [Parameter()]
        [ValidateSet(
            'APPLICATION_INSTALL',
            'APPLICATION_UNINSTALL',
            'DEVICE_DRIVER_INSTALL',
            'MODIFY_SETTINGS',
            'CANCELLED_OPERATION'
        )]
        [System.String]
        $RestorePointType = 'APPLICATION_INSTALL'
    )

    $productType = (Get-CimInstance -ClassName Win32_OperatingSystem).ProductType

    if ($productType -ne 1)
    {
        $message = $script:localizedData.NotWorkstationOS
        New-InvalidOperationException -Message $message
    }

    switch ($Ensure)
    {
        'Present'
        {
            Write-Verbose -Message ($script:localizedData.CreateRestorePoint -f $Description)

            try
            {
                Checkpoint-Computer -Description $Description -RestorePointType $RestorePointType
            }
            catch
            {
                $message = $script:localizedData.CheckpointFailure
                New-InvalidOperationException -Message $message
            }
        }

        'Absent'
        {
            $assemblies = [AppDomain]::CurrentDomain.GetAssemblies()
            $assembly = $assemblies |
                ForEach-Object -Process { $PSItem.GetTypes() } |
                Where-Object -Property FullName -EQ 'SystemRestore.DeleteRestorePoint'

            if ($null -eq $assembly)
            {
                $definition = '[DllImport ("srclient.dll")]public static extern int SRRemoveRestorePoint (int index);'
                Add-Type -MemberDefinition $definition `
                    -Name DeleteRestorePoint -NameSpace SystemRestore -PassThru | Out-Null
            }

            $type = ConvertTo-RestorePointValue -Type $RestorePointType

            $restorePoints = Get-ComputerRestorePoint |
                Where-Object -Property Description -EQ $Description |
                Where-Object -Property RestorePointType -EQ $type

            if ($null -eq $restorePoints)
            {
                Write-Verbose -Message ($script:localizedData.NumRestorePoints -f '0')
            }
            else
            {
                $count = 0
                Write-Verbose -Message ($script:localizedData.NumRestorePoints -f $restorePoints.Count)

                foreach ($restorePoint in $restorePoints)
                {
                    Write-Verbose -Message ($script:localizedData.DeleteRestorePoint -f $count++, $restorePoints.Count)

                    $success = Remove-RestorePoint -RestorePoint $restorePoint

                    if (-not $success)
                    {
                        $message = $script:localizedData.DeleteCheckpointFailure
                        New-InvalidOperationException -Message $message
                    }
                }
            }
        }
    }
}

<#
    .SYNOPSIS
        Tests if the current state is the same as the desired state.

    .PARAMETER Ensure
        Indicates whether a restore point should be present or absent.

    .PARAMETER Description
        Specifies the description to be tested.

    .PARAMETER RestorePointType
        Specifies the restore point type to tested.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Description,

        [Parameter()]
        [ValidateSet(
            'APPLICATION_INSTALL',
            'APPLICATION_UNINSTALL',
            'DEVICE_DRIVER_INSTALL',
            'MODIFY_SETTINGS',
            'CANCELLED_OPERATION'
        )]
        [System.String]
        $RestorePointType = 'APPLICATION_INSTALL'
    )

    $productType = (Get-CimInstance -ClassName Win32_OperatingSystem).ProductType

    if ($productType -eq 1)
    {
        $restorePoint = Get-TargetResource -Ensure 'Present' -Description $Description

        Write-Verbose `
            -Message ($script:localizedData.RestorePointProperties -f $restorePoint.Ensure, $restorePoint.RestorePointType)

        if ($Ensure -eq $restorePoint.Ensure -and $RestorePointType -eq $restorePoint.RestorePointType)
        {
            $inDesiredState = $true
        }
        else
        {
            $inDesiredState = $false
        }
    }
    else
    {
        Write-Warning -Message $script:localizedData.NotWorkstationOS
        Write-Warning -Message $script:localizedData.ReturningTrueToBeSafe
        $inDesiredState = $true
    }

    return $inDesiredState
}

<#
    .SYNOPSIS
        Converts the name of a restore point to a numerical value.

    .PARAMETER Type
        Specifies the type of restore point to convert.
#>
function ConvertTo-RestorePointValue
{
    [CmdletBinding()]
    [OutputType([System.Int32])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Type
    )

    switch ($Type)
    {
        'APPLICATION_INSTALL'      { $value = 0  }
        'APPLICATION_UNINSTALL'    { $value = 1  }
        'DEVICE_DRIVER_INSTALL'    { $value = 10 }
        'MODIFY_SETTINGS'          { $value = 12 }
        'CANCELLED_OPERATION'      { $value = 13 }
    }

    return $value
}

<#
    .SYNOPSIS
        Converts the numerical value of a restore point to a name.

    .PARAMETER Type
        Specifies the type of restore point to convert.
#>
function ConvertTo-RestorePointName
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Type
    )

    switch ($Type)
    {
        0     { $value = 'APPLICATION_INSTALL'   }
        1     { $value = 'APPLICATION_UNINSTALL' }
        10    { $value = 'DEVICE_DRIVER_INSTALL' }
        12    { $value = 'MODIFY_SETTINGS'       }
        13    { $value = 'CANCELLED_OPERATION'   }
    }

    return $value
}

<#
    .SYNOPSIS
        Deletes a restore point.

    .PARAMETER RestorePoint
        Specifies the restore point to delete.
#>
function Remove-RestorePoint
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        $RestorePoint
    )

    $result = [SystemRestore.DeleteRestorePoint]::SRRemoveRestorePoint($RestorePoint.SequenceNumber)

    if ($result -eq 0)
    {
        return $true
    }
    else
    {
        return $false
    }
}

Export-ModuleMember -Function *-TargetResource
