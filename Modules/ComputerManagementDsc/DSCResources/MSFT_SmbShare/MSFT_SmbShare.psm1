$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the ComputerManagementDsc Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'ComputerManagementDsc.Common' `
            -ChildPath 'ComputerManagementDsc.Common.psm1')) -Force

# Import the ComputerManagementDsc Resource Helper Module
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'ComputerManagementDsc.ResourceHelper' `
            -ChildPath 'ComputerManagementDsc.ResourceHelper.psm1'))

# Import Localization Strings
$script:localizedData = Get-LocalizedData `
    -ResourceName 'MSFT_SmbShare' `
    -ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

<#
    .SYNOPSIS
        Returns the current state of the SMB share.

    .PARAMETER Name
        Specifies the name of the SMB share.

    .PARAMETER Path
        Specifies the path of the SMB share.

        Not used in Get-TargetResource.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Path
    )

    Write-Verbose -Message ($script:localizedData.GetTargetResourceMessage -f $Name)

    $returnValue = @{
        Ensure                = 'Absent'
        Name                  = $Name
        Path                  = $null
        Description           = $null
        ConcurrentUserLimit   = 0
        EncryptData           = $false
        FolderEnumerationMode = $null
        CachingMode           = $null
        ContinuouslyAvailable = $false
        ShareState            = $null
        ShareType             = $null
        ShadowCopy            = $null
        Special               = $null
        ChangeAccess          = @()
        ReadAccess            = @()
        FullAccess            = @()
        NoAccess              = @()
    }

    $smbShare = Get-SmbShare -Name $Name -ErrorAction 'SilentlyContinue'
    if ($smbShare)
    {
        $returnValue['Ensure'] = 'Present'
        $returnValue['Name'] = $smbShare.Name
        $returnValue['Path'] = $smbShare.Path
        $returnValue['Description'] = $smbShare.Description
        $returnValue['ConcurrentUserLimit'] = $smbShare.ConcurrentUserLimit
        $returnValue['EncryptData'] = $smbShare.EncryptData
        $returnValue['FolderEnumerationMode'] = $smbShare.FolderEnumerationMode
        $returnValue['CachingMode'] = $smbShare.CachingMode
        $returnValue['ContinuouslyAvailable'] = $smbShare.ContinuouslyAvailable
        $returnValue['ShareState'] = $smbShare.ShareState
        $returnValue['ShareType'] = $smbShare.ShareType
        $returnValue['ShadowCopy'] = $smbShare.ShadowCopy
        $returnValue['Special'] = $smbShare.Special

        $smbShareAccess = Get-SmbShareAccess -Name $Name
        foreach ($access in $smbShareAccess)
        {
            switch ($access.AccessRight)
            {
                'Change'
                {
                    if ($access.AccessControlType -eq 'Allow')
                    {
                        $returnValue['ChangeAccess'] += @($access.AccountName)
                    }
                }

                'Read'
                {
                    if ($access.AccessControlType -eq 'Allow')
                    {
                        $returnValue['ReadAccess'] += @($access.AccountName)
                    }
                }

                'Full'
                {
                    if ($access.AccessControlType -eq 'Allow')
                    {
                        $returnValue['FullAccess'] += @($access.AccountName)
                    }

                    if ($access.AccessControlType -eq 'Deny')
                    {
                        $returnValue['NoAccess'] += @($access.AccountName)
                    }
                }
            }
        }
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.ShareNotFound -f $Name)
    }

    return $returnValue
}

<#
    .SYNOPSIS
        Creates or removes the SMB share.

    .PARAMETER Name
        Specifies the name of the SMB share.

    .PARAMETER Path
        Specifies the path of the SMB share.

    .PARAMETER Description
        Specifies the description of the SMB share.

    .PARAMETER ConcurrentUserLimit
        Specifies the maximum number of concurrently connected users that the
        new SMB share may accommodate. If this parameter is set to zero (0),
        then the number of users is unlimited. The default value is zero (0).

    .PARAMETER EncryptData
        Indicates that the SMB share is encrypted.

    .PARAMETER FolderEnumerationMode
        Specifies which files and folders in the new SMB share are visible to
        users. { AccessBased | Unrestricted }

    .PARAMETER CachingMode
        Specifies the caching mode of the offline files for the SMB share.
        { 'None' | 'Manual' | 'Programs' | 'Documents' | 'BranchCache' }

    .PARAMETER ContinuouslyAvailable
        Specifies whether the SMB share should be continuously available.

    .PARAMETER FullAccess
        Specifies which accounts are granted full permission to access the
        SMB share.

    .PARAMETER ChangeAccess
        Specifies which user will be granted modify permission to access the
        SMB share.

    .PARAMETER ReadAccess
        Specifies which user is granted read permission to access the SMB share.

    .PARAMETER NoAccess
        Specifies which accounts are denied access to the SMB share.

    .PARAMETER Ensure
        Specifies if the SMB share should be added or removed.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.UInt32]
        $ConcurrentUserLimit,

        [Parameter()]
        [System.Boolean]
        $EncryptData,

        [Parameter()]
        [ValidateSet('AccessBased', 'Unrestricted')]
        [System.String]
        $FolderEnumerationMode,

        [Parameter()]
        [ValidateSet('None', 'Manual', 'Programs', 'Documents', 'BranchCache')]
        [System.String]
        $CachingMode,

        [Parameter()]
        [System.Boolean]
        $ContinuouslyAvailable,

        [Parameter()]
        [System.String[]]
        $FullAccess,

        [Parameter()]
        [System.String[]]
        $ChangeAccess,

        [Parameter()]
        [System.String[]]
        $ReadAccess,

        [Parameter()]
        [System.String[]]
        $NoAccess,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    $PSBoundParameters.Remove('Debug')

    $shareExists = $false
    $smbShare = Get-SmbShare -Name $Name -ErrorAction SilentlyContinue
    if ($smbShare -ne $null)
    {
        Write-Verbose -Message "Share with name $Name exists"
        $shareExists = $true
    }
    if ($Ensure -eq 'Present')
    {
        if ($shareExists -eq $false)
        {
            $PSBoundParameters.Remove('Ensure')
            Write-Verbose "Creating share $Name to ensure it is Present"

            # Alter bound parameters
            $newShareParameters = Get-SmbBoundParameters -BoundParameters $PSBoundParameters

            # Pass the parameter collection to New-SmbShare
            New-SmbShare @newShareParameters
        }
        else
        {
            # Need to call either Set-SmbShare or *ShareAccess cmdlets
            if ($PSBoundParameters.ContainsKey('ChangeAccess'))
            {
                $changeAccessValue = $PSBoundParameters['ChangeAccess']
                $PSBoundParameters.Remove('ChangeAccess')
            }
            if ($PSBoundParameters.ContainsKey('ReadAccess'))
            {
                $readAccessValue = $PSBoundParameters['ReadAccess']
                $PSBoundParameters.Remove('ReadAccess')
            }
            if ($PSBoundParameters.ContainsKey('FullAccess'))
            {
                $fullAccessValue = $PSBoundParameters['FullAccess']
                $PSBoundParameters.Remove('FullAccess')
            }
            if ($PSBoundParameters.ContainsKey('NoAccess'))
            {
                $noAccessValue = $PSBoundParameters['NoAccess']
                $PSBoundParameters.Remove('NoAccess')
            }

            # Use Set-SmbShare for performing operations other than changing access
            $PSBoundParameters.Remove('Ensure')
            $PSBoundParameters.Remove('Path')
            Set-SmbShare @PSBoundParameters -Force

            # Use *SmbShareAccess cmdlets to change access
            $smbShareAccessValues = Get-SmbShareAccess -Name $Name

            # Remove Change permissions
            $smbShareAccessValues | Where-Object { $_.AccessControlType -eq 'Allow' -and $_.AccessRight -eq 'Change' } `
            | ForEach-Object {
                Remove-AccessPermission -Name $Name -UserName $_.AccountName -AccessPermission Change
            }

            if ($ChangeAccess -ne $null)
            {
                # Add change permissions
                $changeAccessValue | ForEach-Object {
                    Set-AccessPermission -Name $Name -AccessPermission 'Change' -Username $_
                }
            }

            $smbShareAccessValues = Get-SmbShareAccess -Name $Name

            # Remove read access
            $smbShareAccessValues | Where-Object { $_.AccessControlType -eq 'Allow' -and $_.AccessRight -eq 'Read' } `
            | ForEach-Object {
                Remove-AccessPermission -Name $Name -UserName $_.AccountName -AccessPermission Read
            }

            if ($ReadAccess -ne $null)
            {
                # Add read access
                $readAccessValue | ForEach-Object {
                    Set-AccessPermission -Name $Name -AccessPermission 'Read' -Username $_
                }
            }


            $smbShareAccessValues = Get-SmbShareAccess -Name $Name

            # Remove full access
            $smbShareAccessValues | Where-Object { $_.AccessControlType -eq 'Allow' -and $_.AccessRight -eq 'Full' } `
            | ForEach-Object {
                Remove-AccessPermission -Name $Name -UserName $_.AccountName -AccessPermission Full
            }


            if ($FullAccess -ne $null)
            {

                # Add full access
                $fullAccessValue | ForEach-Object {
                    Set-AccessPermission -Name $Name -AccessPermission 'Full' -Username $_
                }
            }

            $smbShareAccessValues = Get-SmbShareAccess -Name $Name

            # Remove explicit deny
            $smbShareAccessValues | Where-Object { $_.AccessControlType -eq 'Deny' } `
            | ForEach-Object {
                Remove-AccessPermission -Name $Name -UserName $_.AccountName -AccessPermission No
            }


            if ($NoAccess -ne $null)
            {
                # Add explicit deny
                $noAccessValue | ForEach-Object {
                    Set-AccessPermission -Name $Name -AccessPermission 'No' -Username $_
                }
            }
        }
    }
    else
    {
        Write-Verbose "Removing share $Name to ensure it is Absent"
        Remove-SmbShare -name $Name -Force
    }
}

<#
    .SYNOPSIS
        Determines if the SMB share is in the desired state.

    .PARAMETER Name
        Specifies the name of the SMB share.

    .PARAMETER Path
        Specifies the path of the SMB share.

    .PARAMETER Description
        Specifies the description of the SMB share.

    .PARAMETER ConcurrentUserLimit
        Specifies the maximum number of concurrently connected users that the
        new SMB share may accommodate. If this parameter is set to zero (0),
        then the number of users is unlimited. The default value is zero (0).

    .PARAMETER EncryptData
        Indicates that the SMB share is encrypted.

    .PARAMETER FolderEnumerationMode
        Specifies which files and folders in the new SMB share are visible to
        users. { AccessBased | Unrestricted }

    .PARAMETER CachingMode
        Specifies the caching mode of the offline files for the SMB share.
        { 'None' | 'Manual' | 'Programs' | 'Documents' | 'BranchCache' }

    .PARAMETER ContinuouslyAvailable
        Specifies whether the SMB share should be continuously available.

    .PARAMETER FullAccess
        Specifies which accounts are granted full permission to access the
        SMB share.

    .PARAMETER ChangeAccess
        Specifies which user will be granted modify permission to access the
        SMB share.

    .PARAMETER ReadAccess
        Specifies which user is granted read permission to access the SMB share.

    .PARAMETER NoAccess
        Specifies which accounts are denied access to the SMB share.

    .PARAMETER Ensure
        Specifies if the SMB share should be added or removed.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.UInt32]
        $ConcurrentUserLimit,

        [Parameter()]
        [System.Boolean]
        $EncryptData,

        [Parameter()]
        [ValidateSet('AccessBased', 'Unrestricted')]
        [System.String]
        $FolderEnumerationMode,

        [Parameter()]
        [ValidateSet('None', 'Manual', 'Programs', 'Documents', 'BranchCache')]
        [System.String]
        $CachingMode,

        [Parameter()]
        [System.Boolean]
        $ContinuouslyAvailable,

        [Parameter()]
        [System.String[]]
        $FullAccess,

        [Parameter()]
        [System.String[]]
        $ChangeAccess,

        [Parameter()]
        [System.String[]]
        $ReadAccess,

        [Parameter()]
        [System.String[]]
        $NoAccess,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    Write-Verbose -Message ($script:localizedData.TestTargetResourceMessage -f $Name)

    $testTargetResourceResult = $false

    $getTargetResourceResult = Get-TargetResource -Name $Name -Path $Path

    if ($getTargetResourceResult.Ensure -eq $Ensure )
    {
        if ($Ensure -eq 'Present')
        {
            Write-Verbose -Message ($script:localizedData.IsPresent -f $Name)

            $valuesToCheck = @(
                'Name'
                'Path'
                'Description'
                'ConcurrentUserLimit'
                'EncryptData'
                'FolderEnumerationMode'
                'CachingMode'
                'ContinuouslyAvailable'
                'FullAccess'
                'ChangeAccess'
                'ReadAccess'
                'NoAccess'
            )

            <#
                Using $VerbosePreference so that the verbose messages in
                Test-DscParameterState is outputted, if the user requested
                verbose messages.
            #>
            $testTargetResourceResult = Test-DscParameterState `
                -CurrentValues $getTargetResourceResult `
                -DesiredValues $PSBoundParameters `
                -ValuesToCheck $valuesToCheck `
                -Verbose:$VerbosePreference
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.IsAbsent -f $Name)

            $testTargetResourceResult = $true
        }
    }

    return $testTargetResourceResult
}

function Set-AccessPermission
{
    [CmdletBinding()]
    Param
    (
        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
        [System.String[]]
        $UserName,

        [Parameter()]
        [ValidateSet('Change', 'Full', 'Read', 'No')]
        [System.String]
        $AccessPermission
    )
    $formattedString = '{0}{1}' -f $AccessPermission, 'Access'
    Write-Verbose -Message "Setting $formattedString for $UserName"

    if ($AccessPermission -eq 'Change' -or $AccessPermission -eq 'Read' -or $AccessPermission -eq 'Full')
    {
        Grant-SmbShareAccess -Name $Name -AccountName $UserName -AccessRight $AccessPermission -Force
    }
    else
    {
        Block-SmbShareAccess -Name $Name -AccountName $UserName -Force
    }
}

function Get-SmbBoundParameters
{
    # Define parameters
    Param
    (
        [Parameter()]
        [System.Collections.Hashtable]
        $BoundParameters
    )

    # Check for null access before passing to New-SmbShare
    if (($BoundParameters.ContainsKey('ChangeAccess')) -and ([string]::IsNullOrEmpty($BoundParameters['ChangeAccess'])))
    {
        Write-Verbose "Parameter ChangeAccess is null or empty, removing from collection."
        # Remove the parameter
        $BoundParameters.Remove('ChangeAccess')
    }

    if (($BoundParameters.ContainsKey('ReadAccess')) -and ([string]::IsNullOrEmpty($BoundParameters['ReadAccess'])))
    {
        Write-Verbose "Parameter ReadAccess is null or empty, removing from collection."
        # Remove the parameter
        $BoundParameters.Remove('ReadAccess')
    }

    if (($BoundParameters.ContainsKey('FullAccess')) -and ([string]::IsNullOrEmpty($BoundParameters['FullAccess'])))
    {
        Write-Verbose "Parameter FullAccess is null or empty, removing from collection."
        # Remove the parameter
        $BoundParameters.Remove('FullAccess')
    }

    if (($BoundParameters.ContainsKey('NoAccess')) -and ([string]::IsNullOrEmpty($BoundParameters['NoAccess'])))
    {
        Write-Verbose "Parameter NoAccess is null or empty, removing from collection."
        # Remove the parameter
        $BoundParameters.Remove('NoAccess')
    }

    # Return the parameter collection
    return $BoundParameters
}

function Remove-AccessPermission
{
    [CmdletBinding()]
    Param
    (
        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
        [System.String[]]
        $UserName,

        [Parameter()]
        [ValidateSet('Change', 'Full', 'Read', 'No')]
        [System.String]
        $AccessPermission
    )

    $formattedString = '{0}{1}' -f $AccessPermission, 'Access'

    Write-Debug -Message "Removing $formattedString for $UserName"

    if ($AccessPermission -eq 'Change' -or $AccessPermission -eq 'Read' -or $AccessPermission -eq 'Full')
    {
        Revoke-SmbShareAccess -Name $Name -AccountName $UserName -Force
    }
    else
    {
        Unblock-SmbShareAccess -Name $Name -AccountName $UserName -Force
    }
}
