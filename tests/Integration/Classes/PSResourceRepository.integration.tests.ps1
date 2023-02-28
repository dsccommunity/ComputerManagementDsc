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
                $resourceCurrentState.Ensure         | Should -Be $shouldBeData.Ensure
                $resourceCurrentState.SourceLocation | Should -Be $shouldBeData.SourceLocation

                # Optional Properties
                $resourceCurrentState.Credential      | Should -BeNullOrEmpty
                $resourceCurrentState.Proxy           | Should -BeNullOrEmpty
                $resourceCurrentState.ProxyCredential | Should -BeNullOrEmpty
                $resourceCurrentState.Default         | Should -BeNullOrEmpty

                # Defaulted properties
                $resourceCurrentState.PublishLocation           | Should -Be 'https://www.nuget.org/api/v2/package/'
                $resourceCurrentState.ScriptPublishLocation     | Should -Be 'https://www.nuget.org/api/v2/package/'
                $resourceCurrentState.ScriptSourceLocation      | Should -BeNullOrEmpty
                $resourceCurrentState.PackageManagementProvider | Should -Be 'NuGet'
                $resourceCurrentState.InstallationPolicy        | Should -Be 'Untrusted'

                # Read-only properties
                $resourceCurrentState.Reasons | Should -BeNullOrEmpty
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
                $resourceCurrentState.Name | Should -Be $shouldBeData.Name

                # Optional properties
                $resourceCurrentState.SourceLocation            | Should -Be $shouldBeData.SourceLocation
                $resourceCurrentState.ScriptSourceLocation      | Should -Be $shouldBeData.ScriptSourceLocation
                $resourceCurrentState.PublishLocation           | Should -Be $shouldBeData.PublishLocation
                $resourceCurrentState.ScriptPublishLocation     | Should -Be $shouldBeData.ScriptPublishLocation
                $resourceCurrentState.InstallationPolicy        | Should -Be $shouldBeData.InstallationPolicy
                $resourceCurrentState.PackageManagementProvider | Should -Be $shouldBeData.PackageManagementProvider
                $resourceCurrentState.Credential                | Should -BeNullOrEmpty
                $resourceCurrentState.Default                   | Should -BeNullOrEmpty
                $resourceCurrentState.Proxy                     | Should -BeNullOrEmpty
                $resourceCurrentState.ProxyCredential           | Should -BeNullOrEmpty

                # Defaulted properties
                $resourceCurrentState.Ensure | Should -Be $shouldBeData.Ensure

                # Read-only properties
                $resourceCurrentState.Reasons | Should -BeNullOrEmpty
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
                $resourceCurrentState.Name | Should -Be $shouldBeData.Name

                # Defaulted properties
                $resourceCurrentState.InstallationPolicy        | Should -BeNullOrEmpty
                $resourceCurrentState.SourceLocation            | Should -BeNullOrEmpty
                $resourceCurrentState.PackageManagementProvider | Should -BeNullOrEmpty
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

                # Read-only properties
                $resourceCurrentState.Reasons | Should -BeNullOrEmpty
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }
        }

        Wait-ForIdleLcm -Clear
    }

    Context 'When using Invoke-DscResource' {
        BeforeAll {
            $script:mockInvokeDscResourceParameters = @{
                ModuleName = $script:dscModuleName
                Name       = $script:dscResourceFriendlyName
                Verbose    = $true
            }
        }

        BeforeEach {
            Wait-ForIdleLcm -Clear
        }

        Context 'When the configuration is not in desired state' {
            Context 'When calling method Get()' {
                It 'Should not throw and return the correct values for each property' {
                    {
                        $script:resourceCurrentState = Invoke-DscResource @mockInvokeDscResourceParameters -Method 'Get' -Property @{
                            Name                      = 'PSTestGallery'
                            Ensure                    = 'Present'
                            SourceLocation            = 'https://www.nuget.org/api/v2'
                            PublishLocation           = 'https://www.nuget.org/api/v2/package/'
                            ScriptSourceLocation      = 'https://www.nuget.org/api/v2/items/psscript/'
                            ScriptPublishLocation     = 'https://www.nuget.org/api/v2/package/'
                            InstallationPolicy        = 'Trusted'
                            PackageManagementProvider = 'NuGet'
                        }
                    } | Should -Not -Throw

                    $resourceCurrentState.Name | Should -Be 'PSTestGallery'
                    $resourceCurrentState.Ensure | Should -Be 'Absent'
                    $resourceCurrentState.PackageManagementProvider | Should -BeNullOrEmpty
                    $resourceCurrentState.Proxy | Should -BeNullOrEmpty
                    $resourceCurrentState.ProxyCredential | Should -BeNullOrEmpty
                    $resourceCurrentState.PublishLocation | Should -BeNullOrEmpty
                    $resourceCurrentState.ScriptPublishLocation | Should -BeNullOrEmpty
                    $resourceCurrentState.ScriptSourceLocation | Should -BeNullOrEmpty
                    $resourceCurrentState.SourceLocation | Should -BeNullOrEmpty

                    $resourceCurrentState.Reasons | Should -HaveCount 7

                    $resourceCurrentState.Reasons.Code | Should -Contain 'PSResourceRepository:PSResourceRepository:ScriptPublishLocation'
                    $resourceCurrentState.Reasons.Phrase | Should -Contain 'The property ScriptPublishLocation should be "https://www.nuget.org/api/v2/package/", but was ""'

                    $resourceCurrentState.Reasons.Code | Should -Contain 'PSResourceRepository:PSResourceRepository:InstallationPolicy'
                    $resourceCurrentState.Reasons.Phrase | Should -Contain 'The property InstallationPolicy should be "Trusted", but was ""'

                    $resourceCurrentState.Reasons.Code | Should -Contain 'PSResourceRepository:PSResourceRepository:Ensure'
                    $resourceCurrentState.Reasons.Phrase | Should -Contain 'The property Ensure should be "Present", but was "Absent"'

                    $resourceCurrentState.Reasons.Code | Should -Contain 'PSResourceRepository:PSResourceRepository:PackageManagementProvider'
                    $resourceCurrentState.Reasons.Phrase | Should -Contain 'The property PackageManagementProvider should be "NuGet", but was ""'

                    $resourceCurrentState.Reasons.Code | Should -Contain 'PSResourceRepository:PSResourceRepository:ScriptSourceLocation'
                    $resourceCurrentState.Reasons.Phrase | Should -Contain 'The property ScriptSourceLocation should be "https://www.nuget.org/api/v2/items/psscript/", but was ""'

                    $resourceCurrentState.Reasons.Code | Should -Contain 'PSResourceRepository:PSResourceRepository:PublishLocation'
                    $resourceCurrentState.Reasons.Phrase | Should -Contain 'The property PublishLocation should be "https://www.nuget.org/api/v2/package/", but was ""'

                    $resourceCurrentState.Reasons.Code | Should -Contain 'PSResourceRepository:PSResourceRepository:SourceLocation'
                    $resourceCurrentState.Reasons.Phrase | Should -Contain 'The property SourceLocation should be "https://www.nuget.org/api/v2", but was ""'
                }
            }
        }
    }
    #endregion
}
finally
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
