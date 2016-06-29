$Global:DSCModuleName      = 'xComputerManagement'
$Global:DSCResourceName    = 'MSFT_xComputer'

#region HEADER
[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}
else
{
    & git @('-C',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'),'pull')
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
            # A real password isn't needed here - use this next line to avoid triggering PSSA rule
            $SecPassword = New-Object -Type SecureString
            $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'USER',$SecPassword
            $NotComputerName  = if($env:COMPUTERNAME -ne 'othername'){'othername'}else{'name'}
        
            Context "$($Global:DSCResourceName)\Test-TargetResource" {
                Mock Get-WMIObject {[PSCustomObject]@{DomainName = 'ContosoLtd'}} -ParameterFilter {$Class -eq 'Win32_NTDomain'}
                It 'Throws if both DomainName and WorkGroupName are specified' {
                    {Test-TargetResource -Name $Env:ComputerName -DomainName 'contoso.com' -WorkGroupName 'workgroup'} | Should Throw
                }
                It 'Throws if Domain is specified without Credentials' {
                    {Test-TargetResource -Name $Env:ComputerName -DomainName 'contoso.com'} | Should Throw
                }
                It 'Should return True if Domain name is same as specified' {
                    Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Contoso.com';Workgroup='Contoso.com';PartOfDomain=$true}}
                    Mock GetComputerDomain {'contoso.com'}
                    Test-TargetResource -Name $Env:ComputerName -DomainName 'Contoso.com' -Credential $Credential | Should Be $true
                }
                It 'Should return True if Workgroup name is same as specified' {
                    Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Workgroup';Workgroup='Workgroup';PartOfDomain=$false}}
                    Mock GetComputerDomain {''}
                    Test-TargetResource -Name $Env:ComputerName -WorkGroupName 'workgroup' | Should Be $true
                }
                It 'Should return True if ComputerName and Domain name is same as specified' {
                    Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Contoso.com';Workgroup='Contoso.com';PartOfDomain=$true}}
                    Mock GetComputerDomain {'contoso.com'}
                    Test-TargetResource -Name $Env:ComputerName -DomainName 'contoso.com' -Credential $Credential | Should Be $true
                    Test-TargetResource -Name 'localhost' -DomainName 'contoso.com' -Credential $Credential | Should Be $true
                }
                It 'Should return True if ComputerName and Workgroup is same as specified' {
                    Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Workgroup';Workgroup='Workgroup';PartOfDomain=$false}}
                    Mock GetComputerDomain {''}
                    Test-TargetResource -Name $Env:ComputerName -WorkGroupName 'workgroup' | Should Be $true
                    Test-TargetResource -Name 'localhost' -WorkGroupName 'workgroup' | Should Be $true
                }
                It 'Should return True if ComputerName is same and no Domain or Workgroup specified' {
                    Mock Get-WmiObject {[PSCustomObject]@{Domain = 'Workgroup';Workgroup='Workgroup';PartOfDomain=$false}}
                    Mock GetComputerDomain {''}
                    Test-TargetResource -Name $Env:ComputerName | Should Be $true
                    Test-TargetResource -Name 'localhost' | Should Be $true
                    Mock Get-WmiObject {[PSCustomObject]@{Domain = 'Contoso.com';Workgroup='Contoso.com';PartOfDomain=$true}}
                    Mock GetComputerDomain {'contoso.com'}
                    Test-TargetResource -Name $Env:ComputerName | Should Be $true
                    Test-TargetResource -Name 'localhost' | Should Be $true
                }
                It 'Should return False if ComputerName is not same and no Domain or Workgroup specified' {
                    Mock Get-WmiObject {[PSCustomObject]@{Domain = 'Workgroup';Workgroup='Workgroup';PartOfDomain=$false}}
                    Mock GetComputerDomain {''}
                    Test-TargetResource -Name $NotComputerName | Should Be $false
                    Mock Get-WmiObject {[PSCustomObject]@{Domain = 'Contoso.com';Workgroup='Contoso.com';PartOfDomain=$true}}
                    Mock GetComputerDomain {'contoso.com'}
                    Test-TargetResource -Name $NotComputerName | Should Be $false
                }
                It 'Should return False if Domain name is not same as specified' {
                    Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Contoso.com';Workgroup='Contoso.com';PartOfDomain=$true}}
                    Mock GetComputerDomain {'contoso.com'}
                    Test-TargetResource -Name $Env:ComputerName -DomainName 'adventure-works.com' -Credential $Credential  | Should Be $false
                    Test-TargetResource -Name 'localhost' -DomainName 'adventure-works.com' -Credential $Credential  | Should Be $false
                }
                It 'Should return False if Workgroup name is not same as specified' {
                    Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Workgroup';Workgroup='Workgroup';PartOfDomain=$false}}
                    Mock GetComputerDomain {''}
                    Test-TargetResource -Name $Env:ComputerName -WorkGroupName 'NOTworkgroup' | Should Be $false
                    Test-TargetResource -Name 'localhost' -WorkGroupName 'NOTworkgroup' | Should Be $false
                }
                It 'Should return False if ComputerName is not same as specified' {
                    Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Workgroup';Workgroup='Workgroup';PartOfDomain=$false}}
                    Mock GetComputerDomain {''}
                    Test-TargetResource -Name $NotComputerName -WorkGroupName 'workgroup' | Should Be $false
                    Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Contoso.com';Workgroup='Contoso.com';PartOfDomain=$true}}
                    Mock GetComputerDomain {'contoso.com'}
                    Test-TargetResource -Name $NotComputerName -DomainName 'contoso.com' -Credential $Credential | Should Be $false
                }
                It 'Should return False if Computer is in Workgroup and Domain is specified' {
                    Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Contoso.com';Workgroup='Contoso.com';PartOfDomain=$false}}
                    Mock GetComputerDomain {''}
                    Test-TargetResource -Name $Env:ComputerName -DomainName 'contoso.com' -Credential $Credential | Should Be $false
                    Test-TargetResource -Name 'localhost' -DomainName 'contoso.com' -Credential $Credential | Should Be $false
                }
                It 'Should return False if ComputerName is in Domain and Workgroup is specified' {
                    Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Contoso.com';Workgroup='Contoso.com';PartOfDomain=$true}}
                    Mock GetComputerDomain {'contoso.com'}
                    Test-TargetResource -Name $Env:ComputerName -WorkGroupName 'Contoso' -Credential $Credential -UnjoinCredential $Credential | Should Be $false
                    Test-TargetResource -Name 'localhost' -WorkGroupName 'Contoso' -Credential $Credential -UnjoinCredential $Credential | Should Be $false
                }
                It 'Throws if name is to long' {
                    {Test-TargetResource -Name "ThisNameIsTooLong"} | Should Throw
                }
                It 'Throws if name contains illigal characters' {
                    {Test-TargetResource -Name "ThisIsBad<>"} | Should Throw
                }
                It 'Should not Throw if name is localhost' {
                    {Test-TargetResource -Name "localhost"} | Should Not Throw
                }
                
            }
            Context "$($Global:DSCResourceName)\Get-TargetResource" {
                It 'should not throw' {
                    {Get-TargetResource -Name $env:COMPUTERNAME} | Should Not Throw
                }
                It 'Should return a hashtable containing Name, DomainName, JoinOU, CurrentOU, Credential, UnjoinCredential and WorkGroupName' {
                    $Result = Get-TargetResource -Name $env:COMPUTERNAME
                    $Result.GetType().Fullname | Should Be 'System.Collections.Hashtable'
                    $Result.Keys | Should Be @('Name', 'DomainName', 'JoinOU', 'CurrentOU', 'Credential', 'UnjoinCredential', 'WorkGroupName')
                }
                It 'Throws if name is to long' {
                    {Get-TargetResource -Name "ThisNameIsTooLong"} | Should Throw
                }
                It 'Throws if name contains illigal characters' {
                    {Get-TargetResource -Name "ThisIsBad<>"} | Should Throw
                }
            }
            Context "$($Global:DSCResourceName)\Set-TargetResource" {
                Mock Rename-Computer {}
                Mock Add-Computer {}
                It 'Throws if both DomainName and WorkGroupName are specified' {
                    {Set-TargetResource -Name $Env:ComputerName -DomainName 'contoso.com' -WorkGroupName 'workgroup'} | Should Throw
                    Assert-MockCalled -CommandName Rename-Computer -Exactly 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly 0 -Scope It
                }
                It 'Throws if Domain is specified without Credentials' {
                    {Set-TargetResource -Name $Env:ComputerName -DomainName 'contoso.com'} | Should Throw
                    Assert-MockCalled -CommandName Rename-Computer -Exactly 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly 0 -Scope It
                }
                It 'Changes ComputerName and changes Domain to new Domain' {
                    Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Contoso.com';Workgroup='Contoso.com';PartOfDomain=$true}}
                    Mock GetComputerDomain {'contoso.com'}
                    Set-TargetResource -Name $NotComputerName -DomainName 'adventure-works.com' -Credential $Credential -UnjoinCredential $Credential | Should BeNullOrEmpty
                    Assert-MockCalled -CommandName Rename-Computer -Exactly 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly 1 -Scope It -ParameterFilter {$DomainName -and $NewName}
                    Assert-MockCalled -CommandName Add-Computer -Exactly 0 -Scope It -ParameterFilter {$WorkGroupName}
                }
                It 'Changes ComputerName and changes Domain to new Domain with specified OU' {
                    Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Contoso.com';Workgroup='Contoso.com';PartOfDomain=$true}}
                    Mock GetComputerDomain {'contoso.com'}
                    Set-TargetResource -Name $NotComputerName -DomainName 'adventure-works.com' -JoinOU 'OU=Computers,DC=contoso,DC=com' -Credential $Credential -UnjoinCredential $Credential | Should BeNullOrEmpty
                    Assert-MockCalled -CommandName Rename-Computer -Exactly 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly 1 -Scope It -ParameterFilter {$DomainName -and $NewName}
                    Assert-MockCalled -CommandName Add-Computer -Exactly 0 -Scope It -ParameterFilter {$WorkGroupName}
                }
                It 'Changes ComputerName and changes Domain to Workgroup' {
                    Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Contoso.com';Workgroup='Contoso.com';PartOfDomain=$true}}
                    Mock GetComputerDomain {'contoso.com'}
                    Set-TargetResource -Name $NotComputerName -WorkGroupName 'contoso' -Credential $Credential | Should BeNullOrEmpty
                    Assert-MockCalled -CommandName Rename-Computer -Exactly 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly 1 -Scope It -ParameterFilter {$WorkGroupName -and $NewName -and $Credential}
                    Assert-MockCalled -CommandName Add-Computer -Exactly 0 -Scope It -ParameterFilter {$DomainName -or $UnjoinCredential}
                }
                It 'Changes ComputerName and changes Workgroup to Domain' {
                    Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Contoso';Workgroup='Contoso';PartOfDomain=$false}}
                    Mock GetComputerDomain {''}
                    Set-TargetResource -Name $NotComputerName -DomainName 'Contoso.com' -Credential $Credential | Should BeNullOrEmpty
                    Assert-MockCalled -CommandName Rename-Computer -Exactly 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly 1 -Scope It -ParameterFilter {$DomainName -and $NewName}
                    Assert-MockCalled -CommandName Add-Computer -Exactly 0 -Scope It -ParameterFilter {$WorkGroupName}
                }
                It 'Changes ComputerName and changes Workgroup to Domain with specified OU' {
                    Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Contoso';Workgroup='Contoso';PartOfDomain=$false}}
                    Mock GetComputerDomain {''}
                    Set-TargetResource -Name $NotComputerName -DomainName 'Contoso.com' -JoinOU 'OU=Computers,DC=contoso,DC=com' -Credential $Credential | Should BeNullOrEmpty
                    Assert-MockCalled -CommandName Rename-Computer -Exactly 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly 1 -Scope It -ParameterFilter {$DomainName -and $NewName}
                    Assert-MockCalled -CommandName Add-Computer -Exactly 0 -Scope It -ParameterFilter {$WorkGroupName}
                }
                It 'Changes ComputerName and changes Workgroup to new Workgroup' {
                    Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Contoso';Workgroup='Contoso';PartOfDomain=$false}}
                    Mock GetComputerDomain {''}
                    Set-TargetResource -Name $NotComputerName -WorkGroupName 'adventure-works' | Should BeNullOrEmpty
                    Assert-MockCalled -CommandName Rename-Computer -Exactly 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly 1 -Scope It -ParameterFilter {$WorkGroupName -and $NewName}
                    Assert-MockCalled -CommandName Add-Computer -Exactly 0 -Scope It -ParameterFilter {$DomainName}
                }
                It 'Changes only the Domain to new Domain' {
                    Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Contoso.com';Workgroup='Contoso.com';PartOfDomain=$true}}
                    Mock GetComputerDomain {'contoso.com'}
                    Set-TargetResource -Name $Env:ComputerName -DomainName 'adventure-works.com' -Credential $Credential -UnjoinCredential $Credential | Should BeNullOrEmpty
                    Assert-MockCalled -CommandName Rename-Computer -Exactly 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly 1 -Scope It -ParameterFilter {$DomainName}
                    Assert-MockCalled -CommandName Add-Computer -Exactly 0 -Scope It -ParameterFilter {$NewName}
                    Assert-MockCalled -CommandName Add-Computer -Exactly 0 -Scope It -ParameterFilter {$WorkGroupName}
                }
                It 'Changes only the Domain to new Domain when name is [localhost]' {
                    Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Contoso.com';Workgroup='Contoso.com';PartOfDomain=$true}}
                    Mock GetComputerDomain {'contoso.com'}
                    Set-TargetResource -Name 'localhost' -DomainName 'adventure-works.com' -Credential $Credential -UnjoinCredential $Credential | Should BeNullOrEmpty
                    Assert-MockCalled -CommandName Rename-Computer -Exactly 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly 1 -Scope It -ParameterFilter {$DomainName}
                    Assert-MockCalled -CommandName Add-Computer -Exactly 0 -Scope It -ParameterFilter {$NewName}
                    Assert-MockCalled -CommandName Add-Computer -Exactly 0 -Scope It -ParameterFilter {$WorkGroupName}
                }
                It 'Changes only the Domain to new Domain with specified OU' {
                    Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Contoso.com';Workgroup='Contoso.com';PartOfDomain=$true}}
                    Mock GetComputerDomain {'contoso.com'}
                    Set-TargetResource -Name $Env:ComputerName -DomainName 'adventure-works.com' -JoinOU 'OU=Computers,DC=contoso,DC=com' -Credential $Credential -UnjoinCredential $Credential | Should BeNullOrEmpty
                    Assert-MockCalled -CommandName Rename-Computer -Exactly 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly 1 -Scope It -ParameterFilter {$DomainName}
                    Assert-MockCalled -CommandName Add-Computer -Exactly 0 -Scope It -ParameterFilter {$NewName}
                    Assert-MockCalled -CommandName Add-Computer -Exactly 0 -Scope It -ParameterFilter {$WorkGroupName}
                }
                It 'Changes only the Domain to new Domain with specified OU when Name is [localhost]' {
                    Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Contoso.com';Workgroup='Contoso.com';PartOfDomain=$true}}
                    Mock GetComputerDomain {'contoso.com'}
                    Set-TargetResource -Name 'localhost' -DomainName 'adventure-works.com' -JoinOU 'OU=Computers,DC=contoso,DC=com' -Credential $Credential -UnjoinCredential $Credential | Should BeNullOrEmpty
                    Assert-MockCalled -CommandName Rename-Computer -Exactly 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly 1 -Scope It -ParameterFilter {$DomainName}
                    Assert-MockCalled -CommandName Add-Computer -Exactly 0 -Scope It -ParameterFilter {$NewName}
                    Assert-MockCalled -CommandName Add-Computer -Exactly 0 -Scope It -ParameterFilter {$WorkGroupName}
                }
                It 'Changes only Domain to Workgroup' {
                    Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Contoso.com';Workgroup='Contoso.com';PartOfDomain=$true}}
                    Mock GetComputerDomain {''}
                    Set-TargetResource -Name $Env:ComputerName -WorkGroupName 'Contoso' -UnjoinCredential $Credential | Should BeNullOrEmpty
                    Assert-MockCalled -CommandName Rename-Computer -Exactly 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly 0 -Scope It -ParameterFilter {$NewName}
                    Assert-MockCalled -CommandName Add-Computer -Exactly 1 -Scope It -ParameterFilter {$WorkGroupName}
                    Assert-MockCalled -CommandName Add-Computer -Exactly 0 -Scope It -ParameterFilter {$DomainName}
                }
                It 'Changes only Domain to Workgroup when Name is [localhost]' {
                    Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Contoso.com';Workgroup='Contoso.com';PartOfDomain=$true}}
                    Mock GetComputerDomain {''}
                    Set-TargetResource -Name 'localhost' -WorkGroupName 'Contoso' -UnjoinCredential $Credential | Should BeNullOrEmpty
                    Assert-MockCalled -CommandName Rename-Computer -Exactly 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly 0 -Scope It -ParameterFilter {$NewName}
                    Assert-MockCalled -CommandName Add-Computer -Exactly 1 -Scope It -ParameterFilter {$WorkGroupName}
                    Assert-MockCalled -CommandName Add-Computer -Exactly 0 -Scope It -ParameterFilter {$DomainName}
                }
                It 'Changes only ComputerName in Domain' {
                    Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Contoso.com';Workgroup='Contoso.com';PartOfDomain=$true}}
                    Mock GetComputerDomain {'contoso.com'}
                    Set-TargetResource -Name $NotComputerName -Credential $Credential | Should BeNullOrEmpty
                    Assert-MockCalled -CommandName Rename-Computer -Exactly 1 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly 0 -Scope It
                }
                It 'Changes only ComputerName in Workgroup' {
                    Mock GetComputerDomain {''}
                    Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Contoso';Workgroup='Contoso';PartOfDomain=$false}}
                    Set-TargetResource -Name $NotComputerName | Should BeNullOrEmpty
                    Assert-MockCalled -CommandName Rename-Computer -Exactly 1 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly 0 -Scope It
                }
                It 'Throws if name is to long' {
                    {Set-TargetResource -Name "ThisNameIsTooLong"} | Should Throw
                }
                It 'Throws if name contains illigal characters' {
                    {Set-TargetResource -Name "ThisIsBad<>"} | Should Throw
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
