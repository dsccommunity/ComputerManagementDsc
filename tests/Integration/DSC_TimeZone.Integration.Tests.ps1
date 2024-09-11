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
    $script:dscResourceName = 'DSC_TimeZone'

    # Ensure that the tests can be performed on this computer
    $script:skipIntegrationTests = $false
}

BeforeAll {
    $script:dscModuleName = 'ComputerManagementDsc'
    $script:dscResourceName = 'DSC_TimeZone'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Integration'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')
}

AfterAll {
    # Restore the test machine timezone
    & tzutil.exe /s $script:CurrentTimeZone

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Describe "$($script:dscResourceName)_Integration" {
    BeforeAll {
        # Store the test machine timezone
        $script:currentTimeZone = & tzutil.exe /g

        # Change the current timezone so that a complete test occurs.
        tzutil.exe /s 'Eastern Standard Time'

        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
        . $configFile -Verbose -ErrorAction Stop

        $configData = @{
            AllNodes = @(
                @{
                    NodeName         = 'localhost'
                    TimeZone         = 'Pacific Standard Time'
                    IsSingleInstance = 'Yes'
                }
            )
        }
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

            Start-DscConfiguration `
                -Path $TestDrive `
                -ComputerName localhost `
                -Wait `
                -Verbose `
                -Force `
                -ErrorAction Stop
        } | Should -Not -Throw
    }

    It 'Should be able to call Get-DscConfiguration without throwing' {
        { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
    }

    It 'Should have set the configuration and all the parameters should match' {
        $current = Get-DscConfiguration | Where-Object -FilterScript {
            $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
        }
        $current.TimeZone | Should -Be $configData.AllNodes[0].TimeZone
        $current.IsSingleInstance | Should -Be $configData.AllNodes[0].IsSingleInstance
    }
}
