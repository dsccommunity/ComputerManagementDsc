$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'DSC_Computer'

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
        Describe 'DSC_Computer' {
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

            Context 'DSC_Computer\Test-TargetResource' {
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
                    } | Should -Throw $errorRecord
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
                    } | Should -Throw $errorRecord
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
                        -Verbose | Should -BeTrue
                }

                It 'Should return True if Workgroup name is same as specified' {
                    Mock -CommandName Get-CimInstance -MockWith {
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
                        -Verbose | Should -BeTrue
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
                        -Verbose | Should -BeTrue

                    Test-TargetResource `
                        -Name 'localhost' `
                        -DomainName 'contoso.com' `
                        -Credential $credential `
                        -Verbose | Should -BeTrue
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
                        -Verbose | Should -BeTrue

                    Test-TargetResource `
                        -Name 'localhost' `
                        -WorkGroupName 'workgroup' `
                        -Verbose | Should -BeTrue
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
                        -Verbose | Should -BeTrue

                    Test-TargetResource `
                        -Name 'localhost' `
                        -Verbose | Should -BeTrue

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
                        -Verbose | Should -BeTrue

                    Test-TargetResource `
                        -Name 'localhost' `
                        -Verbose | Should -BeTrue
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
                        -Verbose | Should -BeFalse

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
                        -Verbose | Should -BeFalse
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
                        -Verbose | Should -BeFalse

                    Test-TargetResource `
                        -Name 'localhost' `
                        -DomainName 'adventure-works.com' `
                        -Credential $credential `
                        -Verbose | Should -BeFalse
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
                        -Verbose | Should -BeFalse

                    Test-TargetResource `
                        -Name 'localhost' `
                        -WorkGroupName 'NOTworkgroup' `
                        -Verbose | Should -BeFalse
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
                        -Verbose | Should -BeFalse

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
                        -Verbose | Should -BeFalse
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
                        -Verbose | Should -BeFalse

                    Test-TargetResource `
                        -Name 'localhost' `
                        -DomainName 'contoso.com' `
                        -Credential $credential `
                        -Verbose | Should -BeFalse
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
                        -Verbose | Should -BeFalse

                    Test-TargetResource `
                        -Name 'localhost' `
                        -WorkGroupName 'Contoso' `
                        -Credential $credential `
                        -UnjoinCredential $credential `
                        -Verbose | Should -BeFalse
                }

                It 'Throws if name is to long' {
                    {
                        Test-TargetResource `
                            -Name 'ThisNameIsTooLong' `
                            -Verbose
                    } | Should -Throw
                }

                It 'Throws if name contains illegal characters' {
                    {
                        Test-TargetResource `
                            -Name 'ThisIsBad<>' `
                            -Verbose
                    } | Should -Throw
                }

                It 'Should not Throw if name is localhost' {
                    {
                        Test-TargetResource `
                            -Name 'localhost' `
                            -Verbose
                    } | Should -Not -Throw
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
                        -Verbose | Should -BeTrue

                    Test-TargetResource `
                        -Name 'localhost' `
                        -Description 'This is my computer' `
                        -Verbose | Should -BeTrue
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
                        -Verbose | Should -BeFalse

                    Test-TargetResource `
                        -Name 'localhost' `
                        -Description 'This is my computer' `
                        -Verbose | Should -BeFalse
                }
            }

            Context 'DSC_Computer\Get-TargetResource' {
                It 'should not throw' {
                    {
                        Get-TargetResource `
                            -Name $env:COMPUTERNAME `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return a hashtable containing Name, DomainName, JoinOU, CurrentOU, Credential, UnjoinCredential, WorkGroupName and Description' {
                    $Result = Get-TargetResource `
                        -Name $env:COMPUTERNAME `
                        -Verbose

                    $Result.GetType().Fullname | Should -Be 'System.Collections.Hashtable'
                    $Result.Keys | Sort-Object | Should -Be @('Credential', 'CurrentOU', 'Description', 'DomainName', 'JoinOU', 'Name', 'Server', 'UnjoinCredential', 'WorkGroupName')
                }

                It 'Throws if name is to long' {
                    {
                        Get-TargetResource `
                            -Name 'ThisNameIsTooLong' `
                            -Verbose
                    } | Should -Throw
                }

                It 'Throws if name contains illegal characters' {
                    {
                        Get-TargetResource `
                            -Name 'ThisIsBad<>' `
                            -Verbose
                    } | Should -Throw
                }
            }

            Context 'DSC_Computer\Set-TargetResource' {
                Mock -CommandName Rename-Computer
                Mock -CommandName Set-CimInstance
                Mock -CommandName Get-ADSIComputer
                Mock -CommandName Delete-ADSIObject

                It 'Throws if both DomainName and WorkGroupName are specified' {
                    $errorRecord = Get-InvalidOperationRecord `
                        -Message ($LocalizedData.DomainNameAndWorkgroupNameError)

                    Mock -CommandName Add-Computer

                    {
                        Set-TargetResource `
                            -Name $env:COMPUTERNAME `
                            -DomainName 'contoso.com' `
                            -WorkGroupName 'workgroup' `
                            -Verbose
                    } | Should -Throw $errorRecord

                    Assert-MockCalled -CommandName Rename-Computer -Exactly -Times 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It
                }

                It 'Throws if Domain is specified without Credentials' {
                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($LocalizedData.CredentialsNotSpecifiedError) `
                        -ArgumentName 'Credentials'

                    Mock -CommandName Add-Computer

                    {
                        Set-TargetResource `
                            -Name $env:COMPUTERNAME `
                            -DomainName 'contoso.com' `
                            -Verbose
                    } | Should -Throw $errorRecord

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

                    Mock -CommandName Get-ADSIComputer -MockWith {
                        [PSCustomObject] @{
                            Path       = 'LDAP://Contoso.com/CN=mocked-comp,OU=Computers,DC=Contoso,DC=com';
                        }
                    }

                    Mock -CommandName Get-ComputerDomain -MockWith {
                        'contoso.com'
                    }

                    Mock -CommandName Add-Computer

                    Set-TargetResource `
                        -Name $notComputerName `
                        -DomainName 'adventure-works.com' `
                        -Credential $credential `
                        -UnjoinCredential $credential `
                        -Verbose | Should -BeNullOrEmpty

                    Assert-MockCalled -CommandName Rename-Computer -Exactly -Times 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $DomainName -and $NewName }
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $WorkGroupName }
                    Assert-MockCalled -CommandName Get-ADSIComputer -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Delete-ADSIObject -Exactly -Times 1 -Scope It
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

                    Mock -CommandName Get-ADSIComputer -MockWith {
                        [PSCustomObject] @{
                            Path       = 'LDAP://Contoso.com/CN=mocked-comp,OU=Computers,DC=Contoso,DC=com';
                        }
                    }

                    Mock -CommandName Add-Computer

                    Set-TargetResource `
                        -Name $notComputerName `
                        -DomainName 'adventure-works.com' `
                        -JoinOU 'OU=Computers,DC=contoso,DC=com' `
                        -Credential $credential `
                        -UnjoinCredential $credential `
                        -Verbose | Should -BeNullOrEmpty

                    Assert-MockCalled -CommandName Rename-Computer -Exactly -Times 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $DomainName -and $NewName }
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $WorkGroupName }
                    Assert-MockCalled -CommandName Get-ADSIComputer -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Delete-ADSIObject -Exactly -Times 1 -Scope It
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

                    Mock -CommandName Add-Computer

                    Set-TargetResource `
                        -Name $notComputerName `
                        -WorkGroupName 'contoso' `
                        -Credential $credential `
                        -Verbose | Should -BeNullOrEmpty

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

                    Mock -CommandName Get-ADSIComputer -MockWith {
                        [PSCustomObject] @{
                            Path       = 'LDAP://Contoso.com/CN=mocked-comp,OU=Computers,DC=Contoso,DC=com';
                        }
                    }

                    Mock -CommandName Get-ComputerDomain -MockWith {
                        ''
                    }

                    Mock -CommandName Add-Computer

                    Set-TargetResource `
                        -Name $notComputerName `
                        -DomainName 'Contoso.com' `
                        -Credential $credential `
                        -Verbose | Should -BeNullOrEmpty

                    Assert-MockCalled -CommandName Rename-Computer -Exactly -Times 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $DomainName -and $NewName }
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $WorkGroupName }
                    Assert-MockCalled -CommandName Get-ADSIComputer -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Delete-ADSIObject -Exactly -Times 1 -Scope It
                }

                It 'Changes ComputerName and changes Workgroup to Domain with specified Domain Controller' {
                    Mock -CommandName Get-WMIObject -MockWith {
                        [PSCustomObject] @{
                            Domain       = 'Contoso';
                            Workgroup    = 'Contoso';
                            PartOfDomain = $false
                        }
                    }

                    Mock -CommandName Get-ADSIComputer -MockWith {
                        [PSCustomObject] @{
                            Path       = 'LDAP://Contoso.com/CN=mocked-comp,OU=Computers,DC=Contoso,DC=com';
                        }
                    }

                    Mock -CommandName Get-ComputerDomain -MockWith {
                        ''
                    }

                    Mock -CommandName Add-Computer

                    Set-TargetResource `
                        -Name $notComputerName `
                        -DomainName 'Contoso.com' `
                        -Server 'dc01.contoso.com' `
                        -Credential $credential `
                        -Verbose | Should -BeNullOrEmpty

                    Assert-MockCalled -CommandName Rename-Computer -Exactly -Times 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $DomainName -and $NewName -and $Server }
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $WorkGroupName }
                    Assert-MockCalled -CommandName Get-ADSIComputer -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Delete-ADSIObject -Exactly -Times 1 -Scope It
                }

                It 'Changes ComputerName and changes Workgroup to Domain with specified OU' {
                    Mock -CommandName Get-WMIObject -MockWith {
                        [PSCustomObject] @{
                            Domain       = 'Contoso';
                            Workgroup    = 'Contoso';
                            PartOfDomain = $false
                        }
                    }

                    Mock -CommandName Get-ADSIComputer -MockWith {
                        [PSCustomObject] @{
                            Path       = 'LDAP://Contoso.com/CN=mocked-comp,OU=Computers,DC=Contoso,DC=com';
                        }
                    }

                    Mock -CommandName Get-ComputerDomain -MockWith {
                        ''
                    }

                    Mock -CommandName Add-Computer

                    Set-TargetResource `
                        -Name $notComputerName `
                        -DomainName 'Contoso.com' `
                        -JoinOU 'OU=Computers,DC=contoso,DC=com' `
                        -Credential $credential `
                        -Verbose | Should -BeNullOrEmpty

                    Assert-MockCalled -CommandName Rename-Computer -Exactly -Times 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $DomainName -and $NewName }
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $WorkGroupName }
                    Assert-MockCalled -CommandName Get-ADSIComputer -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Delete-ADSIObject -Exactly -Times 1 -Scope It
                }

                It 'Changes ComputerName and changes Domain to new Domain with Options passed' {
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

                    Mock -CommandName Add-Computer

                    Set-TargetResource `
                        -Name $notComputerName `
                        -DomainName 'adventure-works.com' `
                        -Credential $credential `
                        -UnjoinCredential $credential `
                        -Options @('InstallInvoke') `
                        -Verbose | Should -BeNullOrEmpty

                    Assert-MockCalled -CommandName Rename-Computer -Exactly -Times 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $DomainName -and $NewName }
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $WorkGroupName }
                }

                It 'Should try a separate rename if ''FailToRenameAfterJoinDomain'' occured during domain join' {
                    $message = "Computer '' was successfully joined to the new domain '', but renaming it to '' failed with the following error message: The directory service is busy."
                    $exception = [System.InvalidOperationException]::new($message)
                    $errorID = $failToRenameAfterJoinDomainErrorId
                    $errorCategory = [Management.Automation.ErrorCategory]::InvalidOperation
                    $errorRecord = [System.Management.Automation.ErrorRecord]::new($exception, $errorID, $errorCategory, $null)

                    Mock -CommandName Get-WMIObject -MockWith {
                        [PSCustomObject] @{
                            Domain       = 'Contoso'
                            Workgroup    = 'Contoso'
                            PartOfDomain = $false
                        }
                    }

                    Mock -CommandName Get-ADSIComputer -MockWith {
                        $null
                    }

                    Mock -CommandName Get-ComputerDomain -MockWith {
                        ''
                    }

                    Mock -CommandName Add-Computer -MockWith {
                        Throw $errorRecord
                    }

                    Set-TargetResource `
                        -Name $notComputerName `
                        -DomainName 'Contoso.com' `
                        -JoinOU 'OU=Computers,DC=contoso,DC=com' `
                        -Credential $credential | Should -BeNullOrEmpty

                    Assert-MockCalled -CommandName Rename-Computer -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $DomainName -and $NewName }
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $WorkGroupName }
                    Assert-MockCalled -CommandName Get-ADSIComputer -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Delete-ADSIObject -Exactly -Times 0 -Scope It
                }

                It 'Should Throw the correct error if Add-Computer errors with an unknown InvalidOperationException' {
                    $error = 'Unknown Error'
                    $errorRecord = [System.InvalidOperationException]::new($error)

                    Mock -CommandName Get-WMIObject -MockWith {
                        [PSCustomObject] @{
                            Domain       = 'Contoso'
                            Workgroup    = 'Contoso'
                            PartOfDomain = $false
                        }
                    }

                    Mock -CommandName Get-ComputerDomain -MockWith {
                        ''
                    }

                    Mock -CommandName Add-Computer -MockWith {
                        throw $errorRecord
                    }

                    Mock -CommandName New-InvalidOperationException -MockWith {
                        throw $errorRecord
                    }

                    { Set-TargetResource `
                            -Name $notComputerName `
                            -DomainName 'Contoso.com' `
                            -JoinOU 'OU=Computers,DC=contoso,DC=com' `
                            -Credential $credential
                    } | Should -Throw $error

                    Assert-MockCalled -CommandName Rename-Computer -Exactly -Times 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $DomainName -and $NewName }
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $WorkGroupName }
                }

                It 'Should Throw the correct error if Add-Computer errors with an unknown error' {
                    $errorRecord = 'Unknown Error'
                    Mock -CommandName Get-WMIObject -MockWith {
                        [PSCustomObject] @{
                            Domain       = 'Contoso'
                            Workgroup    = 'Contoso'
                            PartOfDomain = $false
                        }
                    }

                    Mock -CommandName Get-ComputerDomain -MockWith {
                        ''
                    }

                    Mock -CommandName Add-Computer -MockWith {
                        Throw $errorRecord
                    }

                    Mock -CommandName New-InvalidOperationException -MockWith {
                        Throw $errorRecord
                    }

                    { Set-TargetResource `
                            -Name $notComputerName `
                            -DomainName 'Contoso.com' `
                            -JoinOU 'OU=Computers,DC=contoso,DC=com' `
                            -Credential $credential
                    } | Should -Throw $errorRecord

                    Assert-MockCalled -CommandName Rename-Computer -Exactly -Times 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $DomainName -and $NewName }
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $WorkGroupName }
                    Assert-MockCalled -CommandName Get-ADSIComputer -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Delete-ADSIObject -Exactly -Times 0 -Scope It
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

                    Mock -CommandName Add-Computer

                    Set-TargetResource `
                        -Name $notComputerName `
                        -WorkGroupName 'adventure-works' `
                        -Verbose | Should -BeNullOrEmpty

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

                    Mock -CommandName Add-Computer

                    Set-TargetResource `
                        -Name $env:COMPUTERNAME `
                        -DomainName 'adventure-works.com' `
                        -Credential $credential `
                        -UnjoinCredential $credential `
                        -Verbose | Should -BeNullOrEmpty

                    Assert-MockCalled -CommandName Rename-Computer -Exactly -Times 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $DomainName }
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $NewName }
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $WorkGroupName }
                    Assert-MockCalled -CommandName Get-ADSIComputer -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Delete-ADSIObject -Exactly -Times 0 -Scope It
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

                    Mock -CommandName Add-Computer

                    Set-TargetResource `
                        -Name 'localhost' `
                        -DomainName 'adventure-works.com' `
                        -Credential $credential `
                        -UnjoinCredential $credential `
                        -Verbose | Should -BeNullOrEmpty

                    Assert-MockCalled -CommandName Rename-Computer -Exactly -Times 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $DomainName }
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $NewName }
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $WorkGroupName }
                    Assert-MockCalled -CommandName Get-ADSIComputer -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Delete-ADSIObject -Exactly -Times 0 -Scope It
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

                    Mock -CommandName Add-Computer

                    Set-TargetResource `
                        -Name $env:COMPUTERNAME `
                        -DomainName 'adventure-works.com' `
                        -JoinOU 'OU=Computers,DC=contoso,DC=com' `
                        -Credential $credential `
                        -UnjoinCredential $credential `
                        -Verbose | Should -BeNullOrEmpty

                    Assert-MockCalled -CommandName Rename-Computer -Exactly -Times 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $DomainName }
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $NewName }
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $WorkGroupName }
                    Assert-MockCalled -CommandName Get-ADSIComputer -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Delete-ADSIObject -Exactly -Times 0 -Scope It
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

                    Mock -CommandName Add-Computer

                    Set-TargetResource `
                        -Name 'localhost' `
                        -DomainName 'adventure-works.com' `
                        -JoinOU 'OU=Computers,DC=contoso,DC=com' `
                        -Credential $credential `
                        -UnjoinCredential $credential `
                        -Verbose | Should -BeNullOrEmpty

                    Assert-MockCalled -CommandName Rename-Computer -Exactly -Times 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $DomainName }
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $NewName }
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $WorkGroupName }
                    Assert-MockCalled -CommandName Get-ADSIComputer -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Delete-ADSIObject -Exactly -Times 0 -Scope It
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

                    Mock -CommandName Add-Computer

                    Set-TargetResource `
                        -Name $env:COMPUTERNAME `
                        -WorkGroupName 'Contoso' `
                        -UnjoinCredential $credential `
                        -Verbose | Should -BeNullOrEmpty

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

                    Mock -CommandName Add-Computer

                    Set-TargetResource `
                        -Name 'localhost' `
                        -WorkGroupName 'Contoso' `
                        -UnjoinCredential $credential `
                        -Verbose | Should -BeNullOrEmpty

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

                    Mock -CommandName Add-Computer

                    Set-TargetResource `
                        -Name $notComputerName `
                        -Credential $credential `
                        -Verbose | Should -BeNullOrEmpty

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
                        -Verbose | Should -BeNullOrEmpty

                    Assert-MockCalled -CommandName Rename-Computer -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 0 -Scope It
                }

                It 'Throws if name is to long' {
                    {
                        Set-TargetResource `
                            -Name 'ThisNameIsTooLong' `
                            -Verbose
                    } | Should -Throw
                }

                It 'Throws if name contains illegal characters' {
                    {
                        Set-TargetResource `
                            -Name 'ThisIsBad<>' `
                            -Verbose
                    } | Should -Throw
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
                        -Verbose | Should -BeNullOrEmpty

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
                        -Verbose | Should -BeNullOrEmpty

                    Set-TargetResource `
                        -Name $env:COMPUTERNAME `
                        -DomainName 'Contoso.com' `
                        -Credential $credential `
                        -UnjoinCredential $credential `
                        -Description 'This is my computer' `
                        -Verbose | Should -BeNullOrEmpty

                    Assert-MockCalled -CommandName Set-CimInstance -Exactly -Times 1 -Scope It
                }
            }

            Context 'DSC_Computer\Get-ComputerDomain' {
                It 'Returns domain netbios or DNS name if domain member' {
                    Mock -CommandName Get-CimInstance -ParameterFilter { $ClassName -eq 'Win32_ComputerSystem' } -MockWith {
                        [PSCustomObject] @{
                            Domain       = 'contoso.com';
                            PartOfDomain = $true
                        }
                    }

                    Mock -CommandName Get-Item -ParameterFilter { $Path -eq 'Env:\USERDOMAIN' } -MockWith {
                        [PSCustomObject] @{
                            Value = 'CONTOSO'
                        }
                    }

                    $getComputerDomainParameters = @{
                        netbios = $true
                    }

                    Get-ComputerDomain @getComputerDomainParameters | Should -Be 'CONTOSO'

                    $getComputerDomainParameters = @{
                        netbios = $false
                    }

                    Get-ComputerDomain @getComputerDomainParameters | Should -Be 'contoso.com'

                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 2 -Scope It
                    Assert-MockCalled -CommandName Get-Item -Exactly -Times 1 -Scope It
                }

                It 'Returns nothing if in a workgroup' {
                    Mock -CommandName Get-CimInstance -ParameterFilter { $ClassName -eq 'Win32_ComputerSystem' } -MockWith {
                        [PSCustomObject] @{
                            Domain       = 'WORKGROUP';
                            PartOfDomain = $false
                        }
                    }

                    Mock -CommandName Get-Item -ParameterFilter { $Path -eq 'Env:\USERDOMAIN' } -MockWith {
                        [PSCustomObject] @{
                            Value = 'Computer1'
                        }
                    }

                    $getComputerDomainParameters = @{
                        netbios = $true
                    }

                    Get-ComputerDomain @getComputerDomainParameters | Should -Be ''

                    $getComputerDomainParameters = @{
                        netbios = $false
                    }

                    Get-ComputerDomain @getComputerDomainParameters | Should -Be ''

                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 2 -Scope It
                    Assert-MockCalled -CommandName Get-Item -Exactly -Times 0 -Scope It
                }

                It 'Returns domain DNS name when netbios not specified' {
                    Mock -CommandName Get-CimInstance -ParameterFilter { $ClassName -eq 'Win32_ComputerSystem' } -MockWith {
                        [PSCustomObject] @{
                            Domain       = 'contoso.com';
                            PartOfDomain = $true
                        }
                    }

                    Mock -CommandName Get-Item -ParameterFilter { $Path -eq 'Env:\USERDOMAIN' } -MockWith {
                        [PSCustomObject] @{
                            Value = 'CONTOSO'
                        }
                    }

                    Get-ComputerDomain | Should -Be "contoso.com"

                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Get-Item -Exactly -Times 0 -Scope It
                }
            }

            Context 'DSC_Computer\Get-LogonServer' {
                It 'Should return a non-empty string' {
                    Get-LogonServer | Should -Not -BeNullOrEmpty
                }
            }

            Context 'DSC_Computer\Get-ADSIComputer' {
                class fake_adsi_directoryentry {
                    [string] $Domain
                    [string] $Username
                    [string] $password
                }

                class fake_adsi_searcher {
                    [string] $SearchRoot
                    [string] $Filter
                    [hashtable] FindOne( ){
                        return @{
                            path = 'LDAP://contoso.com/CN=fake-computer,OU=Computers,DC=contoso,DC=com'
                        }
                     }
                }

                Mock -CommandName New-Object -MockWith {
                        New-Object -TypeName 'fake_adsi_directoryentry'
                    } `
                    -ParameterFilter {
                        $TypeName -and
                        $TypeName -eq 'System.DirectoryServices.DirectoryEntry'
                    }

                It 'Should throw the expected exception if the name is to long' {
                    {
                       $error = Get-ADSIComputer `
                            -Name 'ThisNameIsTooLong' `
                            -Domain 'Contoso.com' `
                            -Credential $credential `
                            -Verbose
                        $error
                    } | Should -Throw "Test-ParamValidator: Cannot validate argument on parameter 'Name'. The character length of the 17 argument is too long. Shorten the character length of the argument so it is fewer than or equal to `"15`" characters, and then try the command again."
                }

                It 'Should throws if the expected exception if the name contains illegal characters' {
                    {
                        Get-ADSIComputer `
                            -Name 'IllegalName[<' `
                            -Domain 'Contoso.com' `
                            -Credential $credential `
                            -Verbose
                    } | Should -Throw "Test-ParamValidator: Cannot validate argument on parameter 'Name'. The `" $_ -inotmatch '[\/\\:*?`"<>|]' `" validation script for the argument with value `"IllegalName[<`" did not return a result of True. Determine why the validation script failed, and then try the command again."
                }

                It 'Returns ADSI object with ADSI path ' {
                    Mock -CommandName New-Object -MockWith {
                            New-Object -TypeName 'fake_adsi_directoryentry'
                        } `
                        -ParameterFilter {
                            $TypeName -and
                            $TypeName -eq 'System.DirectoryServices.DirectoryEntry'
                        }

                    $obj = Get-ADSIComputer `
                        -Name 'LegalName' `
                        -Domain 'LDAP://Contoso.com' `
                        -Credential $credential `
                        -Verbose
                    $obj.path | Should -Be 'LDAP://contoso.com/CN=fake-computer,OU=Computers,DC=contoso,DC=com'
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 2 -Scope It
                }

                It 'Returns ADSI object with domain name' {

                    Mock -CommandName New-Object -MockWith {
                            New-Object -TypeName 'fake_adsi_directoryentry'
                        } `
                        -ParameterFilter {
                            $TypeName -and
                            $TypeName -eq 'System.DirectoryServices.DirectoryEntry'
                        }

                    $obj = Get-ADSIComputer `
                            -Name 'LegalName' `
                            -Domain 'Contoso.com' `
                            -Credential $credential `
                            -Verbose
                    $obj.Path | Should -Be 'LDAP://contoso.com/CN=fake-computer,OU=Computers,DC=contoso,DC=com'
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 2 -Scope It
                }

                It 'Should throw the expected exception if Credential is incorrect' {
                    Mock 'New-Object' { Write-Error -message "Invalid Credentials" } `
                        -ParameterFilter {
                            $TypeName -and
                            $TypeName -eq 'System.DirectoryServices.DirectoryEntry'
                        }

                    {
                        Get-ADSIComputer `
                            -Name 'LegalName' `
                            -Domain 'Contoso.com' `
                            -Credential $credential `
                            -Verbose
                    } | Should -Throw "Invalid Credentials"
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 2 -Scope It
                }
            }

            Context 'DSC_Computer\Delete-ADSIObject' {

                class fake_adsi_directoryentry {
                    [string] $Domain
                    [string] $Username
                    [string] $password
                    [void] DeleteTree(){ }
                }

                It 'Should delete the ADSI Object' {
                    Mock 'New-Object' { New-Object 'fake_adsi_directoryentry' } `
                    -ParameterFilter {
                        $TypeName -and
                        $TypeName -eq 'System.DirectoryServices.DirectoryEntry'
                    }

                    {
                        Delete-ADSIObject `
                            -Path 'LDAP://contoso.com/CN=fake-computer,OU=Computers,DC=contoso,DC=com' `
                            -Credential $credential `
                            -Verbose
                    } | Should -Not -Throw
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope It
                }

                It 'Should throw if path does not begin with LDAP://' {
                    {
                        Delete-ADSIObject `
                            -Path 'contoso.com/CN=fake-computer,OU=Computers,DC=contoso,DC=com' `
                            -Credential $credential`
                            -Verbose
                    } | Should -Throw "Test-ParamValidator: Cannot validate argument on parameter 'Path'. The `" $_ -imatch `"LDAP://*`" `" validation script for the argument with value `"contoso.com/CN=fake-computer,OU=Computers,DC=contoso,DC=com`" did not return a result of True. Determine why the validation script failed, and then try the command again."
                }

                It 'Should throw if Credential is incorrect' {
                    Mock 'New-Object' { Write-Error -message "Invalid Credential" } `
                        -ParameterFilter {
                            $TypeName -and
                            $TypeName -eq 'System.DirectoryServices.DirectoryEntry'
                        }

                    {
                        Delete-ADSIObject `
                            -Path 'LDAP://contoso.com/CN=fake-computer,OU=Computers,DC=contoso,DC=com' `
                            -Credential $credential `
                            -Verbose
                    } | Should -Throw "Invalid Credential"
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope It
                }
            }

            Context 'DSC_Computer\Assert-ResourceProperty' {
                It 'Should throw if PasswordPass and UnsecuredJoin is present but credential username is not null' {
                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($LocalizedData.InvalidOptionCredentialUnsecuredJoinNullUsername) `
                        -ArgumentName 'Credential'

                    {
                        Assert-ResourceProperty `
                            -Name $env:COMPUTERNAME `
                            -Options @('PasswordPass', 'UnsecuredJoin') `
                            -Credential $credential `
                            -Verbose
                    } | Should -Throw $errorRecord
                }

                It 'Should throw if PasswordPass is present in options without UnsecuredJoin' {
                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($LocalizedData.InvalidOptionPasswordPassUnsecuredJoin) `
                        -ArgumentName 'PasswordPass'

                    {
                        Assert-ResourceProperty `
                            -Name $env:COMPUTERNAME `
                            -Options @('PasswordPass') `
                            -Verbose
                    } | Should -Throw $errorRecord
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
