Import-Module ZeroDsc -Force -Args ExportAll

Describe 'Test Environment' {
    It 'add the test stubs to PSModulePath' {
        . "$($PSCommandPath | Split-Path -Parent)\..\Add-StubsToModulePath.ps1"
    }
}

$records = @{}
Describe Test-DependenciesMet {
    Context 'resource nodes' {
        It 'create test dictionary' {
            $records.Nodes = New-RawConfigDocument Name {
                Get-DscResource StubResource5 | Import-DscResource
                StubResource5 'a' @{ Mode = 'Normal' }
                StubResource5 'b' @{
                    Mode = 'Normal'
                    DependsOn = '[StubResource5]a'
                }
                StubResource5 'c' @{
                    Mode = 'Normal'
                    DependsOn = '[StubResource5]a','[StubResource5]b'
                }
            } |
                ConvertTo-ConfigDocument |
                % Resources |
                New-ProgressNodes
        }
        It 'returns exactly one boolean' {
            $r = '[StubResource5]a' | Test-DependenciesMet $records.Nodes
            $r | Should beOfType ([bool])
            $r.Count | Should be 1
        }
        It 'returns true for no DependsOn' {
            $r = '[StubResource5]a' | Test-DependenciesMet $records.Nodes
            $r | Should be $true
        }
        It 'returns false for incomplete single parent' {
            $r = '[StubResource5]b' | Test-DependenciesMet $records.Nodes
            $r | Should be $false
        }
        It 'returns true for complete single parent' {
            $records.Nodes.'[StubResource5]a'.Progress = 'Complete'
            $r = '[StubResource5]b' | Test-DependenciesMet $records.Nodes
            $r | Should be $true
        }
        It 'returns false for one parent complete another parent incomplete' {
            $r = '[StubResource5]c' | Test-DependenciesMet $records.Nodes
            $r | Should be $false
        }
        It 'returns true for two complete parents' {
            $records.Nodes.'[StubResource5]b'.Progress = 'Complete'
            $r = '[StubResource5]c' | Test-DependenciesMet $records.Nodes
            $r | Should be $true
        }
    }
    Context 'aggregate nodes' {
        It 'returns exactly one boolean' {}
    }
    Context 'aggregate nodes (any)' {
        It 'returns false for parent aggregate when all grandparents incomplete' {}
        It 'returns true for parent aggregate when one grandparent complete' {}
    }
    Context 'aggregate nodes (all)' {
        It 'returns false for parent aggregate when one grandparent incomplete' {}
        It 'returns true for parent aggregate when all grandparents complete' {}
    }
    Context 'aggregate nodes (two generations)' {
        It 'returns false when great-grandparent incomplete' {}
        It 'returns true when all great-grandparents are incomplete' {}
    }
}
