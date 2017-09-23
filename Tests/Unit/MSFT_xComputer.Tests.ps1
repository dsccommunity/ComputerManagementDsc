$script:DSCModuleName = 'xComputerManagement'
$script:DSCResourceName = 'MSFT_xComputer'

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
        $script:DSCResourceName = 'MSFT_xComputer'

        Describe $script:DSCResourceName {
            # A real password isn't needed here - use this next line to avoid triggering PSSA rule
            $securePassword = New-Object -Type SecureString
            $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'USER', $securePassword
            $notComputerName = if ($env:COMPUTERNAME -ne 'othername')
            {
                'othername'
            }
            else
            {
                'name'
            }

            Context "$($script:DSCResourceName)\Test-TargetResource" {
                Mock -CommandName Get-WMIObject -MockWith {
                    [PSCustomObject] @{
                        DomainName = 'ContosoLtd'
                    }
                } -ParameterFilter {
                    $Class -eq 'Win32_NTDomain'
                }

                It 'Throws if both DomainName and WorkGroupName are specified' {
                    $errorRecord = Get-InvalidOperationRecord `
                        -Message ($LocalizedData.DomainNameAndWorkgroupNameError)

                    {
                        Test-TargetResource `
                            -Name $env:COMPUTERNAME `
                            -DomainName 'contoso.com' `
                            -WorkGroupName 'workgroup' `
                            -Verbose
                    } | Should Throw $errorRecord
                }

                It 'Throws if Domain is specified without Credentials' {
                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($LocalizedData.CredentialsNotSpecifiedError) `
                        -ArgumentName 'Credentials'

                    {
                        Test-TargetResource `
                            -Name $env:COMPUTERNAME `
                            -DomainName 'contoso.com' `
                            -Verbose
                    } | Should Throw $errorRecord
                }

                It 'Should return True if Domain name is same as specified' {
                    Mock -CommandName Get-WMIObject -MockWith {
                        [PSCustomObject] @{
                            Domain       = 'Contoso.com';
                            Workgroup    = 'Contoso.com';
                            PartOfDomain = $true
                        }
                    }

                    Mock -CommandName Get-ComputerDomain -MockWith {
                        'contoso.com'
                    }

                    Test-TargetResource `
                        -Name $env:COMPUTERNAME `
                        -DomainName 'Contoso.com' `
                        -Credential $credential `
                        -Verbose | Should Be $true
                }

                It 'Should return True if Workgroup name is same as specified' {
                    Mock -CommandName Get-WMIObject -MockWith {
                        [PSCustomObject] @{
                            Domain       = 'Workgroup';
                            Workgroup    = 'Workgroup';
                            PartOfDomain = $false
                        }
                    }

                    Mock -CommandName Get-ComputerDomain -MockWith {
                        ''
                    }

                    Test-TargetResource `
                        -Name $env:COMPUTERNAME `
                        -WorkGroupName 'workgroup' `
                        -Verbose | Should Be $true
                }

                It 'Should return True if ComputerName and Domain name is same as specified' {
                    Mock -CommandName Get-WMIObject -MockWith {
                        [PSCustomObject] @{
                            Domain       = 'Contoso.com';
                            Workgroup    = 'Contoso.com';
                            PartOfDomain = $true
                        }
                    }

                    Mock -CommandName Get-ComputerDomain -MockWith {
                        'contoso.com'
                    }

                    Test-TargetResource `
                        -Name $env:COMPUTERNAME `
                        -DomainName 'contoso.com' `
                        -Credential $credential `
                        -Verbose | Should Be $true

                    Test-TargetResource `
                        -Name 'localhost' `
                        -DomainName 'contoso.com' `
                        -Credential $credential `
                        -Verbose | Should Be $true
                }

                It 'Should return True if ComputerName and Workgroup is same as specified' {
                    Mock -CommandName Get-WMIObject -MockWith {
                        [PSCustomObject] @{
                            Domain       = 'Workgroup';
                            Workgroup    = 'Workgroup';
                            PartOfDomain = $false
                        }
                    }

                    Mock -CommandName Get-ComputerDomain -MockWith {
                        ''
                    }

                    Test-TargetResource `
                        -Name $env:COMPUTERNAME `
                        -WorkGroupName 'workgroup' `
                        -Verbose | Should Be $true

                    Test-TargetResource `
                        -Name 'localhost' `
                        -WorkGroupName 'workgroup' `
                        -Verbose | Should Be $true
                }

                It 'Should return True if ComputerName is same and no Domain or Workgroup specified' {
                    Mock -CommandName Get-WmiObject -MockWith {
                        [PSCustomObject] @{
                            Domain       = 'Workgroup';
                            Workgroup    = 'Workgroup';
                            PartOfDomain = $false
                        }
                    }

                    Mock -CommandName Get-ComputerDomain -MockWith {
                        ''
                    }

                    Test-TargetResource `
                        -Name $env:COMPUTERNAME `
                        -Verbose | Should Be $true

                    Test-TargetResource `
                        -Name 'localhost' `
                        -Verbose | Should Be $true

                    Mock -CommandName Get-WmiObject {
                        [PSCustomObject] @{
                            Domain       = 'Contoso.com';
                            Workgroup    = 'Contoso.com';
                            PartOfDomain = $true
                        }
                    }

                    Mock -CommandName Get-ComputerDomain -MockWith {
                        'contoso.com'
                    }

                    Test-TargetResource `
                        -Name $env:COMPUTERNAME `
                        -Verbose | Should Be $true

                    Test-TargetResource `
                        -Name 'localhost' `
                        -Verbose | Should Be $true
                }

                It 'Should return False if ComputerName is not same and no Domain or Workgroup specified' {
                    Mock -CommandName Get-WmiObject -MockWith {
                        [PSCustomObject] @{
                            Domain       = 'Workgroup';
                            Workgroup    = 'Workgroup';
                            PartOfDomain = $false
                        }
                    }

                    Mock -CommandName Get-ComputerDomain -MockWith {
                        ''
                    }

                    Test-TargetResource `
                        -Name $notComputerName `
                        -Verbose | Should Be $false

                    Mock -CommandName Get-WmiObject -MockWith {
                        [PSCustomObject] @{
                            Domain       = 'Contoso.com';
                            Workgroup    = 'Contoso.com';
                            PartOfDomain = $true
                        }
                    }

                    Mock -CommandName Get-ComputerDomain -MockWith {
                        'contoso.com'
                    }

                    Test-TargetResource `
                        -Name $notComputerName `
                        -Verbose | Should Be $false
                }

                It 'Should return False if Domain name is not same as specified' {
                    Mock -CommandName Get-WMIObject {
                        [PSCustomObject] @{
                            Domain       = 'Contoso.com';
                            Workgroup    = 'Contoso.com';
                            PartOfDomain = $true
                        }
                    }

                    Mock -CommandName Get-ComputerDomain -MockWith {
                        'contoso.com'
                    }

                    Test-TargetResource `
                        -Name $env:COMPUTERNAME `
                        -DomainName 'adventure-works.com' `
                        -Credential $credential `
                        -Verbose | Should Be $false

                    Test-TargetResource `
                        -Name 'localhost' `
                        -DomainName 'adventure-works.com' `
                        -Credential $credential `
                        -Verbose | Should Be $false
                }

                It 'Should return False if Workgroup name is not same as specified' {
                    Mock -CommandName Get-WMIObject -MockWith {
                        [PSCustomObject] @{
                            Domain       = 'Workgroup';
                            Workgroup    = 'Workgroup';
                            PartOfDomain = $false
                        }
                    }

                    Mock -CommandName Get-ComputerDomain -MockWith {
                        ''
                    }

                    Test-TargetResource `
                        -Name $env:COMPUTERNAME `
                        -WorkGroupName 'NOTworkgroup' `
                        -Verbose | Should Be $false

                    Test-TargetResource `
                        -Name 'localhost' `
                        -WorkGroupName 'NOTworkgroup' `
                        -Verbose | Should Be $false
                }

                It 'Should return False if ComputerName is not same as specified' {
                    Mock -CommandName Get-WMIObject -MockWith {
                        [PSCustomObject] @{
                            Domain       = 'Workgroup';
                            Workgroup    = 'Workgroup';
                            PartOfDomain = $false
                        }
                    }

                    Mock -CommandName Get-ComputerDomain -MockWith {
                        ''
                    }

                    Test-TargetResource `
                        -Name $notComputerName `
                        -WorkGroupName 'workgroup' `
                        -Verbose | Should Be $false

                    Mock -CommandName Get-WMIObject -MockWith {
                        [PSCustomObject] @{
                            Domain       = 'Contoso.com';
                            Workgroup    = 'Contoso.com';
                            PartOfDomain = $true
                        }
                    }

                    Mock -CommandName Get-ComputerDomain -MockWith {
                        'contoso.com'
                    }

                    Test-TargetResource `
                        -Name $notComputerName `
                        -DomainName 'contoso.com' `
                        -Credential $credential `
                        -Verbose | Should Be $false
                }

                It 'Should return False if Computer is in Workgroup and Domain is specified' {
                    Mock -CommandName Get-WMIObject {
                        [PSCustomObject] @{
                            Domain       = 'Contoso.com';
                            Workgroup    = 'Contoso.com';
                            PartOfDomain = $false
                        }
                    }

                    Mock -CommandName Get-ComputerDomain -MockWith {
                        ''
                    }

                    Test-TargetResource `
                        -Name $env:COMPUTERNAME `
                        -DomainName 'contoso.com' `
                        -Credential $credential `
                        -Verbose | Should Be $false

                    Test-TargetResource `
                        -Name 'localhost' `
                        -DomainName 'contoso.com' `
                        -Credential $credential `
                        -Verbose | Should Be $false
                }

                It 'Should return False if ComputerName is in Domain and Workgroup is specified' {
                    Mock -CommandName Get-WMIObject {
                        [PSCustomObject] @{
                            Domain       = 'Contoso.com';
                            Workgroup    = 'Contoso.com';
                            PartOfDomain = $true
                        }
                    }

                    Mock -CommandName Get-ComputerDomain -MockWith {
                        'contoso.com'
                    }

                    Test-TargetResource `
                        -Name $env:COMPUTERNAME `
                        -WorkGroupName 'Contoso' `
                        -Credential $credential `
                        -UnjoinCredential $credential `
                        -Verbose | Should Be $false

                    Test-TargetResource `
                        -Name 'localhost' `
                        -WorkGroupName 'Contoso' `
                        -Credential $credential `
                        -UnjoinCredential $credential `
                        -Verbose | Should Be $false
                }

                It 'Throws if name is to long' {
                    {
                        Test-TargetResource `
                            -Name 'ThisNameIsTooLong' `
                            -Verbose
                    } | Should Throw
                }

                It 'Throws if name contains illegal characters' {
                    {
                        Test-TargetResource `
                            -Name 'ThisIsBad<>' `
                            -Verbose
                    } | Should Throw
                }

                It 'Should not Throw if name is localhost' {
                    {
                        Test-TargetResource `
                            -Name 'localhost' `
                            -Verbose
                    } | Should Not Throw
                }

                It 'Should return true if description is same as specified' {
                    Mock -CommandName Get-CimInstance -MockWith {
                        [PSCustomObject] @{
                            Description = 'This is my computer'
                        }
                    }

                    Test-TargetResource `
                        -Name $env:COMPUTERNAME `
                        -Description 'This is my computer' `
                        -Verbose | Should Be $true

                    Test-TargetResource `
                        -Name 'localhost' `
                        -Description 'This is my computer' `
                        -Verbose | Should Be $true
                }

                It 'Should return false if description is same as specified' {
                    Mock -CommandName Get-CimInstance -MockWith {
                        [PSCustomObject] @{
                            Description = 'This is not my computer'
                        }
                    }

                    Test-TargetResource `
                        -Name $env:COMPUTERNAME `
                        -Description 'This is my computer' `
                        -Verbose | Should Be $false

                    Test-TargetResource `
                        -Name 'localhost' `
                        -Description 'This is my computer' `
                        -Verbose | Should Be $false
                }
            }

            Context "$($script:DSCResourceName)\Get-TargetResource" {
                It 'should not throw' {
                    {
                        Get-TargetResource `
                            -Name $env:COMPUTERNAME `
                            -Verbose
                    } | Should Not Throw
                }

                It 'Should return a hashtable containing Name, DomainName, JoinOU, CurrentOU, Credential, UnjoinCredential, WorkGroupName and Description' {
                    $Result = Get-TargetResource `
                        -Name $env:COMPUTERNAME `
                        -Verbose

                    $Result.GetType().Fullname | Should Be 'System.Collections.Hashtable'
                    $Result.Keys | Sort-Object | Should Be @('Credential', 'CurrentOU', 'Description', 'DomainName', 'JoinOU', 'Name', 'UnjoinCredential', 'WorkGroupName')
                }

                It 'Throws if name is to long' {
                    {
                        Get-TargetResource `
                            -Name 'ThisNameIsTooLong' `
                            -Verbose
                    } | Should Throw
                }

                It 'Throws if name contains illegal characters' {
                    {
                        Get-TargetResource `
                            -Name 'ThisIsBad<>' `
                            -Verbose
                    } | Should Throw
                }
            }

            Context "$($script:DSCResourceName)\Set-TargetResource" {
                Mock -CommandName Rename-Computer
                Mock -CommandName Add-Computer
                Mock -CommandName Set-CimInstance

                It 'Throws if both DomainName and WorkGroupName are specified' {
                    $errorRecord = Get-InvalidOperationRecord `
                        -Message ($LocalizedData.DomainNameAndWorkgroupNameError)

                    {
                        Set-TargetResource `
                            -Name $env:COMPUTERNAME `
                            -DomainName 'contoso.com' `
                            -WorkGroupName 'workgroup' `
                            -Verbose
                    } | Should Throw $errorRecord

                    Assert-MockCalled -CommandName Rename-Computer -Exactly -Times 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It
                }

                It 'Throws if Domain is specified without Credentials' {
                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($LocalizedData.CredentialsNotSpecifiedError) `
                        -ArgumentName 'Credentials'

                    {
                        Set-TargetResource `
                            -Name $env:COMPUTERNAME `
                            -DomainName 'contoso.com' `
                            -Verbose
                    } | Should Throw $errorRecord

                    Assert-MockCalled -CommandName Rename-Computer -Exactly -Times 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It
                }

                It 'Changes ComputerName and changes Domain to new Domain' {
                    Mock -CommandName Get-WMIObject -MockWith {
                        [PSCustomObject] @{
                            Domain       = 'Contoso.com';
                            Workgroup    = 'Contoso.com';
                            PartOfDomain = $true
                        }
                    }

                    Mock -CommandName Get-ComputerDomain -MockWith {
                        'contoso.com'
                    }

                    Set-TargetResource `
                        -Name $notComputerName `
                        -DomainName 'adventure-works.com' `
                        -Credential $credential `
                        -UnjoinCredential $credential `
                        -Verbose | Should BeNullOrEmpty

                    Assert-MockCalled -CommandName Rename-Computer -Exactly -Times 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $DomainName -and $NewName }
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $WorkGroupName }
                }

                It 'Changes ComputerName and changes Domain to new Domain with specified OU' {
                    Mock -CommandName Get-WMIObject -MockWith {
                        [PSCustomObject] @{
                            Domain       = 'Contoso.com';
                            Workgroup    = 'Contoso.com';
                            PartOfDomain = $true
                        }
                    }

                    Mock -CommandName Get-ComputerDomain -MockWith {
                        'contoso.com'
                    }

                    Set-TargetResource `
                        -Name $notComputerName `
                        -DomainName 'adventure-works.com' `
                        -JoinOU 'OU=Computers,DC=contoso,DC=com' `
                        -Credential $credential `
                        -UnjoinCredential $credential `
                        -Verbose | Should BeNullOrEmpty

                    Assert-MockCalled -CommandName Rename-Computer -Exactly -Times 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $DomainName -and $NewName }
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $WorkGroupName }
                }

                It 'Changes ComputerName and changes Domain to Workgroup' {
                    Mock -CommandName Get-WMIObject -MockWith {
                        [PSCustomObject] @{
                            Domain       = 'Contoso.com';
                            Workgroup    = 'Contoso.com';
                            PartOfDomain = $true
                        }
                    }

                    Mock -CommandName Get-ComputerDomain -MockWith {
                        'contoso.com'
                    }

                    Set-TargetResource `
                        -Name $notComputerName `
                        -WorkGroupName 'contoso' `
                        -Credential $credential `
                        -Verbose | Should BeNullOrEmpty

                    Assert-MockCalled -CommandName Rename-Computer -Exactly -Times 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $WorkGroupName -and $NewName -and $credential }
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $DomainName -or $UnjoinCredential }
                }

                It 'Changes ComputerName and changes Workgroup to Domain' {
                    Mock -CommandName Get-WMIObject -MockWith {
                        [PSCustomObject] @{
                            Domain       = 'Contoso';
                            Workgroup    = 'Contoso';
                            PartOfDomain = $false
                        }
                    }

                    Mock -CommandName Get-ComputerDomain -MockWith {
                        ''
                    }

                    Set-TargetResource `
                        -Name $notComputerName `
                        -DomainName 'Contoso.com' `
                        -Credential $credential `
                        -Verbose | Should BeNullOrEmpty

                    Assert-MockCalled -CommandName Rename-Computer -Exactly -Times 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $DomainName -and $NewName }
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $WorkGroupName }
                }

                It 'Changes ComputerName and changes Workgroup to Domain with specified OU' {
                    Mock -CommandName Get-WMIObject -MockWith {
                        [PSCustomObject] @{
                            Domain       = 'Contoso';
                            Workgroup    = 'Contoso';
                            PartOfDomain = $false
                        }
                    }

                    Mock -CommandName Get-ComputerDomain -MockWith {
                        ''
                    }

                    Set-TargetResource `
                        -Name $notComputerName `
                        -DomainName 'Contoso.com' `
                        -JoinOU 'OU=Computers,DC=contoso,DC=com' `
                        -Credential $credential `
                        -Verbose | Should BeNullOrEmpty

                    Assert-MockCalled -CommandName Rename-Computer -Exactly -Times 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $DomainName -and $NewName }
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $WorkGroupName }
                }

                It 'Changes ComputerName and changes Workgroup to new Workgroup' {
                    Mock -CommandName Get-WMIObject -MockWith {
                        [PSCustomObject] @{
                            Domain       = 'Contoso';
                            Workgroup    = 'Contoso';
                            PartOfDomain = $false
                        }
                    }

                    Mock -CommandName Get-ComputerDomain -MockWith {
                        ''
                    }

                    Set-TargetResource `
                        -Name $notComputerName `
                        -WorkGroupName 'adventure-works' `
                        -Verbose | Should BeNullOrEmpty

                    Assert-MockCalled -CommandName Rename-Computer -Exactly -Times 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $WorkGroupName -and $NewName }
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $DomainName }
                }

                It 'Changes only the Domain to new Domain' {
                    Mock -CommandName Get-WMIObject -MockWith {
                        [PSCustomObject] @{
                            Domain       = 'Contoso.com';
                            Workgroup    = 'Contoso.com';
                            PartOfDomain = $true
                        }
                    }

                    Mock -CommandName Get-ComputerDomain -MockWith {
                        'contoso.com'
                    }

                    Set-TargetResource `
                        -Name $env:COMPUTERNAME `
                        -DomainName 'adventure-works.com' `
                        -Credential $credential `
                        -UnjoinCredential $credential `
                        -Verbose | Should BeNullOrEmpty

                    Assert-MockCalled -CommandName Rename-Computer -Exactly -Times 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $DomainName }
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $NewName }
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $WorkGroupName }
                }

                It 'Changes only the Domain to new Domain when name is [localhost]' {
                    Mock -CommandName Get-WMIObject -MockWith {
                        [PSCustomObject] @{
                            Domain       = 'Contoso.com';
                            Workgroup    = 'Contoso.com';
                            PartOfDomain = $true
                        }
                    }

                    Mock -CommandName Get-ComputerDomain -MockWith {
                        'contoso.com'
                    }

                    Set-TargetResource `
                        -Name 'localhost' `
                        -DomainName 'adventure-works.com' `
                        -Credential $credential `
                        -UnjoinCredential $credential `
                        -Verbose | Should BeNullOrEmpty

                    Assert-MockCalled -CommandName Rename-Computer -Exactly -Times 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $DomainName }
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $NewName }
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $WorkGroupName }
                }

                It 'Changes only the Domain to new Domain with specified OU' {
                    Mock -CommandName Get-WMIObject -MockWith {
                        [PSCustomObject] @{
                            Domain       = 'Contoso.com';
                            Workgroup    = 'Contoso.com';
                            PartOfDomain = $true
                        }
                    }

                    Mock -CommandName Get-ComputerDomain -MockWith {
                        'contoso.com'
                    }

                    Set-TargetResource `
                        -Name $env:COMPUTERNAME `
                        -DomainName 'adventure-works.com' `
                        -JoinOU 'OU=Computers,DC=contoso,DC=com' `
                        -Credential $credential `
                        -UnjoinCredential $credential `
                        -Verbose | Should BeNullOrEmpty

                    Assert-MockCalled -CommandName Rename-Computer -Exactly -Times 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $DomainName }
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $NewName }
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $WorkGroupName }
                }

                It 'Changes only the Domain to new Domain with specified OU when Name is [localhost]' {
                    Mock -CommandName Get-WMIObject -MockWith {
                        [PSCustomObject] @{
                            Domain       = 'Contoso.com';
                            Workgroup    = 'Contoso.com';
                            PartOfDomain = $true
                        }
                    }

                    Mock -CommandName Get-ComputerDomain -MockWith {
                        'contoso.com'
                    }

                    Set-TargetResource `
                        -Name 'localhost' `
                        -DomainName 'adventure-works.com' `
                        -JoinOU 'OU=Computers,DC=contoso,DC=com' `
                        -Credential $credential `
                        -UnjoinCredential $credential `
                        -Verbose | Should BeNullOrEmpty

                    Assert-MockCalled -CommandName Rename-Computer -Exactly -Times 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $DomainName }
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $NewName }
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $WorkGroupName }
                }

                It 'Changes only Domain to Workgroup' {
                    Mock -CommandName Get-WMIObject -MockWith {
                        [PSCustomObject] @{
                            Domain       = 'Contoso.com';
                            Workgroup    = 'Contoso.com';
                            PartOfDomain = $true
                        }
                    }

                    Mock -CommandName Get-ComputerDomain -MockWith {
                        ''
                    }

                    Set-TargetResource `
                        -Name $env:COMPUTERNAME `
                        -WorkGroupName 'Contoso' `
                        -UnjoinCredential $credential `
                        -Verbose | Should BeNullOrEmpty

                    Assert-MockCalled -CommandName Rename-Computer -Exactly -Times 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $NewName }
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $WorkGroupName }
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $DomainName }
                }

                It 'Changes only Domain to Workgroup when Name is [localhost]' {
                    Mock -CommandName Get-WMIObject -MockWith {
                        [PSCustomObject] @{
                            Domain       = 'Contoso.com';
                            Workgroup    = 'Contoso.com';
                            PartOfDomain = $true
                        }
                    }

                    Mock -CommandName Get-ComputerDomain -MockWith {
                        ''
                    }

                    Set-TargetResource `
                        -Name 'localhost' `
                        -WorkGroupName 'Contoso' `
                        -UnjoinCredential $credential `
                        -Verbose | Should BeNullOrEmpty

                    Assert-MockCalled -CommandName Rename-Computer -Exactly -Times 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $NewName }
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $WorkGroupName }
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $DomainName }
                }

                It 'Changes only ComputerName in Domain' {
                    Mock -CommandName Get-WMIObject -MockWith {
                        [PSCustomObject] @{
                            Domain       = 'Contoso.com';
                            Workgroup    = 'Contoso.com';
                            PartOfDomain = $true
                        }
                    }

                    Mock -CommandName Get-ComputerDomain -MockWith {
                        'contoso.com'
                    }

                    Set-TargetResource `
                        -Name $notComputerName `
                        -Credential $credential `
                        -Verbose | Should BeNullOrEmpty

                    Assert-MockCalled -CommandName Rename-Computer -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It
                }

                It 'Changes only ComputerName in Workgroup' {
                    Mock -CommandName Get-ComputerDomain -MockWith {
                        ''
                    }

                    Mock -CommandName Get-WMIObject -MockWith {
                        [PSCustomObject] @{
                            Domain       = 'Contoso';
                            Workgroup    = 'Contoso';
                            PartOfDomain = $false
                        }
                    }

                    Set-TargetResource `
                        -Name $notComputerName `
                        -Verbose | Should BeNullOrEmpty

                    Assert-MockCalled -CommandName Rename-Computer -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It
                }

                It 'Throws if name is to long' {
                    {
                        Set-TargetResource `
                            -Name 'ThisNameIsTooLong' `
                            -Verbose
                    } | Should Throw
                }

                It 'Throws if name contains illegal characters' {
                    {
                        Set-TargetResource `
                            -Name 'ThisIsBad<>' `
                            -Verbose
                    } | Should Throw
                }

                It 'Changes computer description in a workgroup' {
                    Mock -CommandName Get-ComputerDomain -MockWith {
                        ''
                    }

                    Mock -CommandName Get-WMIObject {
                        [PSCustomObject] @{
                            Domain       = 'Contoso';
                            Workgroup    = 'Contoso';
                            PartOfDomain = $false
                        }
                    }

                    Set-TargetResource `
                        -Name $env:COMPUTERNAME `
                        -Description 'This is my computer' `
                        -DomainName '' `
                        -Verbose | Should BeNullOrEmpty

                    Assert-MockCalled -CommandName Set-CimInstance -Exactly -Times 1 -Scope It
                }

                It 'Changes computer description in a domain' {
                    Mock -CommandName Get-WMIObject -MockWith {
                        [PSCustomObject] @{
                            Domain       = 'Contoso.com';
                            Workgroup    = 'Contoso.com';
                            PartOfDomain = $true
                        }
                    }

                    Mock -CommandName Get-ComputerDomain -MockWith {
                        'contoso.com'
                    }

                    Set-TargetResource `
                        -Name $env:COMPUTERNAME `
                        -Verbose | Should BeNullOrEmpty

                    Set-TargetResource `
                        -Name $env:COMPUTERNAME `
                        -DomainName 'Contoso.com' `
                        -Credential $credential `
                        -UnjoinCredential $credential `
                        -Description 'This is my computer' `
                        -Verbose | Should BeNullOrEmpty

                    Assert-MockCalled -CommandName Set-CimInstance -Exactly -Times 1 -Scope It
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
