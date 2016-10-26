#
# xComputer: DSC resource to rename a computer and add it to a domain or
# workgroup.
#

function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory)]
        [ValidateLength(1,15)]
        [ValidateScript({$_ -inotmatch'[\/\\:*?"<>|]' })]
        [string] $Name,

        [string] $DomainName,

        [string] $JoinOU,

        [PSCredential] $Credential,

        [PSCredential] $UnjoinCredential,

        [string] $WorkGroupName,

        [ValidateSet("af", "af-ZA", "am", "am-ET", "ar", "ar-AE", "ar-BH", "ar-DZ", "ar-EG", "ar-IQ", "ar-JO", "ar-KW", "ar-LB", "ar-LY", "ar-MA", "ar-OM", "ar-QA", "ar-SA", "ar-SY", "ar-TN", "ar-YE", "arn", "arn-CL", "as", "as-IN", "az", "az-Cyrl", "az-Cyrl-AZ", "az-Latn", "az-Latn-AZ", "ba", "ba-RU", "be", "be-BY", "bg", "bg-BG", "bn", "bn-BD", "bn-IN", "bo", "bo-CN", "br", "br-FR", "bs", "bs-Cyrl", "bs-Cyrl-BA", "bs-Latn", "bs-Latn-BA", "ca", "ca-ES", "ca-ES-valencia", "chr", "chr-Cher", "chr-Cher-US", "co", "co-FR", "cs", "cs-CZ", "cy", "cy-GB", "da", "da-DK", "de", "de-AT", "de-CH", "de-DE", "de-LI", "de-LU", "dsb", "dsb-DE", "dv", "dv-MV", "el", "el-GR", "en", "en-029", "en-AU", "en-BZ", "en-CA", "en-GB", "en-HK", "en-IE", "en-IN", "en-JM", "en-MY", "en-NZ", "en-PH", "en-SG", "en-TT", "en-US", "en-ZA", "en-ZW", "es", "es-419", "es-AR", "es-BO", "es-CL", "es-CO", "es-CR", "es-DO", "es-EC", "es-ES", "es-GT", "es-HN", "es-MX", "es-NI", "es-PA", "es-PE", "es-PR", "es-PY", "es-SV", "es-US", "es-UY", "es-VE", "et", "et-EE", "eu", "eu-ES", "fa", "fa-IR", "ff", "ff-Latn", "ff-Latn-SN", "fi", "fi-FI", "fil", "fil-PH", "fo", "fo-FO", "fr", "fr-BE", "fr-CA", "fr-CD", "fr-CH", "fr-CI", "fr-CM", "fr-FR", "fr-HT", "fr-LU", "fr-MA", "fr-MC", "fr-ML", "fr-RE", "fr-SN", "fy", "fy-NL", "ga", "ga-IE", "gd", "gd-GB", "gl", "gl-ES", "gn", "gn-PY", "gsw", "gsw-FR", "gu", "gu-IN", "ha", "ha-Latn", "ha-Latn-NG", "haw", "haw-US", "he", "he-IL", "hi", "hi-IN", "hr", "hr-BA", "hr-HR", "hsb", "hsb-DE", "hu", "hu-HU", "hy", "hy-AM", "id", "id-ID", "ig", "ig-NG", "ii", "ii-CN", "is", "is-IS", "it", "it-CH", "it-IT", "iu", "iu-Cans", "iu-Cans-CA", "iu-Latn", "iu-Latn-CA", "ja", "ja-JP", "jv", "jv-Latn", "jv-Latn-ID", "ka", "ka-GE", "kk", "kk-KZ", "kl", "kl-GL", "km", "km-KH", "kn", "kn-IN", "ko", "ko-KR", "kok", "kok-IN", "ku", "ku-Arab", "ku-Arab-IQ", "ky", "ky-KG", "lb", "lb-LU", "lo", "lo-LA", "lt", "lt-LT", "lv", "lv-LV", "mg", "mg-MG", "mi", "mi-NZ", "mk", "mk-MK", "ml", "ml-IN", "mn", "mn-Cyrl", "mn-MN", "mn-Mong", "mn-Mong-CN", "mn-Mong-MN", "moh", "moh-CA", "mr", "mr-IN", "ms", "ms-BN", "ms-MY", "mt", "mt-MT", "my", "my-MM", "nb", "nb-NO", "ne", "ne-IN", "ne-NP", "nl", "nl-BE", "nl-NL", "nn", "nn-NO", "no", "nqo", "nqo-GN", "nso", "nso-ZA", "oc", "oc-FR", "om", "om-ET", "or", "or-IN", "pa", "pa-Arab", "pa-Arab-PK", "pa-IN", "pl", "pl-PL", "prs", "prs-AF", "ps", "ps-AF", "pt", "pt-AO", "pt-BR", "pt-PT", "qut", "qut-GT", "quz", "quz-BO", "quz-EC", "quz-PE", "rm", "rm-CH", "ro", "ro-MD", "ro-RO", "ru", "ru-RU", "rw", "rw-RW", "sa", "sa-IN", "sah", "sah-RU", "sd", "sd-Arab", "sd-Arab-PK", "se", "se-FI", "se-NO", "se-SE", "si", "si-LK", "sk", "sk-SK", "sl", "sl-SI", "sma", "sma-NO", "sma-SE", "smj", "smj-NO", "smj-SE", "smn", "smn-FI", "sms", "sms-FI", "sn", "sn-Latn", "sn-Latn-ZW", "so", "so-SO", "sq", "sq-AL", "sr", "sr-Cyrl", "sr-Cyrl-BA", "sr-Cyrl-CS", "sr-Cyrl-ME", "sr-Cyrl-RS", "sr-Latn", "sr-Latn-BA", "sr-Latn-CS", "sr-Latn-ME", "sr-Latn-RS", "st", "st-ZA", "sv", "sv-FI", "sv-SE", "sw", "sw-KE", "syr", "syr-SY", "ta", "ta-IN", "ta-LK", "te", "te-IN", "tg", "tg-Cyrl", "tg-Cyrl-TJ", "th", "th-TH", "ti", "ti-ER", "ti-ET", "tk", "tk-TM", "tn", "tn-BW", "tn-ZA", "tr", "tr-TR", "ts", "ts-ZA", "tt", "tt-RU", "tzm", "tzm-Latn", "tzm-Latn-DZ", "tzm-Tfng", "tzm-Tfng-MA", "ug", "ug-CN", "uk", "uk-UA", "ur", "ur-IN", "ur-PK", "uz", "uz-Cyrl", "uz-Cyrl-UZ", "uz-Latn", "uz-Latn-UZ", "vi", "vi-VN", "wo", "wo-SN", "xh", "xh-ZA", "yo", "yo-NG", "zgh", "zgh-Tfng", "zgh-Tfng-MA", "zh", "zh-CN", "zh-Hans", "zh-Hant", "zh-HK", "zh-MO", "zh-SG", "zh-TW", "zu", "zu-ZA", "zh-CHS", "zh-CHT")]
        [string] $SystemLocale
    )

    $convertToCimCredential = New-CimInstance -ClassName MSFT_Credential -Property @{Username=[string]$Credential.UserName; Password=[string]$null} -Namespace root/microsoft/windows/desiredstateconfiguration -ClientOnly
    $convertToCimUnjoinCredential = New-CimInstance -ClassName MSFT_Credential -Property @{Username=[string]$UnjoinCredential.UserName; Password=[string]$null} -Namespace root/microsoft/windows/desiredstateconfiguration -ClientOnly

    $returnValue = @{
        Name = $env:COMPUTERNAME
        DomainName = GetComputerDomain
        JoinOU = $JoinOU
        CurrentOU = Get-ComputerOU
        Credential = [ciminstance]$convertToCimCredential
        UnjoinCredential = [ciminstance]$convertToCimUnjoinCredential
        WorkGroupName= (gwmi WIN32_ComputerSystem).WorkGroup
        SystemLocale = (Get-WinSystemLocale).Name
    }

    $returnValue
}

function Set-TargetResource
{
    param
    (
        [parameter(Mandatory)]
        [ValidateLength(1,15)]
        [ValidateScript({$_ -inotmatch'[\/\\:*?"<>|]' })]
        [string] $Name,
    
        [string] $DomainName,

        [string] $JoinOU,
        
        [PSCredential] $Credential,

        [PSCredential] $UnjoinCredential,

        [string] $WorkGroupName,

        [ValidateSet("af", "af-ZA", "am", "am-ET", "ar", "ar-AE", "ar-BH", "ar-DZ", "ar-EG", "ar-IQ", "ar-JO", "ar-KW", "ar-LB", "ar-LY", "ar-MA", "ar-OM", "ar-QA", "ar-SA", "ar-SY", "ar-TN", "ar-YE", "arn", "arn-CL", "as", "as-IN", "az", "az-Cyrl", "az-Cyrl-AZ", "az-Latn", "az-Latn-AZ", "ba", "ba-RU", "be", "be-BY", "bg", "bg-BG", "bn", "bn-BD", "bn-IN", "bo", "bo-CN", "br", "br-FR", "bs", "bs-Cyrl", "bs-Cyrl-BA", "bs-Latn", "bs-Latn-BA", "ca", "ca-ES", "ca-ES-valencia", "chr", "chr-Cher", "chr-Cher-US", "co", "co-FR", "cs", "cs-CZ", "cy", "cy-GB", "da", "da-DK", "de", "de-AT", "de-CH", "de-DE", "de-LI", "de-LU", "dsb", "dsb-DE", "dv", "dv-MV", "el", "el-GR", "en", "en-029", "en-AU", "en-BZ", "en-CA", "en-GB", "en-HK", "en-IE", "en-IN", "en-JM", "en-MY", "en-NZ", "en-PH", "en-SG", "en-TT", "en-US", "en-ZA", "en-ZW", "es", "es-419", "es-AR", "es-BO", "es-CL", "es-CO", "es-CR", "es-DO", "es-EC", "es-ES", "es-GT", "es-HN", "es-MX", "es-NI", "es-PA", "es-PE", "es-PR", "es-PY", "es-SV", "es-US", "es-UY", "es-VE", "et", "et-EE", "eu", "eu-ES", "fa", "fa-IR", "ff", "ff-Latn", "ff-Latn-SN", "fi", "fi-FI", "fil", "fil-PH", "fo", "fo-FO", "fr", "fr-BE", "fr-CA", "fr-CD", "fr-CH", "fr-CI", "fr-CM", "fr-FR", "fr-HT", "fr-LU", "fr-MA", "fr-MC", "fr-ML", "fr-RE", "fr-SN", "fy", "fy-NL", "ga", "ga-IE", "gd", "gd-GB", "gl", "gl-ES", "gn", "gn-PY", "gsw", "gsw-FR", "gu", "gu-IN", "ha", "ha-Latn", "ha-Latn-NG", "haw", "haw-US", "he", "he-IL", "hi", "hi-IN", "hr", "hr-BA", "hr-HR", "hsb", "hsb-DE", "hu", "hu-HU", "hy", "hy-AM", "id", "id-ID", "ig", "ig-NG", "ii", "ii-CN", "is", "is-IS", "it", "it-CH", "it-IT", "iu", "iu-Cans", "iu-Cans-CA", "iu-Latn", "iu-Latn-CA", "ja", "ja-JP", "jv", "jv-Latn", "jv-Latn-ID", "ka", "ka-GE", "kk", "kk-KZ", "kl", "kl-GL", "km", "km-KH", "kn", "kn-IN", "ko", "ko-KR", "kok", "kok-IN", "ku", "ku-Arab", "ku-Arab-IQ", "ky", "ky-KG", "lb", "lb-LU", "lo", "lo-LA", "lt", "lt-LT", "lv", "lv-LV", "mg", "mg-MG", "mi", "mi-NZ", "mk", "mk-MK", "ml", "ml-IN", "mn", "mn-Cyrl", "mn-MN", "mn-Mong", "mn-Mong-CN", "mn-Mong-MN", "moh", "moh-CA", "mr", "mr-IN", "ms", "ms-BN", "ms-MY", "mt", "mt-MT", "my", "my-MM", "nb", "nb-NO", "ne", "ne-IN", "ne-NP", "nl", "nl-BE", "nl-NL", "nn", "nn-NO", "no", "nqo", "nqo-GN", "nso", "nso-ZA", "oc", "oc-FR", "om", "om-ET", "or", "or-IN", "pa", "pa-Arab", "pa-Arab-PK", "pa-IN", "pl", "pl-PL", "prs", "prs-AF", "ps", "ps-AF", "pt", "pt-AO", "pt-BR", "pt-PT", "qut", "qut-GT", "quz", "quz-BO", "quz-EC", "quz-PE", "rm", "rm-CH", "ro", "ro-MD", "ro-RO", "ru", "ru-RU", "rw", "rw-RW", "sa", "sa-IN", "sah", "sah-RU", "sd", "sd-Arab", "sd-Arab-PK", "se", "se-FI", "se-NO", "se-SE", "si", "si-LK", "sk", "sk-SK", "sl", "sl-SI", "sma", "sma-NO", "sma-SE", "smj", "smj-NO", "smj-SE", "smn", "smn-FI", "sms", "sms-FI", "sn", "sn-Latn", "sn-Latn-ZW", "so", "so-SO", "sq", "sq-AL", "sr", "sr-Cyrl", "sr-Cyrl-BA", "sr-Cyrl-CS", "sr-Cyrl-ME", "sr-Cyrl-RS", "sr-Latn", "sr-Latn-BA", "sr-Latn-CS", "sr-Latn-ME", "sr-Latn-RS", "st", "st-ZA", "sv", "sv-FI", "sv-SE", "sw", "sw-KE", "syr", "syr-SY", "ta", "ta-IN", "ta-LK", "te", "te-IN", "tg", "tg-Cyrl", "tg-Cyrl-TJ", "th", "th-TH", "ti", "ti-ER", "ti-ET", "tk", "tk-TM", "tn", "tn-BW", "tn-ZA", "tr", "tr-TR", "ts", "ts-ZA", "tt", "tt-RU", "tzm", "tzm-Latn", "tzm-Latn-DZ", "tzm-Tfng", "tzm-Tfng-MA", "ug", "ug-CN", "uk", "uk-UA", "ur", "ur-IN", "ur-PK", "uz", "uz-Cyrl", "uz-Cyrl-UZ", "uz-Latn", "uz-Latn-UZ", "vi", "vi-VN", "wo", "wo-SN", "xh", "xh-ZA", "yo", "yo-NG", "zgh", "zgh-Tfng", "zgh-Tfng-MA", "zh", "zh-CN", "zh-Hans", "zh-Hant", "zh-HK", "zh-MO", "zh-SG", "zh-TW", "zu", "zu-ZA", "zh-CHS", "zh-CHT")]
        [string] $SystemLocale
    )

    ValidateDomainOrWorkGroup -DomainName $DomainName -WorkGroupName $WorkGroupName
    
    if ($Name -eq 'localhost')
    {
        $Name = $env:COMPUTERNAME
    }

    if($SystemLocale)
    {
        Write-Verbose -Message "Trying to set computer locale to $SystemLocale."
        Set-WinSystemLocale -SystemLocale $SystemLocale
    }

    if ($Credential)
    {
        if ($DomainName)
        {
            if ($DomainName -eq (GetComputerDomain))
            {
                # Rename the computer, but stay joined to the domain.
                Rename-Computer -NewName $Name -DomainCredential $Credential -Force
                Write-Verbose -Message "Renamed computer to '$($Name)'."
            }
            else
            {
                if ($Name -ne $env:COMPUTERNAME)
                {
                    # Rename the comptuer, and join it to the domain.
                    if ($UnjoinCredential)
                    {
                        Add-Computer -DomainName $DomainName -Credential $Credential -NewName $Name -UnjoinDomainCredential $UnjoinCredential -Force
                    }
                    else
                    {
                        if ($JoinOU) {
                            Add-Computer -DomainName $DomainName -Credential $Credential -NewName $Name -OUPath $JoinOU -Force
                        }
                        else {
                            Add-Computer -DomainName $DomainName -Credential $Credential -NewName $Name -Force
                        }
                    }
                    Write-Verbose -Message "Renamed computer to '$($Name)' and added to the domain '$($DomainName)."
                }
                else
                {
                    # Same computer name, and join it to the domain.
                    if ($UnjoinCredential)
                    {
                        Add-Computer -DomainName $DomainName -Credential $Credential -UnjoinDomainCredential $UnjoinCredential -Force
                    }
                    else
                    {
                        if ($JoinOU) {
                            Add-Computer -DomainName $DomainName -Credential $Credential -OUPath $JoinOU -Force
                        }
                        else {
                            Add-Computer -DomainName $DomainName -Credential $Credential -Force
                        }
                    }
                    Write-Verbose -Message "Added computer to domain '$($DomainName)."
                }
            }
        }
        elseif ($WorkGroupName)
        {
            if($WorkGroupName -eq (gwmi win32_computersystem).WorkGroup)
            {
                # Rename the comptuer, but stay in the same workgroup.
                Rename-Computer -NewName $Name
                Write-Verbose -Message "Renamed computer to '$($Name)'."
            }
            else
            {
                if ($Name -ne $env:COMPUTERNAME)
                {
                    # Rename the computer, and join it to the workgroup.
                    Add-Computer -NewName $Name -Credential $Credential -WorkgroupName $WorkGroupName -Force
                    Write-Verbose -Message "Renamed computer to '$($Name)' and addded to workgroup '$($WorkGroupName)'."
                }
                else
                {
                    # Same computer name, and join it to the workgroup.
                    Add-Computer -WorkGroupName $WorkGroupName -Credential $Credential -Force
                    Write-Verbose -Message "Added computer to workgroup '$($WorkGroupName)'."
                }
            }
        }
        elseif($Name -ne $env:COMPUTERNAME)
        {
            if (GetComputerDomain)
            {
                Rename-Computer -NewName $Name -DomainCredential $Credential -Force
                Write-Verbose -Message "Renamed computer to '$($Name)'."
            }
            else
            {
                Rename-Computer -NewName $Name -Force
                Write-Verbose -Message "Renamed computer to '$($Name)'."
            }
        }
    }
    else # No Credentials
    {
        if ($DomainName)
        {
            throw "Missing domain join credentials."
        }
        if ($WorkGroupName)
        {
            
            if ($WorkGroupName -eq (Get-WmiObject win32_computersystem).Workgroup)
            {
                # Same workgroup, new computer name
                Rename-Computer -NewName $Name -force
                Write-Verbose -Message "Renamed computer to '$($Name)'."
            }
            else
            {
                if ($name -ne $env:COMPUTERNAME)
                {
                    # New workgroup, new computer name
                    Add-Computer -WorkgroupName $WorkGroupName -NewName $Name
                    Write-Verbose -Message "Renamed computer to '$($Name)' and added to workgroup '$($WorkGroupName)'."
                }
                else
                {
                    # New workgroup, same computer name
                    Add-Computer -WorkgroupName $WorkGroupName
                    Write-Verbose -Message "Added computer to workgroup '$($WorkGroupName)'."
                }
            }
        }
        else
        {
            if ($Name -ne $env:COMPUTERNAME)
            {
                Rename-Computer -NewName $Name
                Write-Verbose -Message "Renamed computer to '$($Name)'."
            }
        }
    }

    # Request a reboot from DSC
    $global:DSCMachineStatus = 1
}

function Test-TargetResource
{
    [OutputType([System.Boolean])]
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory)]
        [ValidateLength(1,15)]
        [ValidateScript({$_ -inotmatch'[\/\\:*?"<>|]' })]
        [string] $Name,

        [string] $JoinOU,
        
        [PSCredential]$Credential,

        [PSCredential]$UnjoinCredential,
        
        [string] $DomainName,

        [string] $WorkGroupName,

        [ValidateSet("af", "af-ZA", "am", "am-ET", "ar", "ar-AE", "ar-BH", "ar-DZ", "ar-EG", "ar-IQ", "ar-JO", "ar-KW", "ar-LB", "ar-LY", "ar-MA", "ar-OM", "ar-QA", "ar-SA", "ar-SY", "ar-TN", "ar-YE", "arn", "arn-CL", "as", "as-IN", "az", "az-Cyrl", "az-Cyrl-AZ", "az-Latn", "az-Latn-AZ", "ba", "ba-RU", "be", "be-BY", "bg", "bg-BG", "bn", "bn-BD", "bn-IN", "bo", "bo-CN", "br", "br-FR", "bs", "bs-Cyrl", "bs-Cyrl-BA", "bs-Latn", "bs-Latn-BA", "ca", "ca-ES", "ca-ES-valencia", "chr", "chr-Cher", "chr-Cher-US", "co", "co-FR", "cs", "cs-CZ", "cy", "cy-GB", "da", "da-DK", "de", "de-AT", "de-CH", "de-DE", "de-LI", "de-LU", "dsb", "dsb-DE", "dv", "dv-MV", "el", "el-GR", "en", "en-029", "en-AU", "en-BZ", "en-CA", "en-GB", "en-HK", "en-IE", "en-IN", "en-JM", "en-MY", "en-NZ", "en-PH", "en-SG", "en-TT", "en-US", "en-ZA", "en-ZW", "es", "es-419", "es-AR", "es-BO", "es-CL", "es-CO", "es-CR", "es-DO", "es-EC", "es-ES", "es-GT", "es-HN", "es-MX", "es-NI", "es-PA", "es-PE", "es-PR", "es-PY", "es-SV", "es-US", "es-UY", "es-VE", "et", "et-EE", "eu", "eu-ES", "fa", "fa-IR", "ff", "ff-Latn", "ff-Latn-SN", "fi", "fi-FI", "fil", "fil-PH", "fo", "fo-FO", "fr", "fr-BE", "fr-CA", "fr-CD", "fr-CH", "fr-CI", "fr-CM", "fr-FR", "fr-HT", "fr-LU", "fr-MA", "fr-MC", "fr-ML", "fr-RE", "fr-SN", "fy", "fy-NL", "ga", "ga-IE", "gd", "gd-GB", "gl", "gl-ES", "gn", "gn-PY", "gsw", "gsw-FR", "gu", "gu-IN", "ha", "ha-Latn", "ha-Latn-NG", "haw", "haw-US", "he", "he-IL", "hi", "hi-IN", "hr", "hr-BA", "hr-HR", "hsb", "hsb-DE", "hu", "hu-HU", "hy", "hy-AM", "id", "id-ID", "ig", "ig-NG", "ii", "ii-CN", "is", "is-IS", "it", "it-CH", "it-IT", "iu", "iu-Cans", "iu-Cans-CA", "iu-Latn", "iu-Latn-CA", "ja", "ja-JP", "jv", "jv-Latn", "jv-Latn-ID", "ka", "ka-GE", "kk", "kk-KZ", "kl", "kl-GL", "km", "km-KH", "kn", "kn-IN", "ko", "ko-KR", "kok", "kok-IN", "ku", "ku-Arab", "ku-Arab-IQ", "ky", "ky-KG", "lb", "lb-LU", "lo", "lo-LA", "lt", "lt-LT", "lv", "lv-LV", "mg", "mg-MG", "mi", "mi-NZ", "mk", "mk-MK", "ml", "ml-IN", "mn", "mn-Cyrl", "mn-MN", "mn-Mong", "mn-Mong-CN", "mn-Mong-MN", "moh", "moh-CA", "mr", "mr-IN", "ms", "ms-BN", "ms-MY", "mt", "mt-MT", "my", "my-MM", "nb", "nb-NO", "ne", "ne-IN", "ne-NP", "nl", "nl-BE", "nl-NL", "nn", "nn-NO", "no", "nqo", "nqo-GN", "nso", "nso-ZA", "oc", "oc-FR", "om", "om-ET", "or", "or-IN", "pa", "pa-Arab", "pa-Arab-PK", "pa-IN", "pl", "pl-PL", "prs", "prs-AF", "ps", "ps-AF", "pt", "pt-AO", "pt-BR", "pt-PT", "qut", "qut-GT", "quz", "quz-BO", "quz-EC", "quz-PE", "rm", "rm-CH", "ro", "ro-MD", "ro-RO", "ru", "ru-RU", "rw", "rw-RW", "sa", "sa-IN", "sah", "sah-RU", "sd", "sd-Arab", "sd-Arab-PK", "se", "se-FI", "se-NO", "se-SE", "si", "si-LK", "sk", "sk-SK", "sl", "sl-SI", "sma", "sma-NO", "sma-SE", "smj", "smj-NO", "smj-SE", "smn", "smn-FI", "sms", "sms-FI", "sn", "sn-Latn", "sn-Latn-ZW", "so", "so-SO", "sq", "sq-AL", "sr", "sr-Cyrl", "sr-Cyrl-BA", "sr-Cyrl-CS", "sr-Cyrl-ME", "sr-Cyrl-RS", "sr-Latn", "sr-Latn-BA", "sr-Latn-CS", "sr-Latn-ME", "sr-Latn-RS", "st", "st-ZA", "sv", "sv-FI", "sv-SE", "sw", "sw-KE", "syr", "syr-SY", "ta", "ta-IN", "ta-LK", "te", "te-IN", "tg", "tg-Cyrl", "tg-Cyrl-TJ", "th", "th-TH", "ti", "ti-ER", "ti-ET", "tk", "tk-TM", "tn", "tn-BW", "tn-ZA", "tr", "tr-TR", "ts", "ts-ZA", "tt", "tt-RU", "tzm", "tzm-Latn", "tzm-Latn-DZ", "tzm-Tfng", "tzm-Tfng-MA", "ug", "ug-CN", "uk", "uk-UA", "ur", "ur-IN", "ur-PK", "uz", "uz-Cyrl", "uz-Cyrl-UZ", "uz-Latn", "uz-Latn-UZ", "vi", "vi-VN", "wo", "wo-SN", "xh", "xh-ZA", "yo", "yo-NG", "zgh", "zgh-Tfng", "zgh-Tfng-MA", "zh", "zh-CN", "zh-Hans", "zh-Hant", "zh-HK", "zh-MO", "zh-SG", "zh-TW", "zu", "zu-ZA", "zh-CHS", "zh-CHT")]
        [string] $SystemLocale
    )
    
    Write-Verbose -Message "Validate desired Name is a valid name"
    
    Write-Verbose -Message "Checking if computer name is correct"
    if (($Name -ne 'localhost') -and ($Name -ne $env:COMPUTERNAME)) {return $false}

    if($SystemLocale)
    {
        Write-Verbose "Validating Locale Settings are correct"

        if( -not (Test-SystemLocale -SystemLocale $SystemLocale) )
        {
            throw "Invalid Locale passed to xComputer resource"
        }

        if((Get-WinSystemLocale).Name -ne $SystemLocale)
        {
            return $false
        }
    }

    ValidateDomainOrWorkGroup -DomainName $DomainName -WorkGroupName $WorkGroupName

    if($DomainName)
    {
        if(!($Credential))
        {
            throw "Need to specify credentials with domain"
        }
        
        try
        {
            Write-Verbose "Checking if the machine is a member of $DomainName."
            return ($DomainName.ToLower() -eq (GetComputerDomain).ToLower())
        }
        catch
        {
           Write-Verbose 'The machine is not a domain member.'
           return $false
        }
    }
    elseif($WorkGroupName)
    {
        Write-Verbose -Message "Checking if workgroup name is $WorkGroupName"
        return ($WorkGroupName -eq (gwmi WIN32_ComputerSystem).WorkGroup)
    }
    else
    {
        ## No Domain or Workgroup specified and computer name is correct
        return $true;
    }
}

function ValidateDomainOrWorkGroup($DomainName, $WorkGroupName)
{
    if ($DomainName -and $WorkGroupName)
    {
        throw "Only DomainName or WorkGroupName can be specified at once."
    }
}

function GetComputerDomain
{
  try
    {
        return ([System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain()).Name
    }
    catch [System.Management.Automation.MethodInvocationException]
    {
        Write-Debug 'This machine is not a domain member.'
    }
}

function Get-ComputerOU
{
    $ou = $null

    if (GetComputerDomain)
    {
        $dn = $null
        $dn = ([adsisearcher]"(&(objectCategory=computer)(objectClass=computer)(cn=$env:COMPUTERNAME))").FindOne().Properties.distinguishedname
        $ou = $dn -replace '^(CN=.*?(?<=,))', ''
    }

    return $ou
}

function Test-SystemLocale
{
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$SystemLocale
    )

    $Cultures = [CultureInfo]::GetCultures("AllCultures").Name
    return ($Cultures -contains $SystemLocale)
}

Export-ModuleMember -Function *-TargetResource
