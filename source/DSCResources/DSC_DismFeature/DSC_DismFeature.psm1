$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the ComputerManagementDsc Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'ComputerManagementDsc.Common' `
            -ChildPath 'ComputerManagementDsc.Common.psm1'))

# Import Localization Strings
$script:localizedData = Get-LocalizedData -ResourceName 'DSC_DismFeature'

<#
    .SYNOPSIS
        Gets the current state of the feature.

    .PARAMETER Name
        Specifies the name of the feature.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    Write-Verbose -Message (
        $script:localizedData.GettingState -f $Name
    )

    $returnValue = @{
        Ensure = 'Absent'
        Name = $Name
        Source = $null
        SuppressRestart = $false
    }

    $dismFeatures = Get-DismFeatures

    if ($null -eq $dismFeatures.$Name)
    {
        # This should be ObjectNotFound exception when this module supports DscResource.Common
        New-InvalidOperationException -Message (
            $script:localizedData.UnknownFeature -f $Name
        )
    }

    if ($dismFeatures.$Name -eq 'Enabled')
    {
        $returnValue['Ensure'] = 'Present'
    }

    return $returnValue
}

<#
    .SYNOPSIS
        Sets the current state of the feature.

    .PARAMETER Ensure
        Specifies if the feature should be present or absent. Defaults to 'Present'.

    .PARAMETER Name
        Specifies the name of the feature.

    .PARAMETER Source
        Specifies the location of the source if needed to install the feature.
        E.g. 'C:\sources\sxs'.

    .PARAMETER EnableAllParentFeatures
        Specifies whether all the parent features should also be enabled when
        installing the feature. Defaults to $true.

    .PARAMETER SuppressRestart
        Specifies if a restart of the node should be suppressed. By default the
        node will be restarted if the feature requires as restart.
#>
function Set-TargetResource
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'DSCMachineStatus')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', 'global:DSCMachineStatus')]
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $Source,

        [Parameter()]
        [System.Boolean]
        $EnableAllParentFeatures,

        [Parameter()]
        [System.Boolean]
        $SuppressRestart
    )

    Write-Verbose -Message (
        $script:localizedData.SettingState -f $Name
    )

    switch ($Ensure)
    {
        'Present'
        {
            $dismArguments = @('/Online', '/Enable-Feature', "/FeatureName:$Name", '/Quiet', '/NoRestart')

            if ($Source)
            {
                $dismArguments += "/Source:$Source"
                $dismArguments += '/LimitAccess'
            }

            if ($EnableAllParentFeatures)
            {
                $dismArguments += "/All"
            }

            Invoke-Dism -Arguments $dismArguments
        }

        'Absent'
        {
            Invoke-Dism -Arguments @('/Online', '/Disable-Feature', "/FeatureName:$Name", '/Quiet', '/NoRestart')
        }
    }

    if (Test-Path -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending')
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
        Tests the current state of the feature.

    .PARAMETER Ensure
        Specifies if the feature should be present or absent. Defaults to 'Present'.

    .PARAMETER Name
        Specifies the name of the feature.

    .PARAMETER Source
        Specifies the location of the source if needed to install the feature.
        E.g. 'C:\sources\sxs'.

    .PARAMETER EnableAllParentFeatures
        Specifies whether all the parent features should also be enabled when
        installing the feature. Defaults to $true.

    .PARAMETER SuppressRestart
        Specifies if a restart of the node should be suppressed. By default the
        node will be restarted if the feature requires as restart.

        Not used in Test-TargetResource.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $Source,

        [Parameter()]
        [System.Boolean]
        $EnableAllParentFeatures,

        [Parameter()]
        [System.Boolean]
        $SuppressRestart
    )

    Write-Verbose -Message (
        $script:localizedData.TestingState -f $Name
    )

    $getTargetResourceResult = Get-TargetResource -Name $Name

    $isInDesiredState = $getTargetResourceResult.Ensure -eq $Ensure

    if ($isInDesiredState)
    {
        Write-Verbose -Message (
            $script:localizedData.InDesiredState -f $Name
        )
    }
    else
    {
        Write-Verbose -Message (
            $script:localizedData.NotInDesiredState -f $Name
        )
    }

    return $isInDesiredState
}

<#
    .SYNOPSIS
        Get all the features name and the current state.
#>
function Get-DismFeatures
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param ()

    Write-Verbose -Message (
        $script:localizedData.GetAllDismFeatures
    )

    $invokeDismResult = Invoke-Dism -Arguments @('/Online', '/Get-Features', '/English')

    $dismFeatures = @{}

    foreach ($line in $invokeDismResult)
    {
        switch ($line.Split(':')[0].Trim())
        {
            'Feature Name'
            {
                $featureName = $line.Split(':')[1].Trim()
            }

            'State'
            {
                $dismFeatures += @{
                    $featureName = $line.Split(':')[1].Trim()
                }
            }
        }
    }

    return $dismFeatures
}

<#
    .SYNOPSIS
        Invokes calls of the executable dism.exe.

    .PARAMETER Arguments
        Specifies the arguments to pass to dism.exe.

    .OUTPUTS
        Returns the output from the the executable dism.exe.

    .NOTES
        This is a wrapper for the dism.exe.

        Known errors are:

        740: Elevated permissions are required to run DISM.
        3010: A restart is required.
#>
function Invoke-Dism
{
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Arguments
    )

    Write-Verbose -Message (
        $script:localizedData.CallingDismWithArguments -f ($Arguments -join ' ')
    )

    $dismOutput = & dism.exe $Arguments

    $resultCode = $LASTEXITCODE

    if ($resultCode -ne 0)
    {
        # The output from dism is an array of strings, must join them together.
        New-InvalidOperationException -Message ($dismOutput -join "`n")
    }

    return $dismOutput
}
