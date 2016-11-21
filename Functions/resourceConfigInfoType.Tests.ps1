Import-Module ZeroDsc -Force -Args ExportAll

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
    It 'correctly populates the InvocationInfo property' {
        $raw = New-RawResourceConfigInfo ConfigName
        $r = $raw | ConvertTo-ResourceConfigInfo
        $r.InvocationInfo | Should be $raw.InvocationInfo
    }
    It '.GetConfigPath() works' {
        $r = New-RawResourceConfigInfo ConfigName |
            ConvertTo-ResourceConfigInfo
        $r.GetConfigPath() | Should be '[New-RawResourceConfigInfo]ConfigName'
    }
    InModuleScope ZeroDsc {    
        foreach ( $typeName in 'ResourceParams','AggregateParams' )
        {
            Context "Params [$typeName]" {
                $object = New-Object $typeName
                Mock ConvertTo-ResourceParams -Verifiable {$object}
                It 'it correctly assigns result of ConvertTo-ResourceParams to Params' {
                    $r = New-RawResourceConfigInfo ConfigName @{p=1} |
                        ConvertTo-ResourceConfigInfo
                    $r.Params | Should be $object
                }
                It 'correctly invokes ConvertTo-ResourceParams' {
                    Assert-MockCalled ConvertTo-ResourceParams -Times 1 {
                        $ResourceName -eq 'ConfigName' -and
                        $Params.p -eq 1
                    }
                }
            }
        }
    }
    Context 'bad ResourceName' {
        $h = @{}
        It 'throws correct exception type' {
            Set-Alias "bad>name" New-RawResourceConfigInfo
            try
            {
                $h.CallSite = & {$MyInvocation}
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
        It 'the exception shows the filename of the offending call' {
            $h.Exception.ToString() | Should match ($PSCommandPath | Split-Path -Leaf)
        }
        It 'the exception shows the line number of the offending call' {
            $h.Exception.ToString() | Should match ":$($h.CallSite.ScriptLineNumber+1)"
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
                $h.CallSite = & {$MyInvocation}
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
        It 'the exception shows the filename of the offending call' {
            $h.Exception.ToString() | Should match ($PSCommandPath | Split-Path -Leaf)
        }
        It 'the exception shows the line number of the offending call' {
            $h.Exception.ToString() | Should match ":$($h.CallSite.ScriptLineNumber+1)"
        }
        It 'the exception contains an informative message' {
            $h.Exception.ToString() | Should match 'not a valid ConfigName'
        }
    }
    Context 'bad Params' {
        InModuleScope ZeroDsc {
            $h = @{}
            Mock ConvertTo-ResourceParams {throw 'mock exception'}
            It 'throws correct exception type' {
                try
                {
                    $h.CallSite = & {$MyInvocation}
                    New-RawResourceConfigInfo 'ConfigName' |
                        ConvertTo-ResourceConfigInfo
                }
                catch [FormatException]
                {
                    $threw = $true
                    $h.Exception =$_
                }
                $threw | Should be $true
            }
            It 'the exception show the filename of the offending parameter' {
                $h.Exception.ToString() | Should match ($PSCommandPath | Split-Path -Leaf)
            }
            It 'the exception shows the line number of the offending call' {
                $h.Exception.ToString() | Should match ":$($h.CallSite.ScriptLineNumber+1)"
            }
            It 'the exception contains an informative message' {
                $h.Exception.ToString() | Should match 'mock exception'
            }
        }
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