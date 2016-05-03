$Global:DSCModuleName      = 'xComputerManagement'
$Global:DSCResourceName    = 'MSFT_xComputer'

#region HEADER
# Unit Test Template Version: 1.1.0
[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $Global:DSCResourceName `
    -TestType Unit 
#endregion

# Begin Testing
try
{
    #region Pester Tests

    InModuleScope $Global:DSCResourceName {

        Describe $Global:DSCResourceName {
            
            Mock Add-Content {}
            Mock Set-Content {}
            
            Context "A host entry doesn't exist, and should" {
                $testParams = @{
                    HostName = "www.contoso.com"
                    IPAddress = "192.168.0.156"
                }
                
                Mock Get-Content { 
                    return @(
                        "# A mocked example of a host file - this line is a comment",
                        "",
                        "127.0.0.1       localhost",
                        "127.0.0.1  www.anotherexample.com",
                        ""
                    )
                }
                
                It "should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
                }
                
                It "should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }
                
                It "should create the entry in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Add-Content
                }
            }
            
            Context "A host entry exists but has the wrong IP address" {
                $testParams = @{
                    HostName = "www.contoso.com"
                    IPAddress = "192.168.0.156"
                }
                
                Mock Get-Content {
                    return @(
                        "# A mocked example of a host file - this line is a comment",
                        "",
                        "127.0.0.1       localhost",
                        "127.0.0.1  www.anotherexample.com",
                        "127.0.0.1         $($testParams.HostName)",
                        ""
                    )
                }
                
                It "should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Present" 
                }
                
                It "should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }
                
                It "should update the entry in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-Content
                }
            }
            
            Context "A host entry exists with the correct IP address" {
                $testParams = @{
                    HostName = "www.contoso.com"
                    IPAddress = "192.168.0.156"
                }
                
                Mock Get-Content {
                    return @(
                        "# A mocked example of a host file - this line is a comment",
                        "",
                        "127.0.0.1       localhost",
                        "127.0.0.1  www.anotherexample.com",
                        "$($testParams.IPAddress)         $($testParams.HostName)",
                        ""
                    )
                }
                
                It "should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Present"
                }
                
                It "should return true from the test method" {
                    Test-TargetResource @testParams | Should Be $true
                }
            }
            
            Context "A host entry exists but it shouldn't" {
                $testParams = @{
                    HostName = "www.contoso.com"
                    Ensure = "Absent"
                }
                
                Mock Get-Content {
                    return @(
                        "# A mocked example of a host file - this line is a comment",
                        "",
                        "127.0.0.1       localhost",
                        "127.0.0.1  www.anotherexample.com",
                        "127.0.0.1         $($testParams.HostName)",
                        ""
                    )
                }
                
                It "should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Present"
                }
                
                It "should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }
                
                It "should remove the entry in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-Content
                }
            }
            
            Context "A host entry doesn't it exist and shouldn't" {
                $testParams = @{
                    HostName = "www.contoso.com"
                    Ensure = "Absent"
                }
                
                Mock Get-Content {
                    return @(
                        "# A mocked example of a host file - this line is a comment",
                        "",
                        "127.0.0.1       localhost",
                        "127.0.0.1  www.anotherexample.com",
                        ""
                    )
                }
                
                It "should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                }
                
                It "should return true from the test method" {
                    Test-TargetResource @testParams | Should Be $true
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
