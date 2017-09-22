$script:DSCModuleName      = 'xComputerManagement'
$script:DSCResourceName    = 'MSFT_xOfflineDomainJoin'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
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

        $TestOfflineDomainJoin = @{
            IsSingleInstance = 'Yes'
            RequestFile = 'C:\ODJRequest.txt'
        }

        Describe "$($script:DSCResourceName)\Get-TargetResource" {

            It 'should return the correct values' {
                $Result = Get-TargetResource `
                    @TestOfflineDomainJoin

                $Result.IsSingleInstance       | Should Be $TestOfflineDomainJoin.IsSingleInstance
                $Result.RequestFile            | Should Be ''
            }
        }

        Describe "$($script:DSCResourceName)\Set-TargetResource" {
            Mock Test-Path -MockWith { return $True }
            Mock Join-Domain

            Context 'Domain is not joined' {
                It 'should not throw exception' {
                    { Set-TargetResource @TestOfflineDomainJoin } | Should Not Throw
                }
                It 'Should do call all the mocks' {
                    Assert-MockCalled Test-Path -Times 1
                    Assert-MockCalled Join-Domain -Times 1
                }
            }

            Mock Test-Path -MockWith { return $False }

            Context 'ODJ Request file is not found' {
                It 'should throw RequestFileNotFoundError exception' {
                    $errorId = 'RequestFileNotFoundError'
                    $errorCategory = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                    $errorMessage = $($LocalizedData.RequestFileNotFoundError) `
                        -f $TestOfflineDomainJoin.RequestFile
                    $exception = New-Object -TypeName System.ArgumentException `
                        -ArgumentList $errorMessage
                    $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                        -ArgumentList $exception, $errorId, $errorCategory, $null

                    { Test-TargetResource @TestOfflineDomainJoin } | Should Throw $errorRecord
                }
                It 'should do call all the mocks' {
                    Assert-MockCalled Test-Path -Times 1
                    Assert-MockCalled Join-Domain -Times 0
                }
            }
        }

        Describe "$($script:DSCResourceName)\Test-TargetResource" {
            Mock Test-Path -MockWith { return $True }
            Mock Get-DomainName -MockWith { return $null }

            Context 'Domain is not joined' {
                It 'should return false' {
                    Test-TargetResource @TestOfflineDomainJoin | should be $false
                }
                It 'Should do call all the mocks' {
                    Assert-MockCalled Test-Path -Times 1
                    Assert-MockCalled Get-DomainName -Times 1
                }
            }

            Mock Get-DomainName -MockWith { return 'contoso.com' }

            Context 'Domain is already joined' {
                It 'should return false' {
                    Test-TargetResource @TestOfflineDomainJoin | should be $true
                }
                It 'Should do call all the mocks' {
                    Assert-MockCalled Test-Path -Times 1
                    Assert-MockCalled Get-DomainName -Times 1
                }
            }

            Mock Test-Path -MockWith { return $False }

            Context 'ODJ Request file is not found' {
                It 'should throw RequestFileNotFoundError exception' {
                    $errorId = 'RequestFileNotFoundError'
                    $errorCategory = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                    $errorMessage = $($LocalizedData.RequestFileNotFoundError) `
                        -f $TestOfflineDomainJoin.RequestFile
                    $exception = New-Object -TypeName System.ArgumentException `
                        -ArgumentList $errorMessage
                    $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                        -ArgumentList $exception, $errorId, $errorCategory, $null

                    { Test-TargetResource @TestOfflineDomainJoin } | Should Throw $errorRecord
                }
                It 'Should do call all the mocks' {
                    Assert-MockCalled Test-Path -Times 1
                    Assert-MockCalled Get-DomainName -Times 0
                }
            }
        }

        Describe "$($script:DSCResourceName)\Join-Domain" {
            Mock djoin.exe -MockWith { $script:LASTEXITCODE = 0; return "OK" }

            Context 'Domain Join successful' {
                It 'should not throw' {
                    { Join-Domain -RequestFile 'c:\doesnotmatter.txt' } | Should Not Throw
                }
                It 'Should do call all the mocks' {
                    Assert-MockCalled djoin.exe -Times 1
                }
            }

            Mock djoin.exe -MockWith { $script:LASTEXITCODE = 99; return "ERROR" }

            Context 'Domain Join successful' {
                $errorId = 'DjoinError'
                $errorCategory = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                $errorMessage = $($LocalizedData.DjoinError) `
                    -f 99
                $exception = New-Object -TypeName System.ArgumentException `
                    -ArgumentList $errorMessage
                $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                    -ArgumentList $exception, $errorId, $errorCategory, $null

                It 'should not throw' {
                    { Join-Domain -RequestFile 'c:\doesnotmatter.txt' } | Should Throw $errorRecord
                }
                It 'Should do call all the mocks' {
                    Assert-MockCalled djoin.exe -Times 1
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
