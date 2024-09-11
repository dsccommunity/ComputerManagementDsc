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
    $script:dscResourceName = 'DSC_VirtualMemory'

    # Ensure that the tests can be performed on this computer
    $script:skipIntegrationTests = $false
}

BeforeAll {
    $script:dscModuleName = 'ComputerManagementDsc'
    $script:dscResourceName = 'DSC_VirtualMemory'

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
        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
        . $configFile
    }
    Context 'When setting the page file to automatically managed' {
        BeforeAll {
            $currentConfig = 'setToAuto'
            $configDir = (Join-Path -Path $TestDrive -ChildPath $currentConfig)
            $configMof = (Join-Path -Path $configDir -ChildPath 'localhost.mof')
        }

        It 'Should compile the MOF without throwing' {
            {
                . $currentConfig -OutputPath $configDir
            } | Should -Not -Throw
        }

        It 'Should apply the MOF without throwing' {
            {
                Reset-DscLcm

                Start-DscConfiguration -Path $configDir -Wait -Verbose -Force
            } | Should -Not -Throw
        }

        It 'Should return a compliant state after being applied' {
            (Test-DscConfiguration -ReferenceConfiguration $configMof -Verbose).InDesiredState | Should -BeTrue
        }
    }

    Context 'When setting the page file to custom size' {
        BeforeAll {
            $currentConfig = 'setToCustom'
            $configDir = (Join-Path -Path $TestDrive -ChildPath $currentConfig)
            $configMof = (Join-Path -Path $configDir -ChildPath 'localhost.mof')
        }

        It 'Should compile the MOF without throwing' {
            {
                . $currentConfig -OutputPath $configDir
            } | Should -Not -Throw
        }

        It 'Should apply the MOF without throwing' {
            {
                Reset-DscLcm

                Start-DscConfiguration -Path $configDir -Wait -Verbose -Force
            } | Should -Not -Throw
        }

        It 'Should return a compliant state after being applied' {
            (Test-DscConfiguration -ReferenceConfiguration $configMof -Verbose).InDesiredState | Should -BeTrue
        }
    }

    Context 'When setting the page file to system managed' {
        BeforeAll {
            $currentConfig = 'setToSystemManaged'
            $configDir = (Join-Path -Path $TestDrive -ChildPath $currentConfig)
            $configMof = (Join-Path -Path $configDir -ChildPath 'localhost.mof')
        }

        It 'Should compile the MOF without throwing' {
            {
                . $currentConfig -OutputPath $configDir
            } | Should -Not -Throw
        }

        It 'Should apply the MOF without throwing' {
            {
                Reset-DscLcm

                Start-DscConfiguration -Path $configDir -Wait -Verbose -Force
            } | Should -Not -Throw
        }

        It 'Should return a compliant state after being applied' {
            (Test-DscConfiguration -ReferenceConfiguration $configMof -Verbose).InDesiredState | Should -BeTrue
        }
    }

    Context 'When setting the page file to none' {
        BeforeAll {
            $currentConfig = 'setToNone'
            $configDir = (Join-Path -Path $TestDrive -ChildPath $currentConfig)
            $configMof = (Join-Path -Path $configDir -ChildPath 'localhost.mof')
        }

        It 'Should compile the MOF without throwing' {
            {
                . $currentConfig -OutputPath $configDir
            } | Should -Not -Throw
        }

        It 'Should apply the MOF without throwing' {
            {
                Reset-DscLcm

                Start-DscConfiguration -Path $configDir -Wait -Verbose -Force
            } | Should -Not -Throw
        }

        It 'Should return a compliant state after being applied' {
            (Test-DscConfiguration -ReferenceConfiguration $configMof -Verbose).InDesiredState | Should -BeTrue
        }
    }
}
