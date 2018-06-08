# Suppress the PSSA Rule for the use of global variables as $global:DSCMachineStatus is required to trigger a reboot.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "", Scope = "Function")]
param
()

$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the ComputerManagementDsc Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'ComputerManagementDsc.Common' `
            -ChildPath 'ComputerManagementDsc.Common.psm1'))

# Import the ComputerManagementDsc Resource Helper Module
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'ComputerManagementDsc.ResourceHelper' `
            -ChildPath 'ComputerManagementDsc.ResourceHelper.psm1'))

# Import Localization Strings
$script:localizedData = Get-LocalizedData `
    -ResourceName 'MSFT_Language' `
    -ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

<#
    .SYNOPSIS
        Retrieves the current state of the specified Language Pack.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'.
#>
Function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance
    )

    Write-Verbose -Message ($script:localizedData.StartingGetResource)
    return Get-LanguageInformation -UserID 'CURRENTUSER'
}

<#
    .SYNOPSIS
        Sets the configuration for all specified settings.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER LocationID
        Integer specifying the country location code, this can be found
        https://msdn.microsoft.com/en-us/library/windows/desktop/dd374073(v=vs.85).aspx.

    .PARAMETER MUILanguage
        User interface language, should be in the format en-GB.

    .PARAMETER MUIFallbackLanguage
        User interface language to be used when the primary does not cover the
        required settings, should be in the format en-GB.

    .PARAMETER SystemLocale
        The language used for the system locale, should be in the format en-GB.

    .PARAMETER AddInputLanguages
        Array Specifying the keyboard input languages to be added to the available list.

    .PARAMETER RemoveInputLanguages
        Array specifying the keyboard input languages to be removed from the available list.

    .PARAMETER UserLocale
        The language used for the user locale, should be in the format en-GB.

    .PARAMETER CopySystem
        Boolean value to copy all settings to the system accounts, the default is true.

    .PARAMETER CopyNewUser
        Boolean value to copy all settings for new user accounts, the default is true.
#>
Function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Yes")]
        [System.String]
        $IsSingleInstance,

        [Parameter()]
        [System.Int32]
        $LocationID,

        [Parameter()]
        [System.String]
        $MUILanguage,

        [Parameter()]
        [System.String]
        $MUIFallbackLanguage,

        [Parameter()]
        [System.String]
        $systemLocale,

        [Parameter()]
        [System.String[]]
        $AddInputLanguages,

        [Parameter()]
        [System.String[]]
        $RemoveInputLanguages,

        [Parameter()]
        [System.String]
        $UserLocale,

        [Parameter()]
        [System.Boolean]
        $CopySystem = $true,

        [Parameter()]
        [System.Boolean]
        $CopyNewUser = $true
    )

    <#
        Because some or all of the setting may be changed its impossible to set mandatory parameters,
        instead we will throw an error if no settings have been defined
    #>
    $configurationRequired = $false

    $languageSettings = @()

    $languageSettings += '<gs:GlobalizationServices xmlns:gs="urn:longhornGlobalizationUnattend">'

    $languageSettings += '    <gs:UserList>'
    $languageSettings += "        <gs:User UserID=`"Current`" CopySettingsToDefaultUserAcct=`"$($CopyNewUser.ToString().tolower())`" CopySettingsToSystemAcct=`"$($CopySystem.ToString().tolower())`"/>"
    $languageSettings += '    </gs:UserList>'

    if (-not ([System.String]::IsNullOrEmpty($LocationID)))
    {
        $configurationRequired = $true

        $languageSettings += '    <gs:LocationPreferences>'
        $languageSettings += "        <gs:GeoID Value=`"$LocationID`"/>"
        $languageSettings += '    </gs:LocationPreferences>'
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.LocationNotRequired)
    }

    # Check to see if both MUI Language and MUIFallback Language have been specified
    if (-not ([System.String]::IsNullOrEmpty($MUILanguage) -and [System.String]::IsNullOrEmpty($MUIFallbackLanguage)))
    {
        $configurationRequired = $true

        $languageSettings += '    <gs:MUILanguagePreferences>'

        if (-not ([System.String]::IsNullOrEmpty($MUILanguage)))
        {
            $languageSettings += "        <gs:MUILanguage Value=`"$MUILanguage`"/>"
        }

        if (-not ([System.String]::IsNullOrEmpty($MUIFallbackLanguage)))
        {
            $languageSettings += "        <gs:MUIFallback Value=`"$MUIFallbackLanguage`"/>"
        }

        $languageSettings += '    </gs:MUILanguagePreferences>'
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.LanguageNotRequired)
    }

    if (-not ([System.String]::IsNullOrEmpty($systemLocale)))
    {
        $configurationRequired = $true

        $languageSettings += "    <gs:SystemLocale Name=`"$systemLocale`"/>"
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.LocaleNotRequired)
    }

    if ($null -ne $AddInputLanguages -or $null -ne $RemoveInputLanguages)
    {
        Assert-LanguageCodesValid -Languages $AddInputLanguages
        Assert-LanguageCodesValid -Languages $RemoveInputLanguages

        $configurationRequired = $true

        $languageSettings += '    <gs:InputPreferences>'

        foreach ($LanguageID in $AddInputLanguages)
        {
            $languageSettings += "        <gs:InputLanguageID Action=`"add`" ID=`"$LanguageID`"/>"
        }

        foreach ($LanguageID in $RemoveInputLanguages)
        {
            $languageSettings += "        <gs:InputLanguageID Action=`"remove`" ID=`"$LanguageID`"/>"
        }

        $languageSettings += '    </gs:InputPreferences>'
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.KeyboardNotRequired)
    }

    if ($UserLocale -ne "")
    {
        $configurationRequired = $true

        $languageSettings += '    <gs:UserLocale>'
        $languageSettings += "        <gs:Locale Name=`"$UserLocale`" SetAsCurrent=`"true`" ResetAllSettings=`"true`"/>"
        $languageSettings += '    </gs:UserLocale>'
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.UserLocaleNotRequired)
    }

    $languageSettings +=  '</gs:GlobalizationServices>'

    Write-Verbose -Message ($script:localizedData.CreatedXML)
    $languageSettings | Write-Verbose

    if ($configurationRequired)
    {
        # Configuration command can't take a xml object, it must load the file from the filesystem
        Out-File -InputObject $languageSettings -FilePath "$env:TEMP\Locale.xml" -Force -Encoding ascii

        $arg = "intl.cpl,, /f:`"$env:TEMP\Locale.xml`""
        Start-Process -FilePath control.exe -ArgumentList $arg

        $global:DSCMachineStatus = 1
    }
    else
    {
        New-InvalidOperationException `
            -Message ($script:localizedData.ErrorNoParameters)
    }
}

<#
    .SYNOPSIS
        Tests the configuration for all specified settings.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER LocationID
        Integer specifying the country location code, this can be found
        https://msdn.microsoft.com/en-us/library/windows/desktop/dd374073(v=vs.85).aspx.

    .PARAMETER MUILanguage
        User interface language, should be in the format en-GB.

    .PARAMETER MUIFallbackLanguage
        User interface language to be used when the primary does not cover the
        required settings, should be in the format en-GB.

    .PARAMETER SystemLocale
        The language used for the system locale, should be in the format en-GB.

    .PARAMETER AddInputLanguages
        Array specifying the keyboard input languages to be added to the available list.

    .PARAMETER RemoveInputLanguages
        Array specifying the keyboard input languages to be removed from the available list.

    .PARAMETER UserLocale
        The language used for the user locale, should be in the format en-GB.

    .PARAMETER CopySystem
        Boolean value to copy all settings to the system accounts, the default is true.

    .PARAMETER CopyNewUser
        Boolean value to copy all settings for new user accounts, the default is true.
#>
Function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Yes")]
        [System.String]
        $IsSingleInstance,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Int32]
        $LocationID,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $MUILanguage,

        [Parameter()]
        [System.String]
        $MUIFallbackLanguage,

        [Parameter()]
        [System.String]
        $systemLocale,

        [Parameter()]
        [System.String[]]
        $AddInputLanguages,

        [Parameter()]
        [System.String[]]
        $RemoveInputLanguages,

        [Parameter()]
        [System.String]
        $UserLocale,

        [Parameter()]
        [System.Boolean]
        $CopySystem = $true,

        [Parameter()]
        [System.Boolean]
        $CopyNewUser = $true
    )

    $result = $true

    Assert-LanguageCodesValid -Languages $AddInputLanguages
    Assert-LanguageCodesValid -Languages $RemoveInputLanguages

    $currentUser = Get-LanguageInformation -UserID 'CURRENTUSER'
    $system = Get-LanguageInformation -UserID 'MACHINE'
    $newUser = Get-LanguageInformation -UserID 'DEFAULT'

    #region Check Location

    # If LocationID requires configuration
    if ($LocationID -ne 0)
    {
        # Check current user
        if ($currentUser.LocationID -ne $LocationID)
        {
            $result = $false
        }

        # Check System Account if also configuring System
        if ($CopySystem -eq $true -and $system.LocationID -ne $LocationID)
        {
            $result = $false
        }

        # Check New User Account if also configuring new users
        if ($CopyNewUser -eq $true -and $newUser.LocationID -ne $LocationID)
        {
            $result = $false
        }
        Write-Debug -Message ($script:localizedData.DebugLocationAfter -f 'LocationID', $result)
    }
    else
    {
        Write-Debug -Message ($script:localizedData.DebugSkipCheck -f 'LocationID')
    }

    #endregion

    #region Check MUI Language

    # If MUILanguage requires configuration
    if ($MUILanguage -ne "")
    {
        # Check current user
        if ($currentUser.MUILanguage -ne $MUILanguage)
        {
            $result = $false
            Write-Verbose -Message ($script:localizedData.UpdateRequired -f 'Current User', 'MUILanguage')
        }

        # Check System Account if also configuring System
        if ($CopySystem -eq $true -and $system.MUILanguage -ne $MUILanguage)
        {
            $result = $false
            Write-Verbose -Message ($script:localizedData.UpdateRequired -f 'System', 'MUILanguage')
        }

        # Check New User Account if also configuring new users
        if ($CopyNewUser -eq $true -and $newUser.MUILanguage -ne $MUILanguage)
        {
            $result = $false
            Write-Verbose -Message ($script:localizedData.UpdateRequired -f 'New Users', 'MUILanguage')
        }
        Write-Debug -Message ($script:localizedData.DebugLocationAfter -f 'MUILanguage', $result)
    }
    else
    {
        Write-Debug -Message ($script:localizedData.DebugSkipCheck -f 'MUILanguage')
    }

    #endregion

    #region Check MUI Fallback Language

    # If MUIFallbackLanguage requires configuration
    if ($MUIFallbackLanguage -ne "")
    {
        # Check current user
        if ($null -ne $currentUser.FallbackLanguage)
        {
            if ($currentUser.FallbackLanguage -ne $MUIFallbackLanguage)
            {
                $result = $false
                Write-Verbose -Message ($script:localizedData.UpdateRequired -f 'Current User', 'MUIFallbackLanguage')
            }
        }

        # Check System Account if also configuring System
        if ($null -ne $system.FallbackLanguage)
        {
            if ($CopySystem -eq $true -and $system.FallbackLanguage -ne $MUIFallbackLanguage)
            {
                $result = $false
                Write-Verbose -Message ($script:localizedData.UpdateRequired -f 'System', 'MUIFallbackLanguage')
            }
        }

        # Check New User Account if also configuring new users
        if ($null -ne $newUser.FallbackLanguage)
        {
            if ($CopyNewUser -eq $true -and $newUser.FallbackLanguage -ne $MUIFallbackLanguage)
            {
                $result = $false
                Write-Verbose -Message ($script:localizedData.UpdateRequired -f 'New Users', 'MUIFallbackLanguage')
            }
        }
        Write-Debug -Message ($script:localizedData.DebugLocationAfter -f 'MUIFallbackLanguage', $result)
    }
    else
    {
        Write-Debug -Message ($script:localizedData.DebugSkipCheck -f 'MUIFallbackLanguage')
    }

    #endregion

    #region Check SystemLocale

    # If SystemLocale requires configuration
    if ($systemLocale -ne "")
    {
        if ($currentUser.SystemLocale -ne $systemLocale)
        {
            $result = $false
        }
        Write-Debug -Message ($script:localizedData.DebugLocationAfter -f 'SystemLocale', $result)
    }
    else
    {
        Write-Debug -Message ($script:localizedData.DebugSkipCheck -f 'SystemLocale')
    }

    #endregion

    #region Check Languages

    if ($null -ne $AddInputLanguages)
    {
        # Loop through all languages which need to be on the system
        foreach($language in $AddInputLanguages)
        {
            # Check if they are already on the system for the current user
            if (!($currentUser.CurrentInstalledLanguages.ContainsValue($language)))
            {
                $result = $false
                Write-Verbose -Message ($script:localizedData.UpdateRequired -f 'Current User', 'AddInputLanguages')
            }

            # Check System Account if also adding Languages
            if ($CopySystem -eq $true -and !($system.CurrentInstalledLanguages.ContainsValue($language)))
            {
                Write-Verbose -Message ($script:localizedData.UpdateRequired -f 'System', 'AddInputLanguages')
                $result = $false
            }

            # Check New User Account if also adding Languages
            if ($CopyNewUser -eq $true -and !($newUser.CurrentInstalledLanguages.ContainsValue($language)))
            {
                Write-Verbose -Message ($script:localizedData.UpdateRequired -f 'New Users', 'AddInputLanguages')
                $result = $false
            }
        }
        Write-Debug -Message ($script:localizedData.DebugLocationAfter -f 'AddInputLanguages', $result)
    }
    else
    {
        Write-Debug -Message ($script:localizedData.DebugSkipCheck -f 'AddInputLanguages')
    }

    if ($null -ne $RemoveInputLanguages)
    {
        foreach($language in $RemoveInputLanguages)
        {
            if ($currentUser.CurrentInstalledLanguages.ContainsValue($language))
            {
                $result = $false
                Write-Verbose -Message ($script:localizedData.UpdateRequired -f 'Current User', 'RemoveInputLanguages')
            }

            # Check System Account if also configuring System
            if ($CopySystem -eq $true -and $system.CurrentInstalledLanguages.ContainsValue($language))
            {
                $result = $false
                Write-Verbose -Message ($script:localizedData.UpdateRequired -f 'System', 'RemoveInputLanguages')
            }

            # Check New User Account if also configuring new users
            if ($CopyNewUser -eq $true -and $newUser.CurrentInstalledLanguages.ContainsValue($language))
            {
                $result = $false
                Write-Verbose -Message ($script:localizedData.UpdateRequired -f 'New Users', 'RemoveInputLanguages')
            }
        }
        Write-Debug -Message ($script:localizedData.DebugLocationAfter -f 'RemoveInputLanguages', $result)
    }
    else
    {
        Write-Debug -Message ($script:localizedData.DebugSkipCheck -f 'RemoveInputLanguages')
    }

    #endregion

    #region Check User Locale

    # If User Locale requires configuration
    if ($UserLocale -ne "")
    {
        # Check current user
        if ($currentUser.UserLocale -ne $UserLocale)
        {
            $result = $false
            Write-Verbose -Message ($script:localizedData.UpdateRequired -f 'Current User', 'UserLocale')
        }

        # Check System Account if also configuring System
        if ($CopySystem -eq $true -and $system.UserLocale -ne $UserLocale)
        {
            $result = $false
            Write-Verbose -Message ($script:localizedData.UpdateRequired -f 'System', 'UserLocale')
        }

        # Check New User Account if also configuring new users
        if ($CopyNewUser -eq $true -and $newUser.UserLocale -ne $UserLocale)
        {
            $result = $false
            Write-Verbose -Message ($script:localizedData.UpdateRequired -f 'New Users', 'UserLocale')
        }
        Write-Debug -Message ($script:localizedData.DebugLocationAfter -f 'UserLocale', $result)
    }
    else
    {
        Write-Debug -Message ($script:localizedData.DebugSkipCheck -f 'UserLocale')
    }

    #endregion

    return $result
}

<#
    .SYNOPSIS
        Helper function to define the Language Regular expression once
#>
Function Get-LanguageRegex
{
    [CmdletBinding()]
    [OutputType([String])]
    param
    (
    )

    return '[0-9a-fA-F]{4}:[0-9a-fA-F]{8}|[0-9a-fA-F]{4}:\{[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\}\{[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\}'
}

<#
    .SYNOPSIS
        Checks that all language codes in an array are valid and throws a terminating error if they aren't

    .PARAMETER Languages
        Array of Language Codes to check
#>
Function Assert-LanguageCodesValid
{
    [CmdletBinding()]
    [OutputType([Void])]
    param
    (
        [Parameter()]
        [System.String[]]
        $Languages
    )

    $languageRegEx = Get-LanguageRegex

    if ($null -ne $Languages)
    {
        # Ensure that keyboard layouts are in the required format
        foreach ($languageID in $Languages)
        {
            if ($languageID -notmatch $languageRegEx)
            {
                New-InvalidOperationException -Message ($script:localizedData.ErrorInvalidKeyboardCode -f $languageRegEx)
            }
        }
    }
}

<#
    .SYNOPSIS
        Gathers all the language and locale information about a specific user account

    .PARAMETER UserID
        Either a specific User SID or CURRENTUSER, DEFAULT or MACHINE for predefined accounts
#>
Function Get-LanguageInformation
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter()]
        [System.String[]]
        [ValidateSet('CURRENTUSER',' DEFAULT','MACHINE')]
        $UserID
    )

    switch($UserID.ToUpperInvariant())
    {
        'CURRENTUSER'
        {
            $UserReg = 'HKCU:\'
        }

        'DEFAULT'
        {
            $UserReg = 'registry::hkey_Users\.DEFAULT\'
        }

        'MACHINE'
        {
            $UserReg = 'registry::hkey_Users\S-1-5-18\'
        }

        default
        {
            New-InvalidOperationException -Message ($script:localizedData.ErrorInvalidUserID -f $UserID)
        }
    }

    #region LocationID

    $LocationRegistryFull = Join-Path -Path $UserReg -ChildPath 'Control Panel\International\Geo\'

    $locationID = Get-ItemPropertyValue $LocationRegistryFull -Name 'Nation'
    Write-Verbose -Message ($script:localizedData.UserLocationID -f $locationID)

    #endregion

    #region MUI Language

    $MUILanguageRegistryFull = Join-Path -Path $UserReg -ChildPath 'Control Panel\Desktop\'
    $MUILanguageDefaultRegistryFull = Join-Path -Path $UserReg -ChildPath 'Control Panel\Desktop\MuiCached\'

    # This is only set if the language has ever been changed, if not it defaults to system preferred
    try
    {
        $MUILanguage = Get-ItemPropertyValue $MUILanguageRegistryFull -Name 'PreferredUILanguages'
    }
    catch
    {
        $MUILanguage = Get-ItemPropertyValue $MUILanguageDefaultRegistryFull -Name 'MachinePreferredUILanguages'
    }

    # Assume there is only 1 active MUI installed
    [String]$MUILanguage = $MUILanguage[0]
    Write-Verbose -Message ($script:localizedData.UserMUI -f $MUILanguage)

    #endregion

    #region MUI Fallback Language

    if ($UserID.ToUpperInvariant() -eq 'CURRENTUSER')
    {
        $MUIFallbackLanguageRegistryFull = Join-Path -Path $UserReg -ChildPath 'Control Panel\Desktop\LanguageConfiguration\'
    }
    else
    {
        $MUIFallbackLanguageRegistryFull = Join-Path -Path $UserReg -ChildPath 'Control Panel\Desktop\MuiCached\MachineLanguageConfiguration\'
    }

    try
    {
        $MUIFallbackLanguage = Get-ItemPropertyValue $MUIFallbackLanguageRegistryFull -Name $MUILanguage -ErrorAction Stop
        [String]$MUIFallbackLanguage = $MUIFallbackLanguage[0]
        Write-Verbose -Message ($script:localizedData.UserMUIFallBack -f $MUIFallbackLanguage)
    }
    catch
    {
        Write-Verbose -Message ($script:localizedData.UserNoFallbackLanguage)
    }

    #endregion

    #region Installed Languages

    $InstalledLanguageRegistryFull = Join-Path -Path $UserReg -ChildPath 'Control Panel\International\User Profile\'

    $Languages = Get-ItemPropertyValue $InstalledLanguageRegistryFull -Name 'Languages'
    Write-Verbose -Message ($script:localizedData.CurrentlyInstalledLanguages -f $Languages)

    # RegEX taken from implementation error output
    $languageRegEx = Get-LanguageRegex
    $ReturnLanguage = @{}

    foreach ($Language in $Languages)
    {
        $LanguagePath = Join-Path -Path $InstalledLanguageRegistryFull -ChildPath $Language
        $LanguageProperties = Get-ItemProperty -Path $LanguagePath -ErrorAction Continue
        Write-Verbose -Message ($script:localizedData.CurrentLanguageProperties -f $LanguageProperties)
        $LanguageCodeObj = $LanguageProperties | Get-Member -MemberType NoteProperty | Where-Object {$_.Name -Match $languageRegEx} -ErrorAction Continue
        $LanguageCode = $LanguageCodeObj.Name
        if ($null -ne $LanguageCode)
        {
            Write-Verbose -Message ($script:localizedData.CurrentLanguageCode -f $LanguageCode)
            $ReturnLanguage += @{$Language=$LanguageCode}
        }
    }

    #endregion

    #region Current Locale

    $UserLocaleRegistryFull = Join-Path -Path $UserReg -ChildPath 'Control Panel\International\'

    $Locale = Get-ItemPropertyValue $UserLocaleRegistryFull -Name 'LocaleName'
    Write-Verbose -Message ($script:localizedData.UserLocale -f $Locale)

    #endregion

    #region System Locale

    $systemLocale = Get-WinSystemLocale
    Write-Verbose -Message ($script:localizedData.CurrentSystemLocale -f $systemLocale.Name)

    #endregion

    $returnValue = @{
        IsSingleInstance = 'Yes'
        LocationID = [System.Int32]$locationID
        MUILanguage = [System.String]$MUILanguage
        MUIFallbackLanguage = [System.String]$MUIFallbackLanguage
        SystemLocale = [System.String]$systemLocale.Name
        CurrentInstalledLanguages = [Hashtable]$ReturnLanguage
        UserLocale = [System.String]$Locale
    }

    return $returnValue
}

Export-ModuleMember -Function *-TargetResource
