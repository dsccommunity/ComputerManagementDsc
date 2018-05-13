[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Scope = "Function")]
param
(
)

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
    -ResourceName 'MSFT_LanguagePack' `
    -ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

<#
    .SYNOPSIS
        Retrieves the current state of the specified Language Pack

    .PARAMETER LanguagePackName
        The short code for the language to be tested.  ie en-GB
    
    .PARAMETER LanguagePackLocation
        Not used in Get-TargetResource.

    .PARAMETER SuppressReboot
        Not used in Get-TargetResource.

    .PARAMETER Ensure
        Not used in Get-TargetResource.
#>
Function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $LanguagePackName
    )

    $installedLanguages = (Get-CimInstance -ClassName "Win32_OperatingSystem" -Property "MUILanguages").MUILanguages

    Write-Verbose -Message ($script:localizedData.AllLanguagePacks -f $installedLanguages)

    $found = $installedLanguages -icontains $LanguagePackName
    
    if ($found)
    {
        $ensure = "Present"
    }
    else
    {
        $ensure = "Absent"
    }

    $returnValue = @{
        LanguagePackName = [System.String]$LanguagePackName
        SuppressReboot = [Boolean]$false
        Ensure = [System.String]$ensure
    }

    $returnValue
}

<#
    .SYNOPSIS
        Installs or uninstalls the specified Language Pack

    .PARAMETER LanguagePackName
        The short code for the language to be installed or uninstalled.  ie en-GB
    
    .PARAMETER LanguagePackLocation
        Either Local or Remote path to the language pack cab file.  This is only used
        when installing a language pack

    .PARAMETER SuppressReboot
        If set to true the reboot required flag isn't set after successful installation of a 
        language pack, this can be useful to save time when installing multiple language packs.

    .PARAMETER Ensure
        Indicates whether the given language pack should be installed or uninstalled.
        Set this property to Present to install the Language Pack, and Absent to uninstall
        the Language Pack.  By Default Ensure is set to Present
#>
Function Set-TargetResource
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $LanguagePackName,

        [Parameter()]
        [System.String]
        $LanguagePackLocation,

        [Parameter()]
        [Boolean]
        $SuppressReboot=$false,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure="Present"
    )
    $timeout = 7200

    switch ($Ensure) 
    {
        'Present' {
            if ($PSBoundParameters.ContainsKey('LanguagePackLocation'))
            {
                Write-Verbose -Message ($script:localizedData.InstallingLanguagePack)

                if (Test-Path -Path $LanguagePackLocation)
                {
                    lpksetup.exe /i $LanguagePackName /p $LanguagePackLocation /r /a /s
                    $startTime = Get-Date
                }
                else
                {
                    New-InvalidOperationException -Message ($script:localizedData.ErrorInvalidSourceLocation -f $LanguagePackLocation)
                }
            }
            else
            {
                New-InvalidOperationException -Message ($script:localizedData.ErrorSourceLocationRequired -f $LanguagePackLocation)
            }
        }
        'Absent' {
            Write-Verbose -Message ($script:localizedData.RemovingLanguagePack)
            lpksetup.exe /u $LanguagePackName /r /a /s
            $startTime = Get-Date
        }
        default {
            New-InvalidOperationException -Message ($script:localizedData.ErrorUnknownSwitch -f $Ensure)
        }
    }

    do
    {
        $process = Get-Process -Name "lpksetup" -ErrorAction SilentlyContinue
        $currentTime = (Get-Date) - $startTime
        if ($currentTime.TotalSeconds -gt $timeout)
        {
            New-InvalidOperationException -Message ($script:localizedData.ErrorTimeout -f $timeout)
        }
        Write-Verbose -Message ($script:localizedData.WaitForProcess -f $currentTime)
        Start-Sleep -Seconds 10
    } while ($null -ne $process)

    #allow for suppression to install multiple language packs at the same time to save time
    if ($SuppressReboot -ne $true)
    {
        #Force a reboot after installing or removing a language pack
        $global:DSCMachineStatus = 1
    }
}

<#
    .SYNOPSIS
        Tests if a Language Pack requires installation or uninstallation

    .PARAMETER LanguagePackName
        The short code for the language to be installed or uninstalled.  ie en-GB
    
    .PARAMETER LanguagePackLocation
        Not used in Test-TargetResource.

    .PARAMETER SuppressReboot
        If set to true the reboot required flag isn't set after successful installation of a 
        language pack, this can be useful to save time when installing multiple language packs.

    .PARAMETER Ensure
        Indicates whether the given language pack should be present or absent.
        Set this property to Present to install the Language Pack, and Absent to uninstall
        the Language Pack.  By Default Ensure is set to Present
#>
Function Test-TargetResource
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseVerboseMessageInDSCResource','')]
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $LanguagePackName,

        [Parameter()]
        [System.String]
        $LanguagePackLocation,
        
        [Parameter()]
        [Boolean]
        $SuppressReboot=$false,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure="Present"
    )

    return (Get-TargetResource -LanguagePackName $LanguagePackName).Ensure -eq $Ensure
}

Export-ModuleMember -Function *-TargetResource
