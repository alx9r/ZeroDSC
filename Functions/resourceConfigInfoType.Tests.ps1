Import-Module ZeroDSC -Force

Describe New-RawResourceConfigInfo {
    It 'creates new object' {
        $r = New-RawResourceConfigInfo
        $r | Should not beNullOrEmpty
    }
    It 'the object type is RawResourceConfigInfo' {
        Set-Alias ResourceName New-RawResourceConfigInfo
        $r = Invoke-Command {
            ResourceName
        }
        $r.GetType() | Should be 'RawResourceConfigInfo'
    }
    It 'correctly populates InvocationInfo' {
        $r = New-RawResourceConfigInfo
        $r.InvocationInfo.Line | Should match '\$r = New-RawResourceConfigInfo'
    }
    It 'correctly populates ConfigName' {
        $r = New-RawResourceConfigInfo -ConfigName 'ConfigName'
        $r.ConfigName | Should be 'ConfigName'
    }
    It 'correctly populates Params' {
        $r = New-RawResourceConfigInfo -Params @{ p='value' }
        $r.Params.p | Should be 'value'
    }
}
Describe ConvertTo-ResourceConfigInfo {
    It 'creates exactly one new object' {
        $r = New-RawResourceConfigInfo ConfigName |
            ConvertTo-ResourceConfigInfo
        $r | Should not beNullOrEmpty
        $r.Count | Should be 1
    }
    It 'the object type is ResourceConfigInfo...' {
        Set-Alias ResourceName New-RawResourceConfigInfo
        $r = Invoke-Command {
            ResourceName ConfigName |
                ConvertTo-ResourceConfigInfo
        } 
        $r.GetType() | Should be 'ResourceConfigInfo'
    }
    It '...except when the resource name is Aggregate' {
        $r = Invoke-Command {
            Aggregate ConfigName
        } |
            ConvertTo-ResourceConfigInfo
        $r.GetType() | Should be 'AggregateConfigInfo'
    }
    It 'correctly populates the ConfigName property' {
        $r = New-RawResourceConfigInfo ConfigName |
            ConvertTo-ResourceConfigInfo
        $r.ConfigName | Should be ConfigName
    }
    It 'correctly extracts ResourceName from InvocationInfo' {
        $r = New-RawResourceConfigInfo ConfigName |
            ConvertTo-ResourceConfigInfo
        $r.ResourceName | Should be 'New-RawResourceConfigInfo'        
    }
    It '...even when an alias is used' {
        Set-Alias ResourceName New-RawResourceConfigInfo
        $r = Invoke-Command {
            ResourceName ConfigName
        } |
            ConvertTo-ResourceConfigInfo
        $r.ResourceName | Should be 'ResourceName'
    }
    It 'correctly populates the Params property' {
        $r = New-RawResourceConfigInfo ConfigName @{p1 = 'p'} |
            ConvertTo-ResourceConfigInfo
        $r.Params.p1 | Should be 'p'
    }
    It '.GetConfigPath() works' {
        $r = New-RawResourceConfigInfo ConfigName |
            ConvertTo-ResourceConfigInfo
        $r.GetConfigPath() | Should be '[New-RawResourceConfigInfo]ConfigName'
    }
    Context 'bad ResourceName' {
        $h = @{}
        It 'throws correct exception type' {
            Set-Alias "bad>name" New-RawResourceConfigInfo
            try
            {
                bad>name ConfigName |
                    ConvertTo-ResourceConfigInfo
            }
            catch [FormatException]
            {
                $threw = $true
                $h.Exception = $_
            }
            $threw | Should be $true
        }
        It 'the exception shows the filename of the offending ResourceName' {
            $h.Exception.ToString() | Should match ($PSCommandPath | Split-Path -Leaf)
        }
        It 'the exception contains an informative message' {
            $h.Exception.ToString() | Should match 'not a valid ResourceName'
        }
    }
    Context 'bad ConfigName' {
        $h = @{}
        It 'throws correct exception type' {
            try
            {
                New-RawResourceConfigInfo 'Config[Name' |
                    ConvertTo-ResourceConfigInfo
            }
            catch [FormatException]
            {
                $threw = $true
                $h.Exception = $_
            }
            $threw | Should be $true
        }
        It 'the exception shows the filename of the offending ConfigName' {
            $h.Exception.ToString() | Should match ($PSCommandPath | Split-Path -Leaf)
        }
        It 'the exception contains an informative message' {
            $h.Exception.ToString() | Should match 'not a valid ConfigName'
        }
    }
    Context 'bad Params' {
        It 'throws correct exception type' {}
        It 'the exception show the filename of the offending parameter' {}
        It 'the exception contains an informative message' {}
    }
}
Describe Get-ResourceNameFromInvocationLine {
    Context 'acceptable lines' {
        foreach ( $line in @(
                'ResourceName ConfigName @{'
                ' ResourceName ConfigName @{'
                "`tResourceName ConfigName @{"
                '    ResourceName ConfigName @{'
                'ResourceName ConfigName @{ '
                "ResourceName ConfigName @{`t"
                "ResourceName`t ConfigName @{"
                # 'ResourceName`' regex and backticks seem to have inconsistent behavior
                'Verb-Noun'
                '$r = ResourceName ConfigName @{'
                '$r = Verb-Noun ConfigName @{'
                '$r = ResourceName -ConfigName ConfigName -Params @{}'
                '$r = ResourceName ConfigName $params'
                '$(a.''b'') = ResourceName ConfigName $params'
            ) 
        )
        {
            It $line {
                $r = $line | Get-ResourceNameFromInvocationLine
                $r -in 'ResourceName','Verb-Noun' | Should be $true
            }
        }
    }
}