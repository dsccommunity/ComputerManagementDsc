$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the ComputerManagementDsc Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'ComputerManagementDsc.Common' `
            -ChildPath 'ComputerManagementDsc.Common.psm1'))

# Import Localization Strings
$script:localizedData = Get-LocalizedData -ResourceName 'DSC_UserAccountControl'

$script:registryKey = 'HKLM:\HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System'

$script:granularUserAccountControlParameterNames = @(
    'FilterAdministratorToken'
    'ConsentPromptBehaviorAdmin'
    'ConsentPromptBehaviorUser'
    'EnableInstallerDetection'
    'ValidateAdminCodeSignatures'
    'EnableLua'
    'PromptOnSecureDesktop'
    'EnableVirtualization'
)

<#
    .SYNOPSIS
        Gets the current state of the User Account Control.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER SuppressRestart
        Specifies if the needed restart is suppress. Default the node will be
        restarted if the value is changed.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        # This is best practice when writing a single-instance DSC resource.
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [Parameter()]
        [System.Boolean]
        $SuppressRestart = $false
    )

    Write-Verbose -Message $script:localizedData.GettingStateMessage

    $userAccountControlValues = Get-UserAccountControl

    $returnValue = @{
        IsSingleInstance = 'Yes'
        NotificationLevel = Get-NotificationLevel
        FilterAdministratorToken = $userAccountControlValues.FilterAdministratorToken
        ConsentPromptBehaviorAdmin = $userAccountControlValues.ConsentPromptBehaviorAdmin
        ConsentPromptBehaviorUser = $userAccountControlValues.ConsentPromptBehaviorUser
        EnableInstallerDetection = $userAccountControlValues.EnableInstallerDetection
        ValidateAdminCodeSignatures = $userAccountControlValues.ValidateAdminCodeSignatures
        EnableLua = $userAccountControlValues.EnableLua
        PromptOnSecureDesktop = $userAccountControlValues.PromptOnSecureDesktop
        EnableVirtualization = $userAccountControlValues.EnableVirtualization
        SuppressRestart = $SuppressRestart
    }

    return $returnValue
}

<#
    .SYNOPSIS
        Sets the current state of the User Account Control.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER Enabled
        Specifies if IE Enhanced Security Configuration should be enabled or
        disabled.

    .PARAMETER SuppressRestart
        Specifies if the needed restart is suppress. Default the node will be
        restarted if the value is changed.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [Parameter()]
        [ValidateSet('AlwaysNotify', 'AlwaysNotifyAndAskForCredentials', 'NotifyChanges', 'NotifyChangesWithoutDimming', 'NeverNotify', 'NeverNotifyAndDisableAll')]
        [System.String]
        $NotificationLevel,

        [Parameter()]
        [ValidateSet(0, 1)]
        [System.UInt16]
        $FilterAdministratorToken,

        [Parameter()]
        [ValidateSet(0, 1, 2, 3, 4, 5)]
        [System.UInt16]
        $ConsentPromptBehaviorAdmin,

        [Parameter()]
        [ValidateSet(0, 1, 3)]
        [System.UInt16]
        $ConsentPromptBehaviorUser,

        [Parameter()]
        [ValidateSet(0, 1)]
        [System.UInt16]
        $EnableInstallerDetection,

        [Parameter()]
        [ValidateSet(0, 1)]
        [System.UInt16]
        $ValidateAdminCodeSignatures,

        [Parameter()]
        [ValidateSet(0, 1)]
        [System.UInt16]
        $EnableLua,

        [Parameter()]
        [ValidateSet(0, 1)]
        [System.UInt16]
        $PromptOnSecureDesktop,

        [Parameter()]
        [ValidateSet(0, 1)]
        [System.UInt16]
        $EnableVirtualization,

        [Parameter()]
        [System.Boolean]
        $SuppressRestart = $false
    )

    $assertBoundParameterParameters = @{
        BoundParameterList = $PSBoundParameters
        MutualExclusiveList1 = @(
            'NotificationLevel'
        )
        MutualExclusiveList2 = $script:granularUserAccountControlParameterNames
    }

    Assert-BoundParameter @assertBoundParameterParameters

    Write-Verbose -Message $script:localizedData.SettingStateMessage

    $needRestart = $false

    $getTargetResourceResult = Get-TargetResource -IsSingleInstance 'Yes' -SuppressRestart $SuppressRestart
    if ($PSBoundParameters.ContainsKey('NotificationLevel'))
    {
        if ($getTargetResourceResult.NotificationLevel -ne $NotificationLevel)
        {
            Write-Verbose -Message (
                $script:localizedData.SetNotificationLevel -f $NotificationLevel
            )

            Set-UserAccountControlToNotificationLevel -NotificationLevel $NotificationLevel

            $needRestart = $true
        }
        else
        {
            Write-Verbose -Message $script:localizedData.NotificationLevelInDesiredState
        }
    }
    else
    {
        foreach ($parameterName in $script:granularUserAccountControlParameterNames)
        {
            if ($PSBoundParameters.ContainsKey($parameterName) -and $getTargetResourceResult.$parameterName -ne $PSBoundParameters.$parameterName)
            {
                Write-Verbose -Message (
                    $script:localizedData.SetPropertyToValue `
                        -f $parameterName, $PSBoundParameters.$parameterName
                )

                Set-ItemProperty -Path $script:registryKey -Name $parameterName -Value $PSBoundParameters.$parameterName

                $needRestart = $true
            }
        }

        if (-not $needRestart)
        {
            Write-Verbose -Message $script:localizedData.GranularPropertiesInDesiredState
        }
    }

    if ($needRestart)
    {
        if ($SuppressRestart)
        {
            Write-Warning -Message $script:localizedData.SuppressRestart
        }
        else
        {
            $global:DSCMachineStatus = 1
        }
    }
}

<#
    .SYNOPSIS
        Tests the current state of the User Account Control.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER Enabled
        Specifies if IE Enhanced Security Configuration should be enabled or
        disabled.

    .PARAMETER SuppressRestart
        Specifies if the needed restart is suppress. Default the node will be
        restarted if the value is changed.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [Parameter()]
        [ValidateSet('AlwaysNotify', 'AlwaysNotifyAndAskForCredentials', 'NotifyChanges', 'NotifyChangesWithoutDimming', 'NeverNotify', 'NeverNotifyAndDisableAll')]
        [System.String]
        $NotificationLevel,

        [Parameter()]
        [ValidateSet(0, 1)]
        [System.UInt16]
        $FilterAdministratorToken,

        [Parameter()]
        [ValidateSet(0, 1, 2, 3, 4, 5)]
        [System.UInt16]
        $ConsentPromptBehaviorAdmin,

        [Parameter()]
        [ValidateSet(0, 1, 3)]
        [System.UInt16]
        $ConsentPromptBehaviorUser,

        [Parameter()]
        [ValidateSet(0, 1)]
        [System.UInt16]
        $EnableInstallerDetection,

        [Parameter()]
        [ValidateSet(0, 1)]
        [System.UInt16]
        $ValidateAdminCodeSignatures,

        [Parameter()]
        [ValidateSet(0, 1)]
        [System.UInt16]
        $EnableLua,

        [Parameter()]
        [ValidateSet(0, 1)]
        [System.UInt16]
        $PromptOnSecureDesktop,

        [Parameter()]
        [ValidateSet(0, 1)]
        [System.UInt16]
        $EnableVirtualization,

        [Parameter()]
        [System.Boolean]
        $SuppressRestart = $false
    )

    Write-Verbose -Message $script:localizedData.TestingStateMessage

    $assertBoundParameterParameters = @{
        BoundParameterList = $PSBoundParameters
        MutualExclusiveList1 = @(
            'NotificationLevel'
        )
        MutualExclusiveList2 = $script:granularUserAccountControlParameterNames
    }

    Assert-BoundParameter @assertBoundParameterParameters

    $getTargetResourceResult = Get-TargetResource -IsSingleInstance 'Yes' -SuppressRestart $SuppressRestart
    if ($PSBoundParameters.ContainsKey('NotificationLevel'))
    {
        if ($getTargetResourceResult.NotificationLevel -ne $NotificationLevel)
        {
            $testTargetResourceReturnValue = $false

            Write-Verbose -Message ($script:localizedData.NotificationLevelNoInDesiredState -f $getTargetResourceResult.NotificationLevel, $NotificationLevel)
        }
        else
        {
            $testTargetResourceReturnValue = $true

            Write-Verbose -Message $script:localizedData.NotificationLevelInDesiredState
        }
    }
    else
    {
        $testTargetResourceReturnValue = $true

        foreach ($parameterName in $script:granularUserAccountControlParameterNames)
        {
            if ($PSBoundParameters.ContainsKey($parameterName) -and $getTargetResourceResult.$parameterName -ne $PSBoundParameters.$parameterName)
            {
                $testTargetResourceReturnValue = $false

                Write-Verbose -Message ($script:localizedData.GranularPropertyNoInDesiredState -f $parameterName, $getTargetResourceResult.$parameterName, $PSBoundParameters.$parameterName)
            }
        }

        if ($testTargetResourceReturnValue)
        {
            Write-Verbose -Message $script:localizedData.GranularPropertiesInDesiredState
        }
    }

    return $testTargetResourceReturnValue
}

<#
    .SYNOPSIS
        Gets the current values of the User Account Control registry entries.

    .OUTPUTS
        Returns a hashtable containing the values.
#>
function Get-UserAccountControl
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param ()

    $userAccountControlValues = @{
        FilterAdministratorToken = Get-RegistryPropertyValue -Path $script:registryKey -Name 'FilterAdministratorToken'
        ConsentPromptBehaviorAdmin = Get-RegistryPropertyValue -Path $script:registryKey -Name 'ConsentPromptBehaviorAdmin'
        ConsentPromptBehaviorUser = Get-RegistryPropertyValue -Path $script:registryKey -Name 'ConsentPromptBehaviorUser'
        EnableInstallerDetection = Get-RegistryPropertyValue -Path $script:registryKey -Name 'EnableInstallerDetection'
        ValidateAdminCodeSignatures = Get-RegistryPropertyValue -Path $script:registryKey -Name 'ValidateAdminCodeSignatures'
        EnableLua = Get-RegistryPropertyValue -Path $script:registryKey -Name 'EnableLUA'
        PromptOnSecureDesktop = Get-RegistryPropertyValue -Path $script:registryKey -Name 'PromptOnSecureDesktop'
        EnableVirtualization = Get-RegistryPropertyValue -Path $script:registryKey -Name 'EnableVirtualization'
    }

    return $userAccountControlValues
}

<#
    .SYNOPSIS
        Gets the current notification level string value.

    .OUTPUTS
        Returns the notification level string value. If the registry values does
        not match a predefined notification level then $null is returned.
#>
function Get-NotificationLevel
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param ()

    $stringValue = $null

    $userAccountControlValues = Get-UserAccountControl

    if ($userAccountControlValues.ConsentPromptBehaviorAdmin -eq 2 `
        -and $userAccountControlValues.EnableLua -eq 1 `
        -and $userAccountControlValues.PromptOnSecureDesktop -eq 1
    )
    {
        $stringValue = 'AlwaysNotify'
    }

    if ($userAccountControlValues.ConsentPromptBehaviorAdmin -eq 1 `
        -and $userAccountControlValues.EnableLua -eq 1 `
        -and $userAccountControlValues.PromptOnSecureDesktop -eq 1
    )
    {
        $stringValue = 'AlwaysNotifyAndAskForCredentials'
    }

    if ($userAccountControlValues.ConsentPromptBehaviorAdmin -eq 5 `
        -and $userAccountControlValues.EnableLua -eq 1 `
        -and $userAccountControlValues.PromptOnSecureDesktop -eq 1
    )
    {
        $stringValue = 'NotifyChanges'
    }

    if ($userAccountControlValues.ConsentPromptBehaviorAdmin -eq 5 `
        -and $userAccountControlValues.EnableLua -eq 1 `
        -and $userAccountControlValues.PromptOnSecureDesktop -eq 0
    )
    {
        $stringValue = 'NotifyChangesWithoutDimming'
    }

    if ($userAccountControlValues.ConsentPromptBehaviorAdmin -eq 0 `
        -and $userAccountControlValues.EnableLua -eq 1 `
        -and $userAccountControlValues.PromptOnSecureDesktop -eq 0
    )
    {
        $stringValue = 'NeverNotify'
    }

    if ($userAccountControlValues.ConsentPromptBehaviorAdmin -eq 0 `
        -and $userAccountControlValues.EnableLua -eq 0 `
        -and $userAccountControlValues.PromptOnSecureDesktop -eq 0
    )
    {
        $stringValue = 'NeverNotifyAndDisableAll'
    }

    return $stringValue
}

<#
    .SYNOPSIS
        Gets the current notification level string value.

    .OUTPUTS
        Returns the notification level string value. If the registry values does
        not match a predefined notification level then $null is returned.
#>
function Set-UserAccountControlToNotificationLevel
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('AlwaysNotify', 'AlwaysNotifyAndAskForCredentials', 'NotifyChanges', 'NotifyChangesWithoutDimming', 'NeverNotify', 'NeverNotifyAndDisableAll')]
        [System.String]
        $NotificationLevel
    )

    switch ($NotificationLevel)
    {
        'AlwaysNotify'
        {
            Set-ItemProperty -Path $script:registryKey -Name 'ConsentPromptBehaviorAdmin' -Value 2
            Set-ItemProperty -Path $script:registryKey -Name 'EnableLUA' -Value 1
            Set-ItemProperty -Path $script:registryKey -Name 'PromptOnSecureDesktop' -Value 1
        }

        'AlwaysNotifyAndAskForCredentials'
        {
            Set-ItemProperty -Path $script:registryKey -Name 'ConsentPromptBehaviorAdmin' -Value 1
            Set-ItemProperty -Path $script:registryKey -Name 'EnableLUA' -Value 1
            Set-ItemProperty -Path $script:registryKey -Name 'PromptOnSecureDesktop' -Value 1
        }


        'NotifyChanges'
        {
            Set-ItemProperty -Path $script:registryKey -Name 'ConsentPromptBehaviorAdmin' -Value 5
            Set-ItemProperty -Path $script:registryKey -Name 'EnableLUA' -Value 1
            Set-ItemProperty -Path $script:registryKey -Name 'PromptOnSecureDesktop' -Value 1
        }

        'NotifyChangesWithoutDimming'
        {
            Set-ItemProperty -Path $script:registryKey -Name 'ConsentPromptBehaviorAdmin' -Value 5
            Set-ItemProperty -Path $script:registryKey -Name 'EnableLUA' -Value 1
            Set-ItemProperty -Path $script:registryKey -Name 'PromptOnSecureDesktop' -Value 0
        }

        'NeverNotify'
        {
            Set-ItemProperty -Path $script:registryKey -Name 'ConsentPromptBehaviorAdmin' -Value 0
            Set-ItemProperty -Path $script:registryKey -Name 'EnableLUA' -Value 1
            Set-ItemProperty -Path $script:registryKey -Name 'PromptOnSecureDesktop' -Value 0
        }

        'NeverNotifyAndDisableAll'
        {
            Set-ItemProperty -Path $script:registryKey -Name 'ConsentPromptBehaviorAdmin' -Value 0
            Set-ItemProperty -Path $script:registryKey -Name 'EnableLUA' -Value 0
            Set-ItemProperty -Path $script:registryKey -Name 'PromptOnSecureDesktop' -Value 0
        }
    }
}
