Import-Module ZeroDsc -Force

InModuleScope ZeroDsc {

Describe Test-ValidConfigPath {
    Context 'success' {
        Mock Get-ConfigPathPart -Verifiable { $PartName }
        Mock Test-ValidConfigName -Verifiable { $true }
        Mock Test-ValidResourceName -Verifiable { $true }
        It 'returns true' {
            $r = '[ResourceName]ConfigName' | Test-ValidConfigPath -ErrorAction Stop
            $r | Should be $true
        }
        It 'correctly invokes Get-ConfigPathPart ResourceName' {
            Assert-MockCalled Get-ConfigPathPart -ParameterFilter {
                $String -eq '[ResourceName]ConfigName' -and
                $PartName -eq 'ResourceName'
            }
        }
        It 'correctly invokes Get-ConfigPathPart ConfigName' {
            Assert-MockCalled Get-ConfigPathPart -ParameterFilter {
                $String -eq '[ResourceName]ConfigName' -and
                $PartName -eq 'ConfigName'
            }
        }
        It 'correctly invokes Test-ValidConfigName' {
            Assert-MockCalled Test-ValidConfigName -ParameterFilter {
                $String -eq 'ConfigName'
            }
        }
        It 'correctly invokes Test-ValidResourceName' {
            Assert-MockCalled Test-ValidResourceName -ParameterFilter {
                $String -eq 'ResourceName'
            }
        }
        It 'cascades ErrorAction Stop' {
            Assert-MockCalled Test-ValidResourceName -ParameterFilter {
                $ErrorActionPreference -eq 'Stop'
            }
            Assert-MockCalled Test-ValidConfigName -ParameterFilter {
                $ErrorActionPreference -eq 'Stop'
            }
        }
    }
    Context 'fail ResourceName' {
        Mock Get-ConfigPathPart { $PartName }
        Mock Test-ValidConfigName { $true }
        Mock Test-ValidResourceName { $false }
        It 'returns false' {
            $r = 'string' | Test-ValidConfigPath
            $r | Should be $false
        }
    }
    Context 'fail ConfigName' {
        Mock Get-ConfigPathPart { $PartName }
        Mock Test-ValidConfigName { $false }
        Mock Test-ValidResourceName { $true }
        It 'returns false' {
            $r = 'string' | Test-ValidConfigPath
            $r | Should be $false
        }
    }
    It 'returns true for empty string' {
        $r = [string]::Empty | Test-ValidConfigPath
        $r | Should be $true
    }
    It 'returns true for $null' {
        $r = $null | Test-ValidConfigPath
        $r | Should be $true
    }
}
Describe 'Test-ValidConfigPath Integration' {
    It 'returns true for [ResourceName]ConfigName' {
        $r = '[ResourceName]ConfigName' | Test-ValidConfigPath
        $r | Should be $true
    }
}
Describe ConvertTo-ConfigPath {
    It "correctly composes '[ResourceName]ConfigName'" {
        $r = ConvertTo-ConfigPath ResourceName ConfigName
        $r | Should be '[ResourceName]ConfigName'
    }
}
Describe Get-ConfigPathPart {
    It 'gets ResourceName' {
        $r = '[ResourceName]ConfigName' | Get-ConfigPathPart ResourceName
        $r | Should be 'ResourceName'
    }
    It 'gets ConfigName' {
        $r = '[ResourceName]ConfigName' | Get-ConfigPathPart ConfigName
        $r | Should be 'ConfigName'
    }
    It 'gets malformed ResourceName' {
        $r = '[Re[sourceName]ConfigName' | Get-ConfigPathPart ResourceName
        $r | Should be 'Re[sourceName'
    }
}
Describe Test-ValidConfigName {
    It 'throws on Config[Name' {
        { 'Config[Name' | Test-ValidConfigName -ea Stop } |
            Should throw 'Config[Name'
    }
    foreach ( $string in @(
            'ConfigName'
            'Config-Name'
            'Config_Name'
        )
    )
    {
        It "return true on $string" {
            $r = $string | Test-ValidConfigName
            $r | Should be $true
        }
    }
    It 'throws on empty string' {
        { [string]::Empty | Test-ValidConfigName -ea Stop } |
            Should throw 'Empty String'
    }
    It 'return false on null' {
        { [string]::Empty | Test-ValidConfigName -ea Stop } |
            Should throw 'Null'
    }
}
Describe Test-ValidResourceName {
    It 'throws on Resource[Name' {
        { 'Resource[Name' | Test-ValidResourceName -ea Stop } |
            Should throw 'Resource[Name'
    }
    foreach ( $string in @(
            'ResourceName'
            'Resource-Name'
            'Resource_Name'
        )
    )
    {
        It "return true on $string" {
            $r = $string | Test-ValidResourceName
            $r | Should be $true
        }
    }
    It 'throws on empty string' {
        { [string]::Empty | Test-ValidResourceName -ea Stop } |
            Should throw 'Empty String'
    }
    It 'return false on null' {
        { [string]::Empty | Test-ValidResourceName -ea Stop } |
            Should throw 'Null'
    }
}
}
