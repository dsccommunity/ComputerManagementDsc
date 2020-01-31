$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the ComputerManagementDsc Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'ComputerManagementDsc.Common' `
            -ChildPath 'ComputerManagementDsc.Common.psm1')) -Force

# Import the ComputerManagementDsc Resource Helper Module
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'ComputerManagementDsc.Common' `
            -ChildPath 'ComputerManagementDsc.Common.psm1'))

# Import Localization Strings
$script:localizedData = Get-LocalizedData -ResourceName 'DSC_SmbShare'

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
        Path                  = [System.String] $null
        Description           = [System.String] $null
        ConcurrentUserLimit   = 0
        EncryptData           = $false
        FolderEnumerationMode = [System.String] $null
        CachingMode           = [System.String] $null
        ContinuouslyAvailable = $false
        ShareState            = [System.String] $null
        ShareType             = [System.String] $null
        ShadowCopy            = $false
        Special               = $false
        ScopeName             = [System.String] $null
    }

    $accountsFullAccess   = [system.string[]] @()
    $accountsChangeAccess = [system.string[]] @()
    $accountsReadAccess   = [system.string[]] @()
    $accountsNoAccess     = [system.string[]] @()

    $smbShare = Get-SmbShare -Name $Name -ErrorAction 'SilentlyContinue'

    if ($smbShare)
    {
        $returnValue['Ensure'] = 'Present'
        $returnValue['Name'] = $smbShare.Name
        $returnValue['Path'] = $smbShare.Path
        $returnValue['Description'] = $smbShare.Description
        $returnValue['ConcurrentUserLimit'] = $smbShare.ConcurrentUserLimit
        $returnValue['EncryptData'] = $smbShare.EncryptData
        $returnValue['FolderEnumerationMode'] = $smbShare.FolderEnumerationMode.ToString()
        $returnValue['CachingMode'] = $smbShare.CachingMode.ToString()
        $returnValue['ContinuouslyAvailable'] = $smbShare.ContinuouslyAvailable
        $returnValue['ShareState'] = $smbShare.ShareState.ToString()
        $returnValue['ShareType'] = $smbShare.ShareType.ToString()
        $returnValue['ShadowCopy'] = $smbShare.ShadowCopy
        $returnValue['Special'] = $smbShare.Special
        $returnValue['ScopeName'] = $smbShare.ScopeName

        $currentSmbShareAccessPermissions = Get-SmbShareAccess -Name $Name

        foreach ($access in $currentSmbShareAccessPermissions)
        {
            switch ($access.AccessRight)
            {
                'Change'
                {
                    if ($access.AccessControlType -eq 'Allow')
                    {
                        $accountsChangeAccess += @($access.AccountName)
                    }
                }

                'Read'
                {
                    if ($access.AccessControlType -eq 'Allow')
                    {
                        $accountsReadAccess += @($access.AccountName)
                    }
                }

                'Full'
                {
                    if ($access.AccessControlType -eq 'Allow')
                    {
                        $accountsFullAccess += @($access.AccountName)
                    }

                    if ($access.AccessControlType -eq 'Deny')
                    {
                        $accountsNoAccess += @($access.AccountName)
                    }
                }
            }
        }
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.ShareNotFound -f $Name)
    }

    <#
        This adds either an empty array, or a populated array depending
        if accounts with the respectively access was found.
    #>
    $returnValue['FullAccess'] = [System.String[]] $accountsFullAccess
    $returnValue['ChangeAccess'] = [System.String[]] $accountsChangeAccess
    $returnValue['ReadAccess'] = [System.String[]] $accountsReadAccess
    $returnValue['NoAccess'] = [System.String[]] $accountsNoAccess

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
        Specifies which accounts will be granted modify permission to access the
        SMB share.

    .PARAMETER ReadAccess
        Specifies which accounts is granted read permission to access the SMB share.

    .PARAMETER NoAccess
        Specifies which accounts are denied access to the SMB share.

    .PARAMETER Ensure
        Specifies if the SMB share should be added or removed.

    .PARAMETER ScopeName
        Specifies the scope in which the share should be created.

    .PARAMETER Force
        Specifies if the SMB share is allowed to be dropped and recreated (required
        when the path changes).
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
        $Ensure = 'Present',

        [Parameter()]
        [System.String]
        $ScopeName = '*',

        [Parameter()]
        [System.Boolean]
        $Force
    )

    Assert-AccessPermissionParameters @PSBoundParameters

    <#
        Copy the $PSBoundParameters to a new hash table, so we have the
        original intact.
    #>
    $smbShareParameters = @{} + $PSBoundParameters

    $currentSmbShareConfiguration = Get-TargetResource -Name $Name -Path $Path

    if ($currentSmbShareConfiguration.Ensure -eq 'Present')
    {
        Write-Verbose -Message ($script:localizedData.IsPresent -f $Name)

        if ($Ensure -eq 'Present')
        {
            if (
                ($currentSmbShareConfiguration.Path -ne $Path -or
                $currentSmbShareConfiguration.ScopeName -ne $ScopeName) -and
                $Force
            )
            {
                Write-Verbose -Message ($script:localizedData.RecreateShare -f $Name)

                try
                {
                    Remove-SmbShare -Name $Name -Force -ErrorAction Stop
                    New-SmbShare -Name $Name -Path $Path -ErrorAction Stop
                }
                catch
                {
                    Write-Error -Message ($script:localizedData.RecreateShareError -f $Name, $_)
                }
            }
            else
            {
                Write-Warning -Message (
                    $script:localizedData.NoRecreateShare -f $Name, $currentSmbShareConfiguration.Path, $Path
                )
            }

            Write-Verbose -Message $script:localizedData.UpdatingProperties

            $parametersToRemove = $smbShareParameters.Keys |
                Where-Object -FilterScript {
                    $_ -in ('ChangeAccess','ReadAccess','FullAccess','NoAccess','Ensure','Path','Force')
                }

            $parametersToRemove | ForEach-Object -Process {
                $smbShareParameters.Remove($_)
            }

            # Use Set-SmbShare for performing operations other than changing access
            Set-SmbShare @smbShareParameters -Force -ErrorAction 'Stop'

            $smbShareAccessPermissionParameters = @{
                Name = $Name
            }

            if ($PSBoundParameters.ContainsKey('FullAccess'))
            {
                $smbShareAccessPermissionParameters['FullAccess'] = $FullAccess
            }

            if ($PSBoundParameters.ContainsKey('ChangeAccess'))
            {
                $smbShareAccessPermissionParameters['ChangeAccess'] = $ChangeAccess
            }

            if ($PSBoundParameters.ContainsKey('ReadAccess'))
            {
                $smbShareAccessPermissionParameters['ReadAccess'] = $ReadAccess
            }

            if ($PSBoundParameters.ContainsKey('NoAccess'))
            {
                $smbShareAccessPermissionParameters['NoAccess'] = $NoAccess
            }

            # We should only pass the access collections that the user wants to enforce.
            Remove-SmbShareAccessPermission @smbShareAccessPermissionParameters

            Add-SmbShareAccessPermission @smbShareAccessPermissionParameters
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.RemoveShare -f $Name)

            Remove-SmbShare -name $Name -Force -ErrorAction 'Stop'
        }
    }
    else
    {
        if ($Ensure -eq 'Present')
        {
            $smbShareParameters.Remove('Ensure')
            $smbShareParameters.Remove('Force')

            Write-Verbose -Message ($script:localizedData.CreateShare -f $Name)

            <#
                Remove access collections that are empty, since empty
                collections are not allowed to be provided to the cmdlet
                New-SmbShare.
            #>
            foreach ($accessProperty in ('ChangeAccess','ReadAccess','FullAccess','NoAccess'))
            {
                if ($smbShareParameters.ContainsKey($accessProperty) -and -not $smbShareParameters[$accessProperty])
                {
                    $smbShareParameters.Remove($accessProperty)
                }
            }

            New-SmbShare @smbShareParameters -ErrorAction 'Stop'
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
        Specifies which accounts will be granted modify permission to access the
        SMB share.

    .PARAMETER ReadAccess
        Specifies which accounts is granted read permission to access the SMB share.

    .PARAMETER NoAccess
        Specifies which accounts are denied access to the SMB share.

    .PARAMETER Ensure
        Specifies if the SMB share should be added or removed.

    .PARAMETER ScopeName
        Specifies the scope in which the share should be created.

    .PARAMETER Force
        Specifies if the SMB share is allowed to be dropped and recreated (required
        when the path changes).
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
        $Ensure = 'Present',

        [Parameter()]
        [System.String]
        $ScopeName = '*',

        [Parameter()]
        [System.Boolean]
        $Force
    )

    $null = $PSBoundParameters.Remove('Force')

    Assert-AccessPermissionParameters @PSBoundParameters

    Write-Verbose -Message ($script:localizedData.TestTargetResourceMessage -f $Name)

    $resourceRequiresUpdate = $false

    $currentSmbShareConfiguration = Get-TargetResource -Name $Name -Path $Path

    if ($currentSmbShareConfiguration.Ensure -eq $Ensure)
    {
        if ($Ensure -eq 'Present')
        {
            Write-Verbose -Message (
                '{0} {1}' -f `
                    ($script:localizedData.IsPresent -f $Name),
                    $script:localizedData.EvaluatingProperties
            )

            <#
                Using $VerbosePreference so that the verbose messages in
                Test-DscParameterState is outputted, if the user requested
                verbose messages.
            #>
            $resourceRequiresUpdate = Test-DscParameterState `
                -CurrentValues $currentSmbShareConfiguration `
                -DesiredValues $PSBoundParameters `
                -Verbose:$VerbosePreference
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.IsAbsent -f $Name)

            $resourceRequiresUpdate = $true
        }
    }

    return $resourceRequiresUpdate
}

<#
    .SYNOPSIS
        Removes the access permission for accounts that are no longer part
        of the respectively access collections (FullAccess, ChangeAccess,
        ReadAccess, and NoAccess).

    .PARAMETER Name
        The name of the SMB share for which to remove access permission.

    .PARAMETER FullAccess
        A string collection of account names that _should have_ full access
        permission. The accounts not in this collection will be removed from
        the SMB share.

    .PARAMETER ChangeAccess
        A string collection of account names that _should have_ change access
        permission. The accounts not in this collection will be removed from
        the SMB share.

    .PARAMETER ReadAccess
        A string collection of account names that _should have_ read access
        permission. The accounts not in this collection will be removed from
        the SMB share.

    .PARAMETER NoAccess
        A string collection of account names that _should be_ denied access
        to the SMB share. The accounts not in this collection will be removed
        from the SMB share.

    .NOTES
        The access permission is only removed if the parameter was passed
        into the function.
#>
function Remove-SmbShareAccessPermission
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

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
        $NoAccess
    )

    $currentSmbShareAccessPermissions = Get-SmbShareAccess -Name $Name

    <#
        First all access must be removed for accounts that should not
        have permission, or should be unblocked (those that was denied
        access). After that we can add new accounts using the function
        Add-SmbShareAccessPermission.
    #>
    foreach ($smbShareAccess in $currentSmbShareAccessPermissions)
    {
        switch ($smbShareAccess.AccessControlType)
        {
            'Allow'
            {
                $shouldRevokeAccess = $false

                foreach ($accessRight in 'Change','Read','Full')
                {
                    $accessRightVariableName = '{0}Access' -f $accessRight
                    $shouldRevokeAccess = $shouldRevokeAccess `
                        -or (
                            $smbShareAccess.AccessRight -eq $accessRight `
                            -and $PSBoundParameters.ContainsKey($accessRightVariableName) `
                            -and $smbShareAccess.AccountName -notin $PSBoundParameters[$accessRightVariableName]
                        )
                }

                if ($shouldRevokeAccess)
                {
                    Write-Verbose -Message ($script:localizedData.RevokeAccess -f $smbShareAccess.AccountName, $Name)

                    Revoke-SmbShareAccess -Name $Name -AccountName $smbShareAccess.AccountName -Force -ErrorAction 'Stop'
                }
            }

            'Deny'
            {
                if ($smbShareAccess.AccessRight -eq 'Full')
                {
                    if ($PSBoundParameters.ContainsKey('NoAccess') -and $smbShareAccess.AccountName -notin $NoAccess)
                    {
                        Write-Verbose -Message ($script:localizedData.UnblockAccess -f $smbShareAccess.AccountName, $Name)

                        Unblock-SmbShareAccess -Name $Name -AccountName $smbShareAccess.AccountName -Force -ErrorAction 'Stop'
                    }
                }
            }
        }
    }
}

<#
    .SYNOPSIS
        Add the access permission to the SMB share for accounts, in the
        respectively access collections (FullAccess, ChangeAccess,
        ReadAccess, and NoAccess), that do not yet have access.

    .PARAMETER Name
        The name of the SMB share to add access permission to.

    .PARAMETER FullAccess
        A string collection of account names that should have full access
        permission. The accounts in this collection will be added to the
        SMB share.

    .PARAMETER ChangeAccess
        A string collection of account names that should have change access
        permission. The accounts in this collection will be added to the
        SMB share.

    .PARAMETER ReadAccess
        A string collection of account names that should have read access
        permission. The accounts in this collection will be added to the
        SMB share.

    .PARAMETER NoAccess
        A string collection of account names that should be denied access
        to the SMB share. The accounts in this collection will be added to
        the SMB share.
#>
function Add-SmbShareAccessPermission
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

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
        $NoAccess
    )

    $currentSmbShareAccessPermissions = Get-SmbShareAccess -Name $Name

    $accessRights = @{
        ReadAccess = 'Read'
        ChangeAccess = 'Change'
        FullAccess = 'Full'
    }

    foreach ($accessRight in $accessRights.GetEnumerator())
    {
        if ($PSBoundParameters.ContainsKey($accessRight.Key))
        {
            # Get already added account names.
            $smbShareAccessObjects = $currentSmbShareAccessPermissions | Where-Object -FilterScript {
                $_.AccessControlType -eq 'Allow' -and
                $_.AccessRight -eq $accessRight.Value
            }

            # Get a collection of just the account names.
            $accessAccountNames = @($smbShareAccessObjects.AccountName)

            $newAccountsToHaveAccess = $PSBoundParameters[$accessRight.Key] | Where-Object -FilterScript {
                $_ -notin $accessAccountNames
            }

            # Add new accounts that should have permission.
            $newAccountsToHaveAccess | ForEach-Object -Process {
                Write-Verbose -Message ($script:localizedData.GrantAccess -f $accessRight.Value, $_, $Name)

                Grant-SmbShareAccess -Name $Name -AccountName $_ -AccessRight $accessRight.Value -Force -ErrorAction 'Stop'
            }
        }
    }

    if ($PSBoundParameters.ContainsKey('NoAccess'))
    {
        # Get already added account names.
        $smbShareNoAccessObjects = $currentSmbShareAccessPermissions | Where-Object -FilterScript {
            $_.AccessControlType -eq 'Deny' -and
            $_.AccessRight -eq 'Full'
        }

        # Get a collection of just the account names.
        $noAccessAccountNames = @($smbShareNoAccessObjects.AccountName)

        $newAccountsToHaveNoAccess = $NoAccess | Where-Object -FilterScript {
            $_ -notin $noAccessAccountNames
        }

        # Add new accounts that should be denied permission.
        $newAccountsToHaveNoAccess | ForEach-Object -Process {
            Write-Verbose -Message ($script:localizedData.DenyAccess -f $_, $Name)

            Block-SmbShareAccess -Name $Name -AccountName  $_ -Force -ErrorAction 'Stop'
        }
    }
}

<#
    .SYNOPSIS
        Assert that not only empty collections are passed in the
        respectively access permission collections (FullAccess,
        ChangeAccess, ReadAccess, and NoAccess).

    .PARAMETER Name
        The name of the SMB share to add access permission to.

    .PARAMETER FullAccess
        A string collection of account names that should have full access
        permission. The accounts in this collection will be added to the
        SMB share.

    .PARAMETER ChangeAccess
        A string collection of account names that should have change access
        permission. The accounts in this collection will be added to the
        SMB share.

    .PARAMETER ReadAccess
        A string collection of account names that should have read access
        permission. The accounts in this collection will be added to the
        SMB share.

    .PARAMETER NoAccess
        A string collection of account names that should be denied access
        to the SMB share. The accounts in this collection will be added to
        the SMB share.

    .PARAMETER RemainingParameters
        Container for the rest of the potentially splatted parameters from
        the $PSBoundParameters object.

    .NOTES
        The group 'Everyone' is automatically given read access by
        the cmdlet New-SmbShare if all access permission parameters
        (FullAccess, ChangeAccess, ReadAccess, NoAccess) is set to @().
        For that reason we need neither of the parameters, or at least
        one to specify an account.
#>
function Assert-AccessPermissionParameters
{
    param
    (
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

        [Parameter(ValueFromRemainingArguments)]
        [System.Collections.Generic.List`1[System.Object]]
        $RemainingParameters
    )

    <#
        First check if ReadAccess is monitored (part of the configuration).
        If it is not monitored, then we don't need to worry if Everyone is
        added.
    #>
    if ($PSBoundParameters.ContainsKey('ReadAccess') -and -not $ReadAccess)
    {
        $fullAccessIsEmpty = $PSBoundParameters.ContainsKey('FullAccess') -and -not $FullAccess
        $changeAccessIsEmpty = $PSBoundParameters.ContainsKey('ChangeAccess') -and -not $ChangeAccess
        $noAccessIsEmpty = $PSBoundParameters.ContainsKey('NoAccess') -and -not $NoAccess

        <#
            If ReadAccess should have no members, then we need at least one
            member in one of the other access permission collections.
        #>
        if ($fullAccessIsEmpty -and $changeAccessIsEmpty -and $noAccessIsEmpty)
        {
            New-InvalidArgumentException -Message $script:localizedData.InvalidAccessParametersCombination -ArgumentName 'FullAccess, ChangeAccess, ReadAccess, NoAccess'
        }
    }
}
