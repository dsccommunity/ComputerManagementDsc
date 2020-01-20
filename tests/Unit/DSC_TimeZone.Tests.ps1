$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'DSC_TimeZone'

function Invoke-TestSetup
{
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
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

# Begin Testing
try
{
    InModuleScope $script:dscResourceName {
        Describe 'DSC_TimeZone MOF single instance schema' {
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

        Describe 'DSC_TimeZone\Get-TargetResource' {
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

        Describe 'DSC_TimeZone\Set-TargetResource' {
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

        Describe 'DSC_TimeZone\Test-TargetResource' {
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
    }
}
finally
{
    Invoke-TestCleanup
}
