#region HEADER
$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'DSC_UserAccountControl'

try
{
    Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
}
catch [System.IO.FileNotFoundException]
{
    throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
}

$script:testEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -ResourceType 'Mof' `
    -TestType 'Integration'

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

try
{
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).Config.ps1"
    . $configFile

    # Used to reuse helper functions from the actual resource.
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\..\output\ComputerManagementDsc\*\DSCResources\DSC_UserAccountControl\DSC_UserAccountControl.psm1')

    $script:currentUserAccountControlSettings = Get-UserAccountControl

    # Checking what value can be used for testing for property ConsentPromptBehaviorUser.
    if ($script:currentUserAccountControlSettings.ConsentPromptBehaviorUser -eq 0)
    {
        $script:testConsentPromptBehaviorUserValue = 1
    }
    else
    {
        $script:testConsentPromptBehaviorUserValue = 0
    }

    # Checking what value can be used for testing for property EnableInstallerDetection..
    if ($script:currentUserAccountControlSettings.EnableInstallerDetection -eq 0)
    {
        $script:testEnableInstallerDetectionValue = 1
    }
    else
    {
        $script:testEnableInstallerDetectionValue = 0
    }

    Describe "$($script:dscResourceName)_Integration" {
        $configData = @{
            AllNodes = @(
                @{
                    NodeName = 'localhost'

                    # Setting value that are somewhat safe to change temporarily in a build worker.
                    ConsentPromptBehaviorUser = $script:testConsentPromptBehaviorUserValue
                    EnableInstallerDetection = $script:testEnableInstallerDetectionValue
                }
            )
        }

        It 'Should compile the MOF without throwing' {
            {
                & "$($script:dscResourceName)_Config" `
                    -OutputPath $TestDrive `
                    -ConfigurationData $configData
            } | Should -Not -Throw
        }

        It 'Should apply the MOF without throwing' {
            {
                Reset-DscLcm

                $startDscConfigurationParameters = @{
                    Path         = $TestDrive
                    ComputerName = 'localhost'
                    Wait         = $true
                    Verbose      = $true
                    Force        = $true
                    ErrorAction  = 'Stop'
                }

                Start-DscConfiguration @startDscConfigurationParameters
            } | Should -Not -Throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            {
                Get-DscConfiguration -Verbose -ErrorAction Stop
            } | Should -Not -Throw
        }

        It 'Should have set the resource and all the parameters should match' {
            $current = Get-DscConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
            }

            $current.IsSingleInstance | Should -Be 'Yes'
            $current.ConsentPromptBehaviorUser | Should -Be $configData.AllNodes.ConsentPromptBehaviorUser
            $current.EnableInstallerDetection | Should -Be $configData.AllNodes.EnableInstallerDetection
            $current.SuppressRestart | Should -BeTrue
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    Describe "$($script:dscResourceName)_Integration" {
        $configData = @{
            AllNodes = @(
                @{
                    NodeName = 'localhost'

                    ConsentPromptBehaviorUser = $script:currentUserAccountControlSettings.ConsentPromptBehaviorUser
                    EnableInstallerDetection = $script:currentUserAccountControlSettings.EnableInstallerDetection
                }
            )
        }

        It 'Should compile the MOF without throwing' {
            {
                & "$($script:dscResourceName)_Config" `
                    -OutputPath $TestDrive `
                    -ConfigurationData $configData
            } | Should -Not -Throw
        }

        It 'Should apply the MOF without throwing' {
            {
                Reset-DscLcm

                $startDscConfigurationParameters = @{
                    Path         = $TestDrive
                    ComputerName = 'localhost'
                    Wait         = $true
                    Verbose      = $true
                    Force        = $true
                    ErrorAction  = 'Stop'
                }

                Start-DscConfiguration @startDscConfigurationParameters
            } | Should -Not -Throw
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
