Import-Module ZeroDSC -Force

. "$($PSCommandPath | Split-Path -Parent)\..\Add-StubsToModulePath.ps1"
$resourceModuleStubPath = "$($PSCommandPath | Split-Path -Parent)\..\Resources\StubResourceModule1\StubResourceModule1.psd1"

Describe 'Import-ZeroDscModule using mocks' {
    InModuleScope ZeroDSC {
        Context 'happy path' {
            Mock Import-Module -Verifiable {
                if ( $Name -eq 'param' )
                {
                    New-Object psobject -Property @{
                        NestedModules = 'NestedModule1','NestedModule2'
                        ModuleBase = 'path'
                        Name = 'param'
                    }
                }
            }
            Mock Remove-Module -Verfiable {}
            Mock Get-ChildItem -Verifiable {
                'ResourceName1','ResourceName2'
            }
            Mock Get-DscResource -Verifiable {
                New-Object psobject -Property @{ Path = 'ResourcePath1'; FriendlyName = 'ResourceFriendlyName1' }
                New-Object psobject -Property @{ Path = 'ResourcePath2'; FriendlyName = 'ResourceFriendlyName2' }
            }
            Mock Assert-ValidZeroDscResource -Verifiable {}
            Mock Set-DscResourceConfigFunction -Verifiable {}
            It 'returns nothing' {
                $r = Import-ZeroDscModule param
                $r | Should beNullOrEmpty
            }
            It 'correctly invokes Import-Module for module named by parameter' {
                Assert-MockCalled Import-Module -Times 1 -ParameterFilter {
                    $Name -eq 'param'
                }
            }
            It 'correctly invokes Import-Module for first nested module' {
                Assert-MockCalled Import-Module -Times 1 -ParameterFilter {
                    $Name -eq 'NestedModule1'
                }
            }
            It 'correctly invokes Import-Module for second nested module' {
                Assert-MockCalled Import-Module -Times 1 -ParameterFilter {
                    $Name -eq 'NestedModule2'
                }
            }
            It 'correctly invokes Get-ChildItem to discover DSC Resources' {
                Assert-MockCalled Get-ChildItem -Times 1 -ParameterFilter {
                    $Path -eq 'path\DSCResources'
                }
            }
            It 'correctly gets DSC Resource for first resourse' {
                Assert-MockCalled Get-DscResource -Times 1 -ParameterFilter {
                    $Name -eq 'ResourceName1'
                }
            }
            It 'correctly gets DSC Resource for second resourse' {
                Assert-MockCalled Get-DscResource -Times 1 -ParameterFilter {
                    $Name -eq 'ResourceName2'
                }
            }
            It 'correctly imports module for first resource' {
                Assert-MockCalled Import-Module -Times 1 -ParameterFilter {
                    $Name -eq 'ResourcePath1'
                }
            }
            It 'correctly imports module for second resource' {
                Assert-MockCalled Import-Module -Times 1 -ParameterFilter {
                    $Name -eq 'ResourcePath2'
                }
            }
            It 'correctly invokes Assert-ValidZeroDscResource for first resource' {
                Assert-MockCalled Assert-ValidZeroDscResource -Times 1 -ParameterFilter {
                    $Name -eq 'ResourceFriendlyName1'
                }
            }
            It 'correctly invokes Assert-ValidZeroDscResource for second resource' {
                Assert-MockCalled Assert-ValidZeroDscResource -Times 1 -ParameterFilter {
                    $Name -eq 'ResourceFriendlyName2'
                }
            }
            It 'correctly invokes Set-DscResourceFunctions for first resource' {
                Assert-MockCalled Set-DscResourceConfigFunction -Times 1 -ParameterFilter {
                    $Name -eq 'ResourceFriendlyName1'
                }
            }
            It 'correctly invokes Set-DscResourceFunctions for second resource' {
                Assert-MockCalled Set-DscResourceConfigFunction -Times 1 -ParameterFilter {
                    $Name -eq 'ResourceFriendlyName2'
                }
            }
        }
        Context 'no nested resources' {}
    }
}
Describe Assert-ValidZeroDscResource {
    It 'correctly invoke Get-DscResource' {}
    It 'throws when the DSC Resource is not implemented in PowerShell' {}
    It 'throws when Test-TargetResource is not exported' {}
    It 'throws when Set-TargetResource is not exported' {}
    It 'throws when Get-TargetResource is not exported' {}
    It 'correctly invokes Compare-Signatures' {}
    It 'throws when Test- signature does not match Set-' {}
    It 'throws when Set- signature does mathc Get-' {}
}
Describe Set-DscResourceConfigFunction {
    It 'correctly calls Set-Item' {}
}
Describe 'Import-ZeroDscModule using stub' {
    InModuleScope ZeroDSC {
        Context 'happy path' {
            Mock Assert-ValidZeroDscResource -Verifiable {}
            Mock Set-DscResourceConfigFunction -Verifiable {}
            It 'returns nothing' {
                $r = Import-ZeroDscModule StubResourceModule1
                $r | Should beNullOrEmpty
            }
            It 'correctly invokes Assert-ValidZeroDscResource for first resource' {
                Assert-MockCalled Assert-ValidZeroDscResource -Times 1 -ParameterFilter {
                    $Name -eq 'StubResource1FriendlyName'
                }
            }
            It 'correctly invokes Assert-ValidZeroDscResource for second resource' {
                Assert-MockCalled Assert-ValidZeroDscResource -Times 1 -ParameterFilter {
                    $Name -eq 'StubResource2FriendlyName'
                }
            }
            It 'correctly invokes Set-DscResourceFunctions for first resource' {
                Assert-MockCalled Set-DscResourceConfigFunction -Times 1 -ParameterFilter {
                    $Name -eq 'StubResource1FriendlyName'
                }
            }
            It 'correctly invokes Set-DscResourceFunctions for second resource' {
                Assert-MockCalled Set-DscResourceConfigFunction -Times 1 -ParameterFilter {
                    $Name -eq 'StubResource2FriendlyName'
                }
            }
        }
    }
}
