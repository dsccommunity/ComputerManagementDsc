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
    $script:dscResourceName = 'DSC_SmbShare'

    # Ensure that the tests can be performed on this computer
    $script:skipIntegrationTests = $false
}

BeforeAll {
    $script:dscModuleName = 'ComputerManagementDsc'
    $script:dscResourceName = 'DSC_SmbShare'

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

Describe 'SmbShare Integration Tests' {
    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_Prerequisites_Config"
    ) {
        BeforeAll {
            $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
            . $configFile

            $configurationName = $_
        }

        It 'Should compile the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath        = $TestDrive
                    ConfigurationData = $ConfigurationData
                }

                & $configurationName @configurationParameters
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

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_CreateShare1_Config"
    ) {
        BeforeAll {
            $configurationName = $_
        }

        It 'Should compile the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath        = $TestDrive
                    ConfigurationData = $ConfigurationData
                }

                & $configurationName @configurationParameters
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
                $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
            } | Should -Not -Throw
        }

        It 'Should have set the resource and all the parameters should match' {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName `
                    -and $_.ResourceId -eq '[SmbShare]Integration_Test'
            }

            $resourceCurrentState.Ensure | Should -Be 'Present'
            $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.ShareName1
            $resourceCurrentState.Path | Should -Be $ConfigurationData.AllNodes.SharePath1
            $resourceCurrentState.Description | Should -BeNullOrEmpty
            $resourceCurrentState.EncryptData | Should -BeFalse
            $resourceCurrentState.ConcurrentUserLimit | Should -Be 0
            $resourceCurrentState.Description | Should -BeNullOrEmpty
            $resourceCurrentState.CachingMode | Should -Be 'Manual'
            $resourceCurrentState.ContinuouslyAvailable | Should -BeFalse
            $resourceCurrentState.ShareState | Should -Be 'Online'
            $resourceCurrentState.ShareType | Should -Be 'FileSystemDirectory'
            $resourceCurrentState.ShadowCopy | Should -BeFalse
            $resourceCurrentState.Special | Should -BeFalse
            $resourceCurrentState.FullAccess | Should -BeNullOrEmpty
            $resourceCurrentState.ChangeAccess | Should -BeNullOrEmpty
            $resourceCurrentState.NoAccess | Should -BeNullOrEmpty

            <#
                    By design of the cmdlet `New-SmbShare`, the Everyone group is
                    always added when not providing any access permission members
                    in the configuration.
                #>
            $resourceCurrentState.ReadAccess | Should -HaveCount 1
            $resourceCurrentState.ReadAccess | Should -Contain 'Everyone'
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -BeTrue
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_CreateShare2_Config"
    ) {
        BeforeAll {
            $configurationName = $_
        }

        It 'Should compile the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath        = $TestDrive
                    ConfigurationData = $ConfigurationData
                }

                & $configurationName @configurationParameters
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
                $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
            } | Should -Not -Throw
        }

        It 'Should have set the resource and all the parameters should match' {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName `
                    -and $_.ResourceId -eq '[SmbShare]Integration_Test'
            }

            $resourceCurrentState.Ensure | Should -Be 'Present'
            $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.ShareName2
            $resourceCurrentState.Path | Should -Be $ConfigurationData.AllNodes.SharePath2
            $resourceCurrentState.Description | Should -BeNullOrEmpty
            $resourceCurrentState.EncryptData | Should -BeFalse
            $resourceCurrentState.ConcurrentUserLimit | Should -Be 0
            $resourceCurrentState.Description | Should -BeNullOrEmpty
            $resourceCurrentState.CachingMode | Should -Be 'Manual'
            $resourceCurrentState.ContinuouslyAvailable | Should -BeFalse
            $resourceCurrentState.ShareState | Should -Be 'Online'
            $resourceCurrentState.ShareType | Should -Be 'FileSystemDirectory'
            $resourceCurrentState.ShadowCopy | Should -BeFalse
            $resourceCurrentState.Special | Should -BeFalse
            $resourceCurrentState.FullAccess | Should -BeNullOrEmpty
            $resourceCurrentState.ReadAccess | Should -BeNullOrEmpty
            $resourceCurrentState.NoAccess | Should -BeNullOrEmpty

            <#
                    By design of the cmdlet `New-SmbShare`, the Everyone group is
                    always added when using `ReadAccess = @()` in the configuration.
                #>
            $resourceCurrentState.ChangeAccess | Should -HaveCount 1
            $resourceCurrentState.ChangeAccess | Should -Contain $ConfigurationData.AllNodes.UserName1
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -BeTrue
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_UpdateProperties_Config"
    ) {
        BeforeAll {
            $configurationName = $_
        }

        It 'Should compile the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath        = $TestDrive
                    ConfigurationData = $ConfigurationData
                }

                & $configurationName @configurationParameters
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
                $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
            } | Should -Not -Throw
        }

        It 'Should have set the resource and all the parameters should match' {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName `
                    -and $_.ResourceId -eq '[SmbShare]Integration_Test'
            }

            $resourceCurrentState.Ensure | Should -Be 'Present'
            $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.ShareName1
            $resourceCurrentState.Path | Should -Be $ConfigurationData.AllNodes.SharePath1
            $resourceCurrentState.Description | Should -Be 'A new description'
            $resourceCurrentState.ConcurrentUserLimit | Should -Be 20
            $resourceCurrentState.ShareState | Should -Be 'Online'
            $resourceCurrentState.ShareType | Should -Be 'FileSystemDirectory'
            $resourceCurrentState.ShadowCopy | Should -BeFalse
            $resourceCurrentState.Special | Should -BeFalse

            $resourceCurrentState.FullAccess | Should -HaveCount 1
            $resourceCurrentState.FullAccess | Should -Contain $ConfigurationData.AllNodes.UserName1

            $resourceCurrentState.ChangeAccess | Should -HaveCount 1
            $resourceCurrentState.ChangeAccess | Should -Contain $ConfigurationData.AllNodes.UserName2

            $resourceCurrentState.ReadAccess | Should -HaveCount 1
            $resourceCurrentState.ReadAccess | Should -Contain $ConfigurationData.AllNodes.UserName3

            $resourceCurrentState.NoAccess | Should -HaveCount 1
            $resourceCurrentState.NoAccess | Should -Contain $ConfigurationData.AllNodes.UserName4
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -BeTrue
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_RemovePermission_Config"
    ) {
        BeforeAll {
            $configurationName = $_
        }

        It 'Should compile the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath        = $TestDrive
                    ConfigurationData = $ConfigurationData
                }

                & $configurationName @configurationParameters
            } | Should -Not -Throw
        }

        It 'Should compile and apply the MOF without throwing' {
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
                $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
            } | Should -Not -Throw
        }

        It 'Should have set the resource and all the parameters should match' {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName `
                    -and $_.ResourceId -eq '[SmbShare]Integration_Test'
            }

            $resourceCurrentState.Ensure | Should -Be 'Present'
            $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.ShareName1
            $resourceCurrentState.FullAccess | Should -BeNullOrEmpty
            $resourceCurrentState.ChangeAccess | Should -BeNullOrEmpty
            $resourceCurrentState.NoAccess | Should -BeNullOrEmpty

            $resourceCurrentState.ReadAccess | Should -HaveCount 1
            $resourceCurrentState.ReadAccess | Should -Contain 'Everyone'
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -BeTrue
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_RecreateShare1_Config"
    ) {
        BeforeAll {
            $configurationName = $_
        }

        It 'Should compile the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath        = $TestDrive
                    ConfigurationData = $ConfigurationData
                }

                & $configurationName @configurationParameters
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
                $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
            } | Should -Not -Throw
        }

        It 'Should have set the resource and all the parameters should match' {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName `
                    -and $_.ResourceId -eq '[SmbShare]Integration_Test'
            }

            $resourceCurrentState.Ensure | Should -Be 'Present'
            $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.ShareName1
            $resourceCurrentState.Path | Should -Be $ConfigurationData.AllNodes.SharePath2
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -BeTrue
        }
    }


    $configurationName = "$($script:dscResourceName)_RemoveShare1_Config"

    Context ('When using configuration {0}' -f $configurationName) {
        It 'Should compile the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath        = $TestDrive
                    ConfigurationData = $ConfigurationData
                }

                & $configurationName @configurationParameters
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
                $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
            } | Should -Not -Throw
        }

        It 'Should have set the resource and all the parameters should match' {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName `
                    -and $_.ResourceId -eq '[SmbShare]Integration_Test'
            }

            $resourceCurrentState.Ensure | Should -Be 'Absent'
            $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.ShareName1
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -BeTrue
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_RemoveShare2_Config"
    ) {
        BeforeAll {
            $configurationName = $_
        }

        It 'Should compile the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath        = $TestDrive
                    ConfigurationData = $ConfigurationData
                }

                & $configurationName @configurationParameters
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
                $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
            } | Should -Not -Throw
        }

        It 'Should have set the resource and all the parameters should match' {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName `
                    -and $_.ResourceId -eq '[SmbShare]Integration_Test'
            }

            $resourceCurrentState.Ensure | Should -Be 'Absent'
            $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.ShareName2
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -BeTrue
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_Cleanup_Config"
    ) {
        BeforeAll {
            $configurationName = $_
        }

        It 'Should compile the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath        = $TestDrive
                    ConfigurationData = $ConfigurationData
                }

                & $configurationName @configurationParameters
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
