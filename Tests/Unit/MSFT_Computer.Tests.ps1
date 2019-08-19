#region HEADER
$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'MSFT_Computer'

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
        $script:dscResourceName = 'MSFT_Computer'

        Describe $script:dscResourceName {
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

            Context "$($script:dscResourceName)\Test-TargetResource" {
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

            Context "$($script:dscResourceName)\Get-TargetResource" {
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

            Context "$($script:dscResourceName)\Set-TargetResource" {
                Mock -CommandName Rename-Computer
                Mock -CommandName Set-CimInstance

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
                }

                It 'Changes ComputerName and changes Workgroup to Domain with specified Domain Controller' {
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
                        -DomainName 'Contoso.com' `
                        -Server 'dc01.contoso.com' `
                        -Credential $credential `
                        -Verbose | Should -BeNullOrEmpty

                    Assert-MockCalled -CommandName Rename-Computer -Exactly -Times 0 -Scope It
                    Assert-MockCalled -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $DomainName -and $NewName -and $Server }
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

            Context "$($script:dscResourceName)\Get-ComputerDomain" {
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

            Context "$($script:dscResourceName)\Get-LogonServer" {
                It 'Should return a non-empty string' {
                    Get-LogonServer | Should -Not -BeNullOrEmpty
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
