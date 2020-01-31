$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'DSC_OfflineDomainJoin'

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
        $testOfflineDomainJoin = @{
            IsSingleInstance = 'Yes'
            RequestFile      = 'C:\ODJRequest.txt'
            Verbose          = $true
        }

        Describe 'DSC_OfflineDomainJoin\Get-TargetResource' {
            It 'Should return the correct values' {
                $result = Get-TargetResource `
                    @TestOfflineDomainJoin

                $result.IsSingleInstance | Should -Be $testOfflineDomainJoin.IsSingleInstance
                $result.RequestFile | Should -Be ''
            }
        }

        Describe 'DSC_OfflineDomainJoin\Set-TargetResource' {
            Context 'Domain is not joined' {
                Mock -CommandName Test-Path -MockWith {
                    return $true
                }

                Mock -CommandName Join-Domain

                It 'Should not throw exception' {
                    { Set-TargetResource @TestOfflineDomainJoin } | Should -Not -Throw
                }

                It 'Should do call all the mocks' {
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                    Assert-MockCalled -CommandName Join-Domain -Exactly -Times 1
                }
            }

            Context 'ODJ Request file is not found' {
                Mock -CommandName Test-Path -MockWith {
                    return $false
                }

                Mock -CommandName Join-Domain

                It 'Should throw expected exception' {
                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($LocalizedData.RequestFileNotFoundError -f $testOfflineDomainJoin.RequestFile) `
                        -ArgumentName 'RequestFile'

                    { Test-TargetResource @TestOfflineDomainJoin } | Should -Throw $errorRecord
                }

                It 'Should do call all the mocks' {
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                    Assert-MockCalled -CommandName Join-Domain -Exactly -Times 0
                }
            }
        }

        Describe 'DSC_OfflineDomainJoin\Test-TargetResource' {
            Context 'Domain is not joined' {
                Mock -CommandName Test-Path -MockWith {
                    return $true
                }

                Mock -CommandName Get-DomainName -MockWith {
                    return $null
                }

                It 'Should return false' {
                    Test-TargetResource @TestOfflineDomainJoin | Should -BeFalse
                }

                It 'Should do call all the mocks' {
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-DomainName -Exactly -Times 1
                }
            }

            Context 'Domain is already joined' {
                Mock -CommandName Test-Path -MockWith {
                    return $true
                }

                Mock -CommandName Get-DomainName -MockWith {
                    return 'contoso.com'
                }

                It 'Should return false' {
                    Test-TargetResource @TestOfflineDomainJoin | Should -BeTrue
                }

                It 'Should do call all the mocks' {
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-DomainName -Exactly -Times 1
                }
            }

            Context 'ODJ Request file is not found' {
                Mock -CommandName Test-Path -MockWith {
                    return $false
                }

                Mock -CommandName Get-DomainName -MockWith {
                    return 'contoso.com'
                }

                It 'Should throw expected exception' {
                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($LocalizedData.RequestFileNotFoundError -f $testOfflineDomainJoin.RequestFile) `
                        -ArgumentName 'RequestFile'

                    { Test-TargetResource @TestOfflineDomainJoin } | Should -Throw $errorRecord
                }

                It 'Should do call all the mocks' {
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-DomainName -Exactly -Times 0
                }
            }
        }

        Describe 'DSC_OfflineDomainJoin\Join-Domain' {
            Context 'Domain Join successful' {
                Mock -CommandName djoin.exe -MockWith {
                    $script:LASTEXITCODE = 0
                    return "OK"
                }

                It 'Should not throw' {
                    { Join-Domain -RequestFile 'c:\doesnotmatter.txt' } | Should -Not -Throw
                }

                It 'Should do call all the mocks' {
                    Assert-MockCalled -CommandName djoin.exe -Exactly -Times 1
                }
            }

            Context 'Domain Join successful' {
                Mock -CommandName djoin.exe -MockWith {
                    $script:LASTEXITCODE = 99
                    return "ERROR"
                }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message $($LocalizedData.DjoinError -f 99)

                It 'Should not throw' {
                    { Join-Domain -RequestFile 'c:\doesnotmatter.txt' } | Should -Throw $errorRecord
                }

                It 'Should do call all the mocks' {
                    Assert-MockCalled -CommandName djoin.exe -Exactly -Times 1
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
