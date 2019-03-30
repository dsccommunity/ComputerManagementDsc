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

        $getSmbShareAccessResult = Get-SmbShareAccess -Name $Name
        foreach ($access in $getSmbShareAccessResult)
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

    $smbShareParameters = $PSBoundParameters.Clone()

    $smbShare = Get-SmbShare -Name $Name -ErrorAction 'SilentlyContinue'
    if ($smbShare)
    {
        Write-Verbose -Message "Share with name $Name exists"

        if ($Ensure -eq 'Present')
        {
            $parametersToRemove = $smbShareParameters.Keys |
                Where-Object -FilterScript {
                    $_ -in ('ChangeAccess','ReadAccess','FullAccess','NoAccess','Ensure','Path')
                }

            $parametersToRemove | ForEach-Object {
                $smbShareParameters.Remove($_)
            }

            # Use Set-SmbShare for performing operations other than changing access
            Set-SmbShare @smbShareParameters -Force

            <#
                Get a collection of all accounts that currently have access
                or are denied access
            #>
            $getSmbShareAccessResult = Get-SmbShareAccess -Name $Name

            <#
                First all access must be removed for accounts that should not
                have permission, or should be unblocked (those that was denied
                access). After that we add new accounts.

                The switch-statement will loop through all items in the
                collection.
            #>
            switch ($getSmbShareAccessResult.AccessControlType)
            {
                'Allow'
                {
                    $removeAccessPermissionParameters = @{
                        Name = $Name
                        UserName = $_.AccountName
                    }

                    if ($_.AccessRight -eq 'Change' -and $_.AccountName -notin $ChangeAccess)
                    {
                        $removeAccessPermissionParameters['AccessPermission'] = 'ChangeAccess'
                        Remove-AccessPermission @removeAccessPermissionParameters
                    }

                    if ($_.AccessRight -eq 'Read' -and $_.AccountName -notin $ReadAccess)
                    {
                        $removeAccessPermissionParameters['AccessPermission'] = 'ReadAccess'
                        Remove-AccessPermission @removeAccessPermissionParameters
                    }

                    if ($_.AccessRight -eq 'Full' -and $_.AccountName -notin $FullAccess)
                    {
                        $removeAccessPermissionParameters['AccessPermission'] = 'FullAccess'
                        Remove-AccessPermission @removeAccessPermissionParameters
                    }
                }

                'Deny'
                {
                    if ($_.AccessRight -eq 'Full' -and $_.AccountName -notin $NoAccess)
                    {
                        Remove-AccessPermission -Name $Name -UserName $_.AccountName -AccessPermission 'NoAccess'
                    }
                }
            }

            # Update the collection after all accounts have been removed.
            $getSmbShareAccessResult = Get-SmbShareAccess -Name $Name

            if ($ChangeAccess)
            {
                # Get already added account names.
                $changeAccessAccountNames = $getSmbShareAccessResult | Where-Object -FilterScript {
                    $_.AccessControlType -eq 'Allow' `
                    -and $_.AccessRight -eq 'Change'
                }

                $newAccountsToHaveChangeAccess = $ChangeAccess | Where-Object -FilterScript {
                    $_ -notin $changeAccessAccountNames
                }

                # Add new accounts that should have change permission.
                $newAccountsToHaveChangeAccess | ForEach-Object {
                    Set-AccessPermission -Name $Name -AccessPermission 'ChangeAccess' -Username $_
                }
            }

            if ($ReadAccess)
            {
                # Get already added account names.
                $readAccessAccountNames = $getSmbShareAccessResult | Where-Object -FilterScript {
                    $_.AccessControlType -eq 'Allow' `
                    -and $_.AccessRight -eq 'Read'
                }

                $newAccountsToHaveReadAccess = $ReadAccess | Where-Object -FilterScript {
                    $_ -notin $readAccessAccountNames
                }

                # Add new accounts that should have read permission.
                $newAccountsToHaveReadAccess | ForEach-Object {
                    Set-AccessPermission -Name $Name -AccessPermission 'ReadAccess' -Username $_
                }
            }

            if ($FullAccess)
            {
                # Get already added account names.
                $fullAccessAccountNames = $getSmbShareAccessResult | Where-Object -FilterScript {
                    $_.AccessControlType -eq 'Allow' `
                    -and $_.AccessRight -eq 'Full'
                }

                $newAccountsToHaveFullAccess = $FullAccess | Where-Object -FilterScript {
                    $_ -notin $fullAccessAccountNames
                }

                # Add new accounts that should have full permission.
                $newAccountsToHaveFullAccess | ForEach-Object {
                    Set-AccessPermission -Name $Name -AccessPermission 'FullAccess' -Username $_
                }
            }

            if ($NoAccess)
            {
                # Get already added account names.
                $noAccessAccountNames = $getSmbShareAccessResult | Where-Object -FilterScript {
                    $_.AccessControlType -eq 'Deny' `
                    -and $_.AccessRight -eq 'Full'
                }

                $newAccountsToHaveNoAccess = $NoAccess | Where-Object -FilterScript {
                    $_ -notin $noAccessAccountNames
                }

                # Add new accounts that should be denied permission.
                $newAccountsToHaveNoAccess | ForEach-Object {
                    Set-AccessPermission -Name $Name -AccessPermission 'NoAccess' -Username $_
                }
            }
        }
        else
        {
            Write-Verbose "Removing share $Name to ensure it is Absent"
            Remove-SmbShare -name $Name -Force
        }
    }
    else
    {
        if ($Ensure -eq 'Present')
        {
            $smbShareParameters.Remove('Ensure')

            Write-Verbose "Creating share $Name to ensure it is Present"

            <#
                Remove access collections that are empty, since that is
                already the default for the cmdlet New-SmbShare.
            #>
            foreach ($accessProperty in ('ChangeAccess','ReadAccess','FullAccess','NoAccess'))
            {
                if ($smbShareParameters.ContainsKey($accessProperty) -and -not $smbShareParameters[$accessProperty])
                {
                    Write-Verbose "Parameter $accessProperty is null or empty, removing from collection."
                    $smbShareParameters.Remove($accessProperty)
                }
            }

            # Pass the parameter collection to New-SmbShare
            New-SmbShare @smbShareParameters
        }
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
        [ValidateSet('ChangeAccess', 'FullAccess', 'ReadAccess', 'NoAccess')]
        [System.String]
        $AccessPermission
    )

    $formattedString = '{0}{1}' -f $AccessPermission, 'Access'
    Write-Verbose -Message "Setting $formattedString for $UserName"

    if ($AccessPermission -in ('ChangeAccess', 'ReadAccess', 'FullAccess'))
    {
        Grant-SmbShareAccess -Name $Name -AccountName $UserName -AccessRight $AccessPermission -Force
    }
    else
    {
        Block-SmbShareAccess -Name $Name -AccountName $UserName -Force
    }
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
        [ValidateSet('ChangeAccess', 'FullAccess', 'ReadAccess', 'NoAccess')]
        [System.String]
        $AccessPermission
    )

    $formattedString = '{0}{1}' -f $AccessPermission, 'Access'

    Write-Debug -Message "Removing $formattedString for $UserName"

    if ($AccessPermission -in ('ChangeAccess', 'ReadAccess', 'FullAccess'))
    {
        Revoke-SmbShareAccess -Name $Name -AccountName $UserName -Force
    }
    else
    {
        Unblock-SmbShareAccess -Name $Name -AccountName $UserName -Force
    }
}
