Import-Module ZeroDSC -Force

Describe New-ResourceConfigInfo {
    It 'creates new object' {
        $r = New-ResourceConfigInfo ConfigName
        $r | Should not beNullOrEmpty
    }
    It 'correctly extracts ResourceName from invocation line...' {
        $r = Invoke-Command {
            New-ResourceConfigInfo ConfigName
        }
        $r.ResourceName | Should be New-ResourceConfigInfo
    }
    It '...even when an alias is used' {
        Set-Alias ResourceName New-ResourceConfigInfo
        $r = Invoke-Command {
            ResourceName ConfigName
        }
        $r.ResourceName | Should be 'ResourceName'
    }
    It 'the object type is ResourceConfigInfo...' {
        Set-Alias ResourceName New-ResourceConfigInfo
        $r = Invoke-Command {
            ResourceName ConfigName
        }
        $r.GetType() | Should be 'ResourceConfigInfo'
    }
    It '...except when the resource name is Aggregate' {
        $r = Invoke-Command {
            Aggregate ConfigName
        }
        $r.GetType() | Should be 'AggregateConfigInfo'
    }
    It 'correctly populates the ConfigName property' {
        $r = New-ResourceConfigInfo ConfigName
        $r.ConfigName | Should be ConfigName
    }
    It '.GetConfigPath() works' {
        $r = New-ResourceConfigInfo ConfigName
        $r.GetConfigPath() | Should be '[New-ResourceConfigInfo]ConfigName'
    }
    It 'throws on bad ResourceName' {
        Set-Alias "bad>name" New-ResourceConfigInfo
        { bad>name ConfigName } |
            Should throw 'not a valid ResourceName'
    }
    It 'throws on bad ConfigName property' {
        { 
            New-ResourceConfigInfo 'Config[Name' 
        } |
            Should throw 'not a valid ConfigName'
    }
    It 'correctly populates the Params property' {
        $r = New-ResourceConfigInfo ConfigName @{p1 = 'p'}
        $r.Params.p1 | Should be 'p'
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