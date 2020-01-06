<#
    .SYNOPSIS
        Integration tests for DSC resource SmbShare.
#>

#region HEADER
$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceFriendlyName = 'SmbShare'
$script:dscResourceName = "MSFT_$($script:dscResourceFriendlyName)"

# Integration Test Template Version: 1.3.3
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath 'DscResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -TestType Integration
#endregion

#region HEADER

$script:dscResourceFriendlyName = 'SmbShare'
$script:dcsResourceName = "MSFT_$($script:dscResourceFriendlyName)"

#region Integration Tests
$configurationFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dcsResourceName).config.ps1"
. $configurationFile

Describe "$($script:dcsResourceName)_Integration" {
    $configurationName = "$($script:dcsResourceName)_Prerequisites_Config"

    Context ('When using configuration {0}' -f $configurationName) {
        It 'Should compile and apply the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath        = $TestDrive
                    ConfigurationData = $ConfigurationData
                }

                & $configurationName @configurationParameters

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

    $configurationName = "$($script:dcsResourceName)_CreateShare1_Config"

    Context ('When using configuration {0}' -f $configurationName) {
        It 'Should compile and apply the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath        = $TestDrive
                    ConfigurationData = $ConfigurationData
                }

                & $configurationName @configurationParameters

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
                    -and $_.ResourceId -eq "[$($script:dscResourceFriendlyName)]Integration_Test"
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

    $configurationName = "$($script:dcsResourceName)_CreateShare2_Config"

    Context ('When using configuration {0}' -f $configurationName) {
        It 'Should compile and apply the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath        = $TestDrive
                    ConfigurationData = $ConfigurationData
                }

                & $configurationName @configurationParameters

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
                    -and $_.ResourceId -eq "[$($script:dscResourceFriendlyName)]Integration_Test"
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

    $configurationName = "$($script:dcsResourceName)_UpdateProperties_Config"

    Context ('When using configuration {0}' -f $configurationName) {
        It 'Should compile and apply the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath        = $TestDrive
                    ConfigurationData = $ConfigurationData
                }

                & $configurationName @configurationParameters

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
                    -and $_.ResourceId -eq "[$($script:dscResourceFriendlyName)]Integration_Test"
            }

            $resourceCurrentState.Ensure | Should -Be 'Present'
            $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.ShareName1
            $resourceCurrentState.Path | Should -Be $ConfigurationData.AllNodes.SharePath1
            $resourceCurrentState.Description | Should -Be 'A new description'
            #$resourceCurrentState.EncryptData | Should -BeTrue
            $resourceCurrentState.ConcurrentUserLimit | Should -Be 20
            #$resourceCurrentState.FolderEnumerationMode | Should -Be 'AccessBased'
            #$resourceCurrentState.CachingMode | Should -Be 'None'
            #$resourceCurrentState.ContinuouslyAvailable | Should -BeTrue
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

    $configurationName = "$($script:dcsResourceName)_RemovePermission_Config"

    Context ('When using configuration {0}' -f $configurationName) {
        It 'Should compile and apply the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath        = $TestDrive
                    ConfigurationData = $ConfigurationData
                }

                & $configurationName @configurationParameters

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
                    -and $_.ResourceId -eq "[$($script:dscResourceFriendlyName)]Integration_Test"
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

    $configurationName = "$($script:dcsResourceName)_RemoveShare1_Config"

    Context ('When using configuration {0}' -f $configurationName) {
        It 'Should compile and apply the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath        = $TestDrive
                    ConfigurationData = $ConfigurationData
                }

                & $configurationName @configurationParameters

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
                    -and $_.ResourceId -eq "[$($script:dscResourceFriendlyName)]Integration_Test"
            }

            $resourceCurrentState.Ensure | Should -Be 'Absent'
            $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.ShareName1
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -BeTrue
        }
    }

    $configurationName = "$($script:dcsResourceName)_RemoveShare2_Config"

    Context ('When using configuration {0}' -f $configurationName) {
        It 'Should compile and apply the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath        = $TestDrive
                    ConfigurationData = $ConfigurationData
                }

                & $configurationName @configurationParameters

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
                    -and $_.ResourceId -eq "[$($script:dscResourceFriendlyName)]Integration_Test"
            }

            $resourceCurrentState.Ensure | Should -Be 'Absent'
            $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.ShareName2
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -BeTrue
        }
    }

    $configurationName = "$($script:dcsResourceName)_Cleanup_Config"

    Context ('When using configuration {0}' -f $configurationName) {
        It 'Should compile and apply the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath        = $TestDrive
                    ConfigurationData = $ConfigurationData
                }

                & $configurationName @configurationParameters

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
#endregion
