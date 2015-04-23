$Module = "$PSScriptRoot\..\DSCResources\MSFT_xComputer\MSFT_xComputer.psm1"
Remove-Module -Name MSFT_xComputer -Force -ErrorAction SilentlyContinue
Import-Module -Name $Module -Force -ErrorAction Stop

InModuleScope MSFT_xComputer {
    
    Describe 'xComputermanagement' {
        
        #$VerbosePreference = 'Continue'

        $SecPassword = ConvertTo-SecureString -String 'password' -AsPlainText -Force
        $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'USER',$SecPassword
        $NotComputerName  = if($env:COMPUTERNAME -ne 'othername'){'othername'}else{'name'}
    
        Context Test-TargetResource {
            It 'Throws if both DomainName and WorkGroupName are specified' {
                {Test-TargetResource -Name $Env:ComputerName -DomainName 'contoso.com' -WorkGroupName 'workgroup'} | Should Throw
            }
            It 'Throws if Domain is specified without Credentials' {
                {Test-TargetResource -Name $Env:ComputerName -DomainName 'contoso.com'} | Should Throw
            }
            It 'Should return True if Domain name is same as specified' {
                Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Contoso.com';Workgroup='Contoso.com';PartOfDomain=$true}}
                Test-TargetResource -Name $Env:ComputerName -DomainName 'Contoso.com' -Credential $Credential | Should Be $true
            }
            It 'Should return True if Workgroup name is same as specified' {
                Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Workgroup';Workgroup='Workgroup';PartOfDomain=$false}}
                Test-TargetResource -Name $Env:ComputerName -WorkGroupName 'workgroup' -Verbose | Should Be $true
            }
            It 'Should return True if ComputerName and Domain name is same as specified' {
                Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Contoso.com';Workgroup='Contoso.com';PartOfDomain=$true}}
                Test-TargetResource -Name $Env:ComputerName -DomainName 'contoso.com' -Credential $Credential | Should Be $true
            }
            It 'Should return True if ComputerName and Workgroup is same as specified' {
                Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Workgroup';Workgroup='Workgroup';PartOfDomain=$false}}
                Test-TargetResource -Name $Env:ComputerName -WorkGroupName 'workgroup' | Should Be $true
            }
            It 'Should return True if current Domain flat name (Netbios) is specified' {
                Mock Get-WMIObject {[PSCustomObject]@{Domain = 'contoso.com';Workgroup='contoso.com';PartOfDomain=$true}}
                Mock Get-WMIObject {[PSCustomObject]@{DomainName = 'ContosoLtd'}} -ParameterFilter {$Class -eq 'Win32_NTDomain'}
                Test-TargetResource -Name $Env:ComputerName -DomainName 'contosoltd' -Credential $Credential | Should Be $true
            }
            It 'Should return False if Domain name is not same as specified' {
                Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Contoso.com';Workgroup='Contoso.com';PartOfDomain=$true}}
                Test-TargetResource -Name $Env:ComputerName -DomainName 'adventure-works.com' -Credential $Credential  | Should Be $false
            }
            It 'Should return False if Workgroup name is not same as specified' {
                Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Workgroup';Workgroup='Workgroup';PartOfDomain=$false}}
                Test-TargetResource -Name $Env:ComputerName -WorkGroupName 'NOTworkgroup' | Should Be $false
            }
            It 'Should return False if ComputerName is not same as specified' {
                Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Workgroup';Workgroup='Workgroup';PartOfDomain=$false}}
                Test-TargetResource -Name $NotComputerName -WorkGroupName 'workgroup' | Should Be $false
                Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Contoso.com';Workgroup='Contoso.com';PartOfDomain=$true}}
                Test-TargetResource -Name $NotComputerName -DomainName 'contoso.com' -Credential $Credential | Should Be $false
            }
            It 'Should return False if Computer is in Workgroup and Domain is specified' {
                Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Contoso';Workgroup='Contoso';PartOfDomain=$false}}
                Test-TargetResource -Name $Env:ComputerName -DomainName 'contoso.com' -Credential $Credential | Should Be $false
            }
            It 'Should return False if ComputerName is in Domain and Workgroup is specified' {
                Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Contoso.com';Workgroup='Contoso.com';PartOfDomain=$true}}
                Test-TargetResource -Name $Env:ComputerName -WorkGroupName 'Contoso' -Credential $Credential | Should Be $false
            }
        }
        Context Get-TargetResource {
            It 'should not throw' {
                {Get-TargetResource -Name $env:COMPUTERNAME} | Should Not Throw
            }
            It 'Should return a hashtable containing Name,DomainName, Credential, UnjoinCredential and WorkGroupName' {
                $Result = Get-TargetResource -Name $env:COMPUTERNAME
                $Result.GetType().Fullname | Should Be 'System.Collections.Hashtable'
                $Result.Keys | Should Be @('Name','DomainName','Credential','UnjoinCredential','WorkGroupName')
            }
        }
        Context Set-TargetResource {
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
                Set-TargetResource -Name $NotComputerName -DomainName 'adventure-works.com' -Credential $Credential -UnjoinCredential $Credential | Should BeNullOrEmpty
                Assert-MockCalled -CommandName Rename-Computer -Exactly 0 -Scope It
                Assert-MockCalled -CommandName Add-Computer -Exactly 1 -Scope It -ParameterFilter {$DomainName -and $NewName}
                Assert-MockCalled -CommandName Add-Computer -Exactly 0 -Scope It -ParameterFilter {$WorkGroupName}
            }
            It 'Changes ComputerName and changes Domain to Workgroup' {
                Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Contoso.com';Workgroup='Contoso.com';PartOfDomain=$true}}
                Set-TargetResource -Name $NotComputerName -WorkGroupName 'contoso' -UnjoinCredential $Credential | Should BeNullOrEmpty
                Assert-MockCalled -CommandName Rename-Computer -Exactly 0 -Scope It
                Assert-MockCalled -CommandName Add-Computer -Exactly 1 -Scope It -ParameterFilter {$WorkGroupName -and $NewName}
                Assert-MockCalled -CommandName Add-Computer -Exactly 0 -Scope It -ParameterFilter {$DomainName}
            }
            It 'Changes ComputerName and changes Workgroup to Domain' {
                Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Contoso';Workgroup='Contoso';PartOfDomain=$false}}
                Set-TargetResource -Name $NotComputerName -DomainName 'Contoso.com' -Credential $Credential | Should BeNullOrEmpty
                Assert-MockCalled -CommandName Rename-Computer -Exactly 0 -Scope It
                Assert-MockCalled -CommandName Add-Computer -Exactly 1 -Scope It -ParameterFilter {$DomainName -and $NewName}
                Assert-MockCalled -CommandName Add-Computer -Exactly 0 -Scope It -ParameterFilter {$WorkGroupName}
            }
            It 'Changes ComputerName and changes Workgroup to new Workgroup' {
                Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Contoso';Workgroup='Contoso';PartOfDomain=$false}}
                Set-TargetResource -Name $NotComputerName -WorkGroupName 'adventure-works' | Should BeNullOrEmpty
                Assert-MockCalled -CommandName Rename-Computer -Exactly 0 -Scope It
                Assert-MockCalled -CommandName Add-Computer -Exactly 1 -Scope It -ParameterFilter {$WorkGroupName -and $NewName}
                Assert-MockCalled -CommandName Add-Computer -Exactly 0 -Scope It -ParameterFilter {$DomainName}
            }
            It 'Changes only the Domain to new Domain' {
                Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Contoso.com';Workgroup='Contoso.com';PartOfDomain=$true}}
                Set-TargetResource -Name $Env:ComputerName -DomainName 'adventure-works.com' -Credential $Credential -UnjoinCredential $Credential | Should BeNullOrEmpty
                Assert-MockCalled -CommandName Rename-Computer -Exactly 0 -Scope It
                Assert-MockCalled -CommandName Add-Computer -Exactly 1 -Scope It -ParameterFilter {$DomainName}
                Assert-MockCalled -CommandName Add-Computer -Exactly 0 -Scope It -ParameterFilter {$NewName}
                Assert-MockCalled -CommandName Add-Computer -Exactly 0 -Scope It -ParameterFilter {$WorkGroupName}
            }
            It 'Changes only Domain to Workgroup' {
                Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Contoso.com';Workgroup='Contoso.com';PartOfDomain=$true}}
                Set-TargetResource -Name $Env:ComputerName -WorkGroupName 'Contoso' -UnjoinCredential $Credential | Should BeNullOrEmpty
                Assert-MockCalled -CommandName Rename-Computer -Exactly 0 -Scope It
                Assert-MockCalled -CommandName Add-Computer -Exactly 0 -Scope It -ParameterFilter {$NewName}
                Assert-MockCalled -CommandName Add-Computer -Exactly 1 -Scope It -ParameterFilter {$WorkGroupName}
                Assert-MockCalled -CommandName Add-Computer -Exactly 0 -Scope It -ParameterFilter {$DomainName}
            }
            It 'Changes only ComputerName in Domain' {
                Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Contoso.com';Workgroup='Contoso.com';PartOfDomain=$true}}
                Set-TargetResource -Name $NotComputerName -Credential $Credential | Should BeNullOrEmpty
                Assert-MockCalled -CommandName Rename-Computer -Exactly 1 -Scope It
                Assert-MockCalled -CommandName Add-Computer -Exactly 0 -Scope It
            }
            It 'Changes only ComputerName in Workgroup' {
                Mock Get-WMIObject {[PSCustomObject]@{Domain = 'Contoso';Workgroup='Contoso';PartOfDomain=$false}}
                Set-TargetResource -Name $NotComputerName | Should BeNullOrEmpty
                Assert-MockCalled -CommandName Rename-Computer -Exactly 1 -Scope It
                Assert-MockCalled -CommandName Add-Computer -Exactly 0 -Scope It
            }
        }
    }
}

