#region HEADER
$script:ModuleName = 'ComputerManagementDsc.Common'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

# Unit Test Template Version: 1.2.4
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath 'DscResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force
Import-Module (Join-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'Modules' -ChildPath $script:ModuleName)) -ChildPath "$script:ModuleName.psm1") -Force
#endregion HEADER

# Store the test machine timezone
$currentTimeZone = & tzutil.exe /g

# Change the current timezone so that a complete test occurs.
tzutil.exe /s 'Eastern Standard Time'

# Using try/finally to always cleanup even if something awful happens.
try
{
    InModuleScope $script:ModuleName {

        Describe 'ComputerManagementDsc.Common\Set-TimeZoneId' {
            <#
                The purpose of this test is to ensure the C# .NET code
                that is used to set the time zone if the Set-TimeZone
                cmdlet is not available but the Add-Type cmdlet is available

                The other conditions can be effectively tested with
                the unit tests, but the only way to test the C# .NET code
                is to execute it without mocking. This results in
                a destrutive change which is only allowed within the
                integration tests.
            #>
            Context '"Set-TimeZone" is not available but "Add-Type" is available' {
                Mock `
                    -CommandName Get-Command `
                    -ParameterFilter {
                        $Name -eq 'Add-Type'
                    } -MockWith {
                        'Add-Type'
                    }

                Mock `
                    -CommandName Get-Command `
                    -ParameterFilter {
                        $Name -eq 'Set-TimeZone'
                    }

                Mock -CommandName 'TzUtil.exe' -MockWith {
                    $Script:LASTEXITCODE = 0
                    return 'OK'
                }

                It 'Should not throw an exception' {
                    { Set-TimeZoneId -TimezoneId 'Eastern Standard Time' } | Should -Not -Throw
                }

                It 'Should have set the time zone to Eastern Standard Time' {
                    Get-TimeZoneId | Should -Be 'Eastern Standard Time'
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-Command `
                        -ParameterFilter {
                            $Name -eq 'Add-Type'
                        } -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-Command `
                        -ParameterFilter {
                            $Name -eq 'Set-TimeZone'
                        } -Exactly -Times 1

                    Assert-MockCalled -CommandName TzUtil.exe -Exactly -Times 0
                }
            }
        }
    }
}
finally
{
    # Restore the test machine timezone
    & tzutil.exe /s $CurrentTimeZone
}
