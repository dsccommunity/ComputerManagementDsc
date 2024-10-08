# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }

    <#
        Need to define that variables here to be used in the Pester Discover to
        build the ForEach-blocks.
    #>
    $script:dscModuleName = 'ComputerManagementDsc'
    $script:dscResourceName = 'DSC_SmbServerConfiguration'

    # Ensure that the tests can be performed on this computer
    $script:skipIntegrationTests = $false
}

BeforeAll {
    $script:dscModuleName = 'ComputerManagementDsc'
    $script:dscResourceName = 'DSC_SmbServerConfiguration'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Integration'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    $script:CurrentSmbServerConfigBackup = Get-SmbServerConfiguration
}

AfterAll {
    $setSmbServerConfigurationParameters = @{
        AnnounceComment                 = $script:CurrentSmbServerConfigBackup.AnnounceComment
        AnnounceServer                  = $script:CurrentSmbServerConfigBackup.AnnounceServer
        AsynchronousCredits             = $script:CurrentSmbServerConfigBackup.AsynchronousCredits
        AuditSmb1Access                 = $script:CurrentSmbServerConfigBackup.AuditSmb1Access
        AutoDisconnectTimeout           = $script:CurrentSmbServerConfigBackup.AutoDisconnectTimeout
        AutoShareServer                 = $script:CurrentSmbServerConfigBackup.AutoShareServer
        AutoShareWorkstation            = $script:CurrentSmbServerConfigBackup.AutoShareWorkstation
        CachedOpenLimit                 = $script:CurrentSmbServerConfigBackup.CachedOpenLimit
        DurableHandleV2TimeoutInSeconds = $script:CurrentSmbServerConfigBackup.DurableHandleV2TimeoutInSeconds
        EnableAuthenticateUserSharing   = $script:CurrentSmbServerConfigBackup.EnableAuthenticateUserSharing
        EnableDownlevelTimewarp         = $script:CurrentSmbServerConfigBackup.EnableDownlevelTimewarp
        EnableForcedLogoff              = $script:CurrentSmbServerConfigBackup.EnableForcedLogoff
        EnableLeasing                   = $script:CurrentSmbServerConfigBackup.EnableLeasing
        EnableMultiChannel              = $script:CurrentSmbServerConfigBackup.EnableMultiChannel
        EnableOplocks                   = $script:CurrentSmbServerConfigBackup.EnableOplocks
        EnableSecuritySignature         = $script:CurrentSmbServerConfigBackup.EnableSecuritySignature
        EnableSMB1Protocol              = $script:CurrentSmbServerConfigBackup.EnableSMB1Protocol
        EnableSMB2Protocol              = $script:CurrentSmbServerConfigBackup.EnableSMB2Protocol
        EnableStrictNameChecking        = $script:CurrentSmbServerConfigBackup.EnableStrictNameChecking
        EncryptData                     = $script:CurrentSmbServerConfigBackup.EncryptData
        IrpStackSize                    = $script:CurrentSmbServerConfigBackup.IrpStackSize
        KeepAliveTime                   = $script:CurrentSmbServerConfigBackup.KeepAliveTime
        MaxChannelPerSession            = $script:CurrentSmbServerConfigBackup.MaxChannelPerSession
        MaxMpxCount                     = $script:CurrentSmbServerConfigBackup.MaxMpxCount
        MaxSessionPerConnection         = $script:CurrentSmbServerConfigBackup.MaxSessionPerConnection
        MaxThreadsPerQueue              = $script:CurrentSmbServerConfigBackup.MaxThreadsPerQueue
        MaxWorkItems                    = $script:CurrentSmbServerConfigBackup.MaxWorkItems
        NullSessionPipes                = $script:CurrentSmbServerConfigBackup.NullSessionPipes
        NullSessionShares               = $script:CurrentSmbServerConfigBackup.NullSessionShares
        OplockBreakWait                 = $script:CurrentSmbServerConfigBackup.OplockBreakWait
        PendingClientTimeoutInSeconds   = $script:CurrentSmbServerConfigBackup.PendingClientTimeoutInSeconds
        RejectUnencryptedAccess         = $script:CurrentSmbServerConfigBackup.RejectUnencryptedAccess
        RequireSecuritySignature        = $script:CurrentSmbServerConfigBackup.RequireSecuritySignature
        ServerHidden                    = $script:CurrentSmbServerConfigBackup.ServerHidden
        Smb2CreditsMax                  = $script:CurrentSmbServerConfigBackup.Smb2CreditsMax
        Smb2CreditsMin                  = $script:CurrentSmbServerConfigBackup.Smb2CreditsMin
        SmbServerNameHardeningLevel     = $script:CurrentSmbServerConfigBackup.SmbServerNameHardeningLevel
        TreatHostAsStableStorage        = $script:CurrentSmbServerConfigBackup.TreatHostAsStableStorage
        ValidateAliasNotCircular        = $script:CurrentSmbServerConfigBackup.ValidateAliasNotCircular
        ValidateShareScope              = $script:CurrentSmbServerConfigBackup.ValidateShareScope
        ValidateShareScopeNotAliased    = $script:CurrentSmbServerConfigBackup.ValidateShareScopeNotAliased
        ValidateTargetName              = $script:CurrentSmbServerConfigBackup.ValidateTargetName
        Confirm                         = $false
    }

    Set-SmbServerConfiguration @setSmbServerConfigurationParameters

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}



Describe "$($script:dscResourceName)_Integration" {
    BeforeAll {
        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
        . $configFile

        $configData = @{
            AllNodes = @(
                @{
                    NodeName                        = 'localhost'
                    IsSingleInstance                = 'Yes'
                    AnnounceComment                 = 'Test String'
                    AnnounceServer                  = $true
                    AsynchronousCredits             = 32
                    AuditSmb1Access                 = $true
                    AutoDisconnectTimeout           = 30
                    AutoShareServer                 = $false
                    AutoShareWorkstation            = $false
                    CachedOpenLimit                 = 20
                    DurableHandleV2TimeoutInSeconds = 90
                    EnableAuthenticateUserSharing   = $true
                    EnableDownlevelTimewarp         = $true
                    EnableForcedLogoff              = $false
                    EnableLeasing                   = $false
                    EnableMultiChannel              = $false
                    EnableOplocks                   = $false
                    EnableSecuritySignature         = $true
                    EnableSMB1Protocol              = $false
                    EnableSMB2Protocol              = $false
                    EnableStrictNameChecking        = $false
                    EncryptData                     = $true
                    IrpStackSize                    = 20
                    KeepAliveTime                   = 3
                    MaxChannelPerSession            = 16
                    MaxMpxCount                     = 100
                    MaxSessionPerConnection         = 16000
                    MaxThreadsPerQueue              = 15
                    MaxWorkItems                    = 2
                    NullSessionPipes                = 'TestPipe'
                    NullSessionShares               = 'TestShare'
                    OplockBreakWait                 = 30
                    PendingClientTimeoutInSeconds   = 60
                    RejectUnencryptedAccess         = $false
                    RequireSecuritySignature        = $true
                    ServerHidden                    = $false
                    Smb2CreditsMax                  = 2000
                    Smb2CreditsMin                  = 256
                    SmbServerNameHardeningLevel     = 1
                    TreatHostAsStableStorage        = $true
                    ValidateAliasNotCircular        = $false
                    ValidateShareScope              = $false
                    ValidateShareScopeNotAliased    = $false
                    ValidateTargetName              = $false
                }
            )
        }
    }

    It 'Should compile the MOF without throwing' {
        {
            & "$($script:dscResourceName)_Config" `
                -OutputPath $TestDrive `
                -ConfigurationData $configData
        } | Should -Not -Throw
    }

    It 'Should apply the MOF without throwing' {
        {
            Reset-DscLcm

            $startDscConfigurationParameters = @{
                Path         = $TestDrive
                ComputerName = 'localhost'
                Wait         = $true
                Verbose      = $true
                Force        = $true
                ErrorAction  = 'Stop'
            }

            Start-DscConfiguration @startDscConfigurationParameters
        } | Should -Not -Throw
    }

    It 'Should be able to call Get-DscConfiguration without throwing' {
        {
            Get-DscConfiguration -Verbose -ErrorAction Stop
        } | Should -Not -Throw
    }

    It 'Should have set the resource and all the parameters should match' {
        $current = Get-DscConfiguration | Where-Object -FilterScript {
            $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
        }
        $current.AnnounceComment | Should -Be $configData.AllNodes[0].AnnounceComment
        $current.AnnounceServer | Should -Be $configData.AllNodes[0].AnnounceServer
        $current.AsynchronousCredits | Should -Be $configData.AllNodes[0].AsynchronousCredits
        $current.AuditSmb1Access | Should -Be $configData.AllNodes[0].AuditSmb1Access
        $current.AutoDisconnectTimeout | Should -Be $configData.AllNodes[0].AutoDisconnectTimeout
        $current.AutoShareServer | Should -Be $configData.AllNodes[0].AutoShareServer
        $current.AutoShareWorkstation | Should -Be $configData.AllNodes[0].AutoShareWorkstation
        $current.CachedOpenLimit | Should -Be $configData.AllNodes[0].CachedOpenLimit
        $current.DurableHandleV2TimeoutInSeconds | Should -Be $configData.AllNodes[0].DurableHandleV2TimeoutInSeconds
        $current.EnableAuthenticateUserSharing | Should -Be $configData.AllNodes[0].EnableAuthenticateUserSharing
        $current.EnableDownlevelTimewarp | Should -Be $configData.AllNodes[0].EnableDownlevelTimewarp
        $current.EnableForcedLogoff | Should -Be $configData.AllNodes[0].EnableForcedLogoff
        $current.EnableLeasing | Should -Be $configData.AllNodes[0].EnableLeasing
        $current.EnableMultiChannel | Should -Be $configData.AllNodes[0].EnableMultiChannel
        $current.EnableOplocks | Should -Be $configData.AllNodes[0].EnableOplocks
        $current.EnableSecuritySignature | Should -Be $configData.AllNodes[0].EnableSecuritySignature
        $current.EnableSMB1Protocol | Should -Be $configData.AllNodes[0].EnableSMB1Protocol
        $current.EnableSMB2Protocol | Should -Be $configData.AllNodes[0].EnableSMB2Protocol
        $current.EnableStrictNameChecking | Should -Be $configData.AllNodes[0].EnableStrictNameChecking
        $current.EncryptData | Should -Be $configData.AllNodes[0].EncryptData
        $current.IrpStackSize | Should -Be $configData.AllNodes[0].IrpStackSize
        $current.KeepAliveTime | Should -Be $configData.AllNodes[0].KeepAliveTime
        $current.MaxChannelPerSession | Should -Be $configData.AllNodes[0].MaxChannelPerSession
        $current.MaxMpxCount | Should -Be $configData.AllNodes[0].MaxMpxCount
        $current.MaxSessionPerConnection | Should -Be $configData.AllNodes[0].MaxSessionPerConnection
        $current.MaxThreadsPerQueue | Should -Be $configData.AllNodes[0].MaxThreadsPerQueue
        $current.MaxWorkItems | Should -Be $configData.AllNodes[0].MaxWorkItems
        $current.NullSessionPipes | Should -Be $configData.AllNodes[0].NullSessionPipes
        $current.NullSessionShares | Should -Be $configData.AllNodes[0].NullSessionShares
        $current.OplockBreakWait | Should -Be $configData.AllNodes[0].OplockBreakWait
        $current.PendingClientTimeoutInSeconds | Should -Be $configData.AllNodes[0].PendingClientTimeoutInSeconds
        $current.RejectUnencryptedAccess | Should -Be $configData.AllNodes[0].RejectUnencryptedAccess
        $current.RequireSecuritySignature | Should -Be $configData.AllNodes[0].RequireSecuritySignature
        $current.ServerHidden | Should -Be $configData.AllNodes[0].ServerHidden
        $current.Smb2CreditsMax | Should -Be $configData.AllNodes[0].Smb2CreditsMax
        $current.Smb2CreditsMin | Should -Be $configData.AllNodes[0].Smb2CreditsMin
        $current.SmbServerNameHardeningLevel | Should -Be $configData.AllNodes[0].SmbServerNameHardeningLevel
        $current.TreatHostAsStableStorage | Should -Be $configData.AllNodes[0].TreatHostAsStableStorage
        $current.ValidateAliasNotCircular | Should -Be $configData.AllNodes[0].ValidateAliasNotCircular
        $current.ValidateShareScope | Should -Be $configData.AllNodes[0].ValidateShareScope
        $current.ValidateShareScopeNotAliased | Should -Be $configData.AllNodes[0].ValidateShareScopeNotAliased
        $current.ValidateTargetName | Should -Be $configData.AllNodes[0].ValidateTargetName
    }
}
