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
        $returnValue['ShareState'] = [System.String] $smbShare.ShareState
        $returnValue['ShareType'] = [System.String] $smbShare.ShareType
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

    Assert-AccessPermissionParameters @PSBoundParameters

    <#
        Copy the $PSBoundParameters to a new hash table, so we have the
        original intact.
    #>
    $smbShareParameters = @{} + $PSBoundParameters

    $getTargetResourceResult = Get-TargetResource -Name $Name -Path $Path
    if ($getTargetResourceResult.Ensure -eq 'Present')
    {
        Write-Verbose -Message ($script:localizedData.IsPresent -f $Name)

        if ($Ensure -eq 'Present')
        {
            Write-Verbose -Message $script:localizedData.UpdatingProperties

            $parametersToRemove = $smbShareParameters.Keys |
                Where-Object -FilterScript {
                    $_ -in ('ChangeAccess','ReadAccess','FullAccess','NoAccess','Ensure','Path')
                }

            # TODO: Make sure to remove parameters that already are in desired state.

            $parametersToRemove | ForEach-Object {
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

            # We should only pass the access collections that the user want to enforce.
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

    Assert-AccessPermissionParameters @PSBoundParameters

    Write-Verbose -Message ($script:localizedData.TestTargetResourceMessage -f $Name)

    $testTargetResourceResult = $false

    $getTargetResourceResult = Get-TargetResource -Name $Name -Path $Path

    if ($getTargetResourceResult.Ensure -eq $Ensure )
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
            $testTargetResourceResult = Test-DscParameterState `
                -CurrentValues $getTargetResourceResult `
                -DesiredValues $PSBoundParameters `
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

    <#
        Get a collection of all accounts that currently have access
        or are denied access
    #>
    $getSmbShareAccessResult = Get-SmbShareAccess -Name $Name

    <#
        First all access must be removed for accounts that should not
        have permission, or should be unblocked (those that was denied
        access). After that we add new accounts.
    #>
    foreach ($smbShareAccess in $getSmbShareAccessResult)
    {
        switch ($smbShareAccess.AccessControlType)
        {
            'Allow'
            {
                $shouldRevokeAccess = $false

                if ($smbShareAccess.AccessRight -eq 'Change')
                {
                    if ($PSBoundParameters.ContainsKey('ChangeAccess') -and $smbShareAccess.AccountName -notin $ChangeAccess)
                    {
                        $shouldRevokeAccess = $true
                    }
                }

                if ($smbShareAccess.AccessRight -eq 'Read')
                {
                    if ($PSBoundParameters.ContainsKey('ReadAccess') -and $smbShareAccess.AccountName -notin $ReadAccess)
                    {
                        $shouldRevokeAccess = $true
                    }
                }

                if ($smbShareAccess.AccessRight -eq 'Full')
                {
                    if ($PSBoundParameters.ContainsKey('FullAccess') -and $smbShareAccess.AccountName -notin $FullAccess)
                    {
                        $shouldRevokeAccess = $true
                    }
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

    # Update the collection after all accounts have been removed.
    $getSmbShareAccessResult = Get-SmbShareAccess -Name $Name

    if ($PSBoundParameters.ContainsKey('ChangeAccess'))
    {
        # Get already added account names.
        $smbShareChangeAccessObjects = $getSmbShareAccessResult | Where-Object -FilterScript {
            $_.AccessControlType -eq 'Allow' `
            -and $_.AccessRight -eq 'Change'
        }

        # Get a collection of just the account names.
        $changeAccessAccountNames = @($smbShareChangeAccessObjects.AccountName)

        $newAccountsToHaveChangeAccess = $ChangeAccess | Where-Object -FilterScript {
            $_ -notin $changeAccessAccountNames
        }

        $accessRight = 'Change'

        # Add new accounts that should have change permission.
        $newAccountsToHaveChangeAccess | ForEach-Object {
            Write-Verbose -Message ($script:localizedData.GrantAccess -f $accessRight, $_, $Name)

            Grant-SmbShareAccess -Name $Name -AccountName $_ -AccessRight $accessRight -Force -ErrorAction 'Stop'
        }
    }

    if ($PSBoundParameters.ContainsKey('ReadAccess'))
    {
        # Get already added account names.
        $smbShareReadAccessObjects = $getSmbShareAccessResult | Where-Object -FilterScript {
            $_.AccessControlType -eq 'Allow' `
            -and $_.AccessRight -eq 'Read'
        }

        # Get a collection of just the account names.
        $readAccessAccountNames = @($smbShareReadAccessObjects.AccountName)

        $newAccountsToHaveReadAccess = $ReadAccess | Where-Object -FilterScript {
            $_ -notin $readAccessAccountNames
        }

        $accessRight = 'Read'

        # Add new accounts that should have read permission.
        $newAccountsToHaveReadAccess | ForEach-Object {
            Write-Verbose -Message ($script:localizedData.GrantAccess -f $accessRight, $_, $Name)

            Grant-SmbShareAccess -Name $Name -AccountName $_ -AccessRight $accessRight -Force -ErrorAction 'Stop'
        }
    }

    if ($PSBoundParameters.ContainsKey('FullAccess'))
    {
        # Get already added account names.
        $smbShareFullAccessObjects = $getSmbShareAccessResult | Where-Object -FilterScript {
            $_.AccessControlType -eq 'Allow' `
            -and $_.AccessRight -eq 'Full'
        }

        # Get a collection of just the account names.
        $fullAccessAccountNames = @($smbShareFullAccessObjects.AccountName)

        $newAccountsToHaveFullAccess = $FullAccess | Where-Object -FilterScript {
            $_ -notin $fullAccessAccountNames
        }

        $accessRight = 'Full'

        # Add new accounts that should have full permission.
        $newAccountsToHaveFullAccess | ForEach-Object {
            Write-Verbose -Message ($script:localizedData.GrantAccess -f $accessRight, $_, $Name)

            Grant-SmbShareAccess -Name $Name -AccountName $_ -AccessRight $accessRight -Force -ErrorAction 'Stop'
        }
    }

    if ($PSBoundParameters.ContainsKey('NoAccess'))
    {
        # Get already added account names.
        $smbShareNoAccessObjects = $getSmbShareAccessResult | Where-Object -FilterScript {
            $_.AccessControlType -eq 'Deny' `
            -and $_.AccessRight -eq 'Full'
        }

        # Get a collection of just the account names.
        $noAccessAccountNames = @($smbShareNoAccessObjects.AccountName)

        $newAccountsToHaveNoAccess = $NoAccess | Where-Object -FilterScript {
            $_ -notin $noAccessAccountNames
        }

        # Add new accounts that should be denied permission.
        $newAccountsToHaveNoAccess | ForEach-Object {
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
        For that reason we are need either none of the parameters, or
        at least one to specify an account.

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
        $fullAccessHasNoMembers = $PSBoundParameters.ContainsKey('FullAccess') -and -not $FullAccess
        $changeAccessHasNoMembers = $PSBoundParameters.ContainsKey('ChangeAccess') -and -not $ChangeAccess
        $noAccessHasNoMembers = $PSBoundParameters.ContainsKey('NoAccess') -and -not $NoAccess
        <#
            If ReadAccess should have no members, then we need at least one
            member in one of the other access permission collections.
        #>
        if ($fullAccessHasNoMembers -and $changeAccessHasNoMembers -and $noAccessHasNoMembers)
        {
            New-InvalidArgumentException -Message $script:localizedData.WrongAccessParameters -ArgumentName 'FullAccess, ChangeAccess, ReadAccess, NoAccess'
        }
    }
}
