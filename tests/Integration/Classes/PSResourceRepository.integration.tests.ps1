$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceFriendlyName = 'PSResourceRepository'
$script:dscResourceName = "$($script:dscResourceFriendlyName)"

try
{
    Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
}
catch [System.IO.FileNotFoundException]
{
    throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
}

$initializationParams = @{
    DSCModuleName = $script:dscModuleName
    DSCResourceName = $script:dscResourceName
    ResourceType = 'Class'
    TestType = 'Integration'
}
$script:testEnvironment = Initialize-TestEnvironment @initializationParams

# Using try/finally to always cleanup.
try
{
    #region Integration Tests
    $configurationFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configurationFile

    Describe "$($script:dscResourceName)_Integration" {
        BeforeAll {
            $resourceId = "[$($script:dscResourceFriendlyName)]Integration_Test"
        }

        $configurationName = "$($script:dscResourceName)_Create_Config"

        Context ('When using configuration {0}' -f $configurationName) {

            It 'Should compile and apply the MOF without throwing' {
                BeforeAll {
                    #* Unregister the repository so we can add it.
                    Unregister-PSRepository -Name $ConfigurationData.NonNodeData.$configurationName.Name -Force
                }

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
                    $_.ConfigurationName -eq $configurationName -and $_.ResourceId -eq $resourceId
                }

                $shouldBeData = $ConfigurationData.NonNodeData.$configurationName

                # Key properties
                $resourceCurrentState.Name | Should -Be $shouldBeData.Name

                # Optional Properties
                $resourceCurrentState.SourceLocation            | Should -Be $shouldBeData.SourceLocation
                $resourceCurrentState.Default                   | Should -BeTrue
                $resourceCurrentState.SourceInfo                | Should -BeNullOrEmpty
                $resourceCurrentState.Credential                | Should -BeNullOrEmpty
                $resourceCurrentState.Proxy                     | Should -BeNullOrEmpty
                $resourceCurrentState.ProxyCredential           | Should -BeNullOrEmpty


                # Defaulted properties
                $resourceCurrentState.Ensure                    | Should -Be $shouldBeData.Ensure
                $resourceCurrentState.InstallationPolicy        | Should -Be 'Untrusted'
                $resourceCurrentState.PackageManagementProvider | Should -Be 'NuGet'

            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }
        }

        Wait-ForIdleLcm -Clear

        $configurationName = "$($script:dscResourceName)_Modify_Config"

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
                    $_.ConfigurationName -eq $configurationName -and $_.ResourceId -eq $resourceId
                }

                $shouldBeData = $ConfigurationData.NonNodeData.$configurationName

                # Key properties
                $resourceCurrentState.Name           | Should -Be $shouldBeData.Name

                # Optional properties
                $resourceCurrentState.SourceLocation            | Should -Be $shouldBeData.SourceLocation
                $resourceCurrentState.ScriptSourceLocation      | Should -Be $shouldBeData.ScriptSourceLocation
                $resourceCurrentState.PublishLocation           | Should -Be $shouldBeData.PublishLocation
                $resourceCurrentState.ScriptPublishLocation     | Should -Be $shouldBeData.ScriptPublishLocation
                $resourceCurrentState.InstallationPolicy        | Should -Be $shouldBeData.InstallationPolicy
                $resourceCurrentState.Credential                | Should -BeNullOrEmpty
                $resourceCurrentState.Default                   | Should -BeNullOrEmpty
                $resourceCurrentState.Proxy                     | Should -BeNullOrEmpty
                $resourceCurrentState.ProxyCredential           | Should -BeNullOrEmpty

                # Defaulted properties
                $resourceCurrentState.PackageManagementProvider | Should -Be 'NuGet'
                $resourceCurrentState.Ensure                    | Should -Be $shouldBeData.Ensure
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }
        }

        Wait-ForIdleLcm -Clear

        $configurationName = "$($script:dscResourceName)_Remove_Config"

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
                    $_.ConfigurationName -eq $configurationName -and $_.ResourceId -eq $resourceId
                }

                $shouldBeData = $ConfigurationData.NonNodeData.$configurationName

                # Key properties
                $resourceCurrentState.Name           | Should -Be $shouldBeData.Name

                # Defaulted properties
                $resourceCurrentState.InstallationPolicy        | Should -Be 'Untrusted'
                $resourceCurrentState.SourceLocation            | Should -BeNullOrEmpty
                $resourceCurrentState.PackageManagementProvider | Should -Be 'NuGet'
                $resourceCurrentState.Credential                | Should -BeNullOrEmpty
                $resourceCurrentState.Default                   | Should -BeNullOrEmpty
                $resourceCurrentState.PackageManagementProvider | Should -BeNullOrEmpty
                $resourceCurrentState.Proxy                     | Should -BeNullOrEmpty
                $resourceCurrentState.ProxyCredential           | Should -BeNullOrEmpty
                $resourceCurrentState.PublishLocation           | Should -BeNullOrEmpty
                $resourceCurrentState.ScriptPublishLocation     | Should -BeNullOrEmpty
                $resourceCurrentState.ScriptSourceLocation      | Should -BeNullOrEmpty
                $resourceCurrentState.SourceLocation            | Should -BeNullOrEmpty

                # Ensure will be Absent
                $resourceCurrentState.Ensure | Should -Be 'Absent'
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }
        }

        Wait-ForIdleLcm -Clear

    }
    #endregion
}
finally
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
