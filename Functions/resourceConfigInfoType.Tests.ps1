Import-Module ZeroDSC -Force

Describe New-ResourceConfigInfo {
    It 'creates new object' {
        $r = New-ResourceConfigInfo
        $r | Should not beNullOrEmpty
    }
    It 'correctly extracts ResourceName from invocation line...' {
        $r = Invoke-Command {
            New-ResourceConfigInfo
        }
        $r.ResourceName | Should be New-ResourceConfigInfo
    }
    It '...even when an alias is used' {
        Set-Alias ResourceName New-ResourceConfigInfo
        $r = Invoke-Command {
            ResourceName
        }
        $r.ResourceName | Should be 'ResourceName'
    }
    It 'the object type is ResourceConfigInfo...' {
        Set-Alias ResourceName New-ResourceConfigInfo
        $r = Invoke-Command {
            ResourceName
        }
        $r.GetType() | Should be 'ResourceConfigInfo'
    }
    It '...except when the resource name is Aggregate' {
        $r = Invoke-Command {
            Aggregate
        }
        $r.GetType() | Should be 'AggregateConfigInfo'
    }
    It 'correctly populates the ConfigName property' {
        $r = New-ResourceConfigInfo ConfigName
        $r.ConfigName | Should be ConfigName
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
                'ResourceName`'
            )
        )
        {
            It $line {
                $r = $line | Get-ResourceNameFromInvocationLine
                $r | Should be 'ResourceName'
            }
        }
    }
}