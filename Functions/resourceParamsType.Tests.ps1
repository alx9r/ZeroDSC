Import-Module ZeroDsc -Force

Describe 'ResourceParams' {
    InModuleScope ZeroDsc {
        It 'default constructor produces object' {
            $o = [ResourceParams]::new()
            $o.GetType() | Should be 'ResourceParams'
        }
        Context 'PSRunAsCredential' {
            It 'accepts assignment of a credential' {
                $password = 'bogus' | ConvertTo-SecureString -AsPlainText -Force
                $cred = New-Object pscredential('bogus', $password)
                $o = [ResourceParams]::new()
                $o.PSRunAsCredential = $cred
                $o.PSRunAsCredential.UserName | Should be 'bogus'
            }
            It 'does not accept assignment of strings' {
                $o = [ResourceParams]::new()
                { $o.PSRunAsCredential = 'some string' } |
                    Should throw 'Cannot convert'
            }
        }
        Context 'ComputerName' {
            It 'accepts assigment of valid domain name' {
                $o = [ResourceParams]::new()
                $o.ComputerName = 'computer.domain.com'
                $o.ComputerName | Should be 'computer.domain.com'
            }
            It 'does not accept assignment of invalid domain names' {
                $o = [ResourceParams]::new()
                { $o.ComputerName = '-computer.domain.com' } |
                    Should throw '-computer.domain.com is not a valid domain name'
            }
        }
        Context 'DependsOn' {
            It 'accepts assignment of valid ConfigPath' {
                $o = [ResourceParams]::new()
                $o.DependsOn = '[ResourceName]ConfigName'
                $o.DependsOn | Should be '[ResourceName]ConfigName'
            }
            It 'accepts assignment of array of valid ConfigPaths' {
                $o = [ResourceParams]::new()
                $o.DependsOn = '[ResourceName1]ConfigName1','[ResourceName2]ConfigName2'
                $o.DependsOn[0] | Should be '[ResourceName1]ConfigName1'
                $o.DependsOn[1] | Should be '[ResourceName2]ConfigName2'
            }
            It 'does not accept assignment of invalid ConfigPath' {
                $o = [ResourceParams]::new()
                { $o.DependsOn = '[Resource[Name]ConfigName' } |
                    Should throw 'Resource[Name is not a valid ResourceName'
            }
        }
        Context 'Params' {
            It 'is a hashtable' {
                $o = [ResourceParams]::new()
                $o.Params | Should beOfType ([hashtable])
            }
        }
    }
}
Describe 'AggregateParams' {
    InModuleScope ZeroDsc {
        Context 'Type' {
            It 'accepts assignment of a valid type name' {
                $o = [AggregateParams]::new()
                $o.Type = 'Count'
            }
            It 'does not accept assignment of invalid type name' {
                $o = [AggregateParams]::new()
                { $o.Type = 'invalid' } |
                    Should throw 'not a valid aggregate type'
            }
        }
        Context 'Test' {
            It 'accepts assignment of a valid test' {
                $o = [AggregateParams]::new()
                $o.Test = '-gt 0'
            }
            It 'does not accept assignment of invalid test' {
                $o = [AggregateParams]::new()
                { $o.Test = 'invalid' } |
                    Should throw 'not a valid aggregate test'
            }
        }
    }
}