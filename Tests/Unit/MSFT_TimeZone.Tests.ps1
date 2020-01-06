#region HEADER
$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'MSFT_TimeZone'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

# Unit Test Template Version: 1.2.4
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
    -ResourceType 'Mof' `
    -TestType Unit
#endregion HEADER

# Begin Testing
try
{
    #region Pester Tests
    InModuleScope $script:dscResourceName {
        $script:dscResourceName = 'MSFT_TimeZone'

        Describe "$($script:dscResourceName) MOF single instance schema" {
            It 'Should have mandatory IsSingleInstance parameter and one other parameter' {
                $timeZoneResource = Get-DscResource -Name TimeZone

                $timeZoneResource.Properties.Where{
                    $_.Name -eq 'IsSingleInstance'
                }.IsMandatory | Should -BeTrue

                $timeZoneResource.Properties.Where{
                    $_.Name -eq 'IsSingleInstance'
                }.Values | Should -Be 'Yes'
            }
        }

        Describe "$($script:dscResourceName)\Get-TargetResource" {
            Mock `
                -CommandName Get-TimeZoneId `
                -MockWith { 'Pacific Standard Time' }

            $timeZone = Get-TargetResource `
                -TimeZone 'Pacific Standard Time' `
                -IsSingleInstance 'Yes' `
                -Verbose

            It 'Should return hashtable with Key TimeZone' {
                $timeZone.ContainsKey('TimeZone') | Should -BeTrue
            }

            It 'Should return hashtable with Value that matches "Pacific Standard Time"' {
                $timeZone.TimeZone = 'Pacific Standard Time'
            }
        }

        Describe "$($script:dscResourceName)\Set-TargetResource" {
            Mock `
                -CommandName Set-TimeZoneId

            Mock `
                -CommandName Get-TimeZoneId `
                -MockWith { 'Eastern Standard Time' }

            It 'Call Set-TimeZoneId' {
                Set-TargetResource `
                    -TimeZone 'Pacific Standard Time' `
                    -IsSingleInstance 'Yes' `
                    -Verbose

                Assert-MockCalled `
                    -CommandName Set-TimeZoneId `
                    -Exactly 1
            }

            It 'Should not call Set-TimeZoneId when Current TimeZone already set to desired State' {
                $systemTimeZone = Get-TargetResource `
                    -TimeZone 'Eastern Standard Time' `
                    -IsSingleInstance 'Yes' `
                    -Verbose

                Set-TargetResource `
                    -TimeZone $systemTimeZone.TimeZone `
                    -IsSingleInstance 'Yes' `
                    -Verbose

                Assert-MockCalled `
                    -CommandName Set-TimeZoneId `
                    -Scope It `
                    -Exactly 0
            }
        }

        Describe "$($script:dscResourceName)\Test-TargetResource" {
            Mock `
                -ModuleName ComputerManagementDsc.Common `
                -CommandName Get-TimeZoneId `
                -MockWith { 'Pacific Standard Time' }

            It 'Should return true when Test is passed Time Zone thats already set' {
                Test-TargetResource `
                    -TimeZone 'Pacific Standard Time' `
                    -IsSingleInstance 'Yes' `
                    -Verbose | Should -BeTrue
            }

            It 'Should return false when Test is passed Time Zone that is not set' {
                Test-TargetResource `
                    -TimeZone 'Eastern Standard Time' `
                    -IsSingleInstance 'Yes' `
                    -Verbose | Should -BeFalse
            }
        }
    } #end InModuleScope $DSCResourceName
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
