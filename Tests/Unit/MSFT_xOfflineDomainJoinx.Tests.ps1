$script:DSCModuleName = 'xComputerManagement'
$script:DSCResourceName = 'MSFT_xOfflineDomainJoin'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit
#endregion HEADER

# Begin Testing
try
{
    #region Pester Tests
    InModuleScope $script:DSCResourceName {
        $script:DSCResourceName = 'MSFT_xOfflineDomainJoin'

        $testOfflineDomainJoin = @{
            IsSingleInstance = 'Yes'
            RequestFile      = 'C:\ODJRequest.txt'
            Verbose          = $true
        }

        Describe "$($script:DSCResourceName)\Get-TargetResource" {
            It 'Should return the correct values' {
                $result = Get-TargetResource `
                    @TestOfflineDomainJoin

                $result.IsSingleInstance       | Should Be $testOfflineDomainJoin.IsSingleInstance
                $result.RequestFile            | Should Be ''
            }
        }

        Describe "$($script:DSCResourceName)\Set-TargetResource" {
            Context 'Domain is not joined' {
                Mock -CommandName Test-Path -MockWith {
                    return $true
                }

                Mock -CommandName Join-Domain

                It 'Should not throw exception' {
                    { Set-TargetResource @TestOfflineDomainJoin } | Should Not Throw
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

                    { Test-TargetResource @TestOfflineDomainJoin } | Should Throw $errorRecord
                }

                It 'Should do call all the mocks' {
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                    Assert-MockCalled -CommandName Join-Domain -Exactly -Times 0
                }
            }
        }

        Describe "$($script:DSCResourceName)\Test-TargetResource" {
            Context 'Domain is not joined' {
                Mock -CommandName Test-Path -MockWith {
                    return $true
                }

                Mock -CommandName Get-DomainName -MockWith {
                    return $null
                }

                It 'Should return false' {
                    Test-TargetResource @TestOfflineDomainJoin | should be $false
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
                    Test-TargetResource @TestOfflineDomainJoin | should be $true
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

                    { Test-TargetResource @TestOfflineDomainJoin } | Should Throw $errorRecord
                }

                It 'Should do call all the mocks' {
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-DomainName -Exactly -Times 0
                }
            }
        }

        Describe "$($script:DSCResourceName)\Join-Domain" {
            Context 'Domain Join successful' {
                Mock -CommandName djoin.exe -MockWith {
                    $script:LASTEXITCODE = 0
                    return "OK"
                }

                It 'Should not throw' {
                    { Join-Domain -RequestFile 'c:\doesnotmatter.txt' } | Should Not Throw
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
                    { Join-Domain -RequestFile 'c:\doesnotmatter.txt' } | Should Throw $errorRecord
                }

                It 'Should do call all the mocks' {
                    Assert-MockCalled -CommandName djoin.exe -Exactly -Times 1
                }
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
