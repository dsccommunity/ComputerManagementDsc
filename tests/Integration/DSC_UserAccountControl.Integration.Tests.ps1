# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }

    <#
        Need to define that variables here to be used in the Pester Discover to
        build the ForEach-blocks.
    #>
    $script:dscModuleName = 'ComputerManagementDsc'
    $script:dscResourceName = 'DSC_UserAccountControl'

    # Ensure that the tests can be performed on this computer
    $script:skipIntegrationTests = $false
}

BeforeAll {
    $script:dscModuleName = 'ComputerManagementDsc'
    $script:dscResourceName = 'DSC_UserAccountControl'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Integration'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')
}

AfterAll {
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Describe "$($script:dscResourceName)_Integration" {
    BeforeAll {
        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).Config.ps1"
        . $configFile

        # Used to reuse helper functions from the actual resource.
        Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\..\output\builtModule\ComputerManagementDsc\*\DSCResources\DSC_UserAccountControl\DSC_UserAccountControl.psm1')
    }

    BeforeEach {
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

        $configData = @{
            AllNodes = @(
                @{
                    NodeName                  = 'localhost'

                    # Setting value that are somewhat safe to change temporarily in a build worker.
                    ConsentPromptBehaviorUser = $script:testConsentPromptBehaviorUserValue
                    EnableInstallerDetection  = $script:testEnableInstallerDetectionValue
                }
            )
        }
    }

    Context 'When ConsentPromptBehaviorUser and EnableInstallerDetection are 0' {
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
            $current.ConsentPromptBehaviorUser | Should -Be 0
            $current.EnableInstallerDetection | Should -Be 0
            $current.SuppressRestart | Should -BeTrue
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    Context 'When ConsentPromptBehaviorUser and EnableInstallerDetection are 1' {
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
            $current.ConsentPromptBehaviorUser | Should -Be 1
            $current.EnableInstallerDetection | Should -Be 1
            $current.SuppressRestart | Should -BeTrue
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }
}
