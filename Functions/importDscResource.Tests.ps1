Import-Module ZeroDSC -Force

. "$($PSCommandPath | Split-Path -Parent)\..\Add-StubsToModulePath.ps1"
$resourceModuleStubPath = "$($PSCommandPath | Split-Path -Parent)\..\Resources\StubResourceModule1\StubResourceModule1.psd1"
$testFunctionInfoPath = "$($PSCommandPath | Split-Path -Parent)\..\Resources\testFunctionInfo.xml"
$setFunctionInfoPath = "$($PSCommandPath | Split-Path -Parent)\..\Resources\setFunctionInfo.xml"

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
                if ( $Name -match 1 ) { $n = 1 }
                if ( $Name -match 2 ) { $n = 2 }
                New-Object psobject -Property @{ 
                    Path = "ResourcePath$n"
                    FriendlyName = "ResourceFriendlyName$n" 
                }
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
    }
}
Describe Assert-ValidZeroDscResource {
    InModuleScope ZeroDSC {
        Context 'happy path' {
            Mock Get-DscResource -Verifiable {
                New-Object psobject -Property @{ 
                    Path = 'ResourcePath'
                    FriendlyName = 'ResourceFriendlyName'
                }
            }
            Mock Import-Module -Verifiable {
                New-Object psobject -Property @{
                    Name = 'ResourceName'
                }
            }
            Mock Remove-Module -Verifiable {}
            Mock Get-Command -Verifiable {}
            Mock Compare-Signatures -Verifiable {}
            It 'returns nothing' {
                $r = Assert-ValidZeroDscResource 'param'
                $r | Should beNullOrEmpty
            }
            It 'gets the DSC resource named by parameter' {
                Assert-MockCalled Get-DscResource -Times 1 {
                    $Name -eq 'param'
                }
            }
            It 'imports the dsc resource module by path' {
                Assert-MockCalled Import-Module -Times 1 {
                    $Name -eq 'ResourcePath'
                }
            }
            It 'gets the Test- command' {
                Assert-MockCalled Get-Command -Times 1 {
                    $Name -eq 'Test-TargetResource' -and
                    $Module -eq 'ResourceName'
                }
            }
            It 'gets the Set- command' {
                Assert-MockCalled Get-Command -Times 1 {
                    $Name -eq 'Set-TargetResource' -and
                    $Module -eq 'ResourceName'
                }
            }
            It 'gets the Get- command' {
                Assert-MockCalled Get-Command -Times 1 {
                    $Name -eq 'Set-TargetResource' -and
                    $Module -eq 'ResourceName'
                }
            }
        }
        It 'throws when the DSC Resource is not implemented in PowerShell' {}
        It 'throws when Test-TargetResource is not exported' {}
        It 'throws when Set-TargetResource is not exported' {}
        It 'throws when Get-TargetResource is not exported' {}
        It 'correctly invokes Compare-Signatures' {}
        It 'throws when Test- signature does not match Set-' {}
        It 'throws when Set- signature does mathc Get-' {}
    }
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
                    $Name -eq 'StubResource1AFriendlyName'
                }
            }
            It 'correctly invokes Assert-ValidZeroDscResource for second resource' {
                Assert-MockCalled Assert-ValidZeroDscResource -Times 1 -ParameterFilter {
                    $Name -eq 'StubResource1BFriendlyName'
                }
            }
            It 'correctly invokes Set-DscResourceFunctions for first resource' {
                Assert-MockCalled Set-DscResourceConfigFunction -Times 1 -ParameterFilter {
                    $Name -eq 'StubResource1AFriendlyName'
                }
            }
            It 'correctly invokes Set-DscResourceFunctions for second resource' {
                Assert-MockCalled Set-DscResourceConfigFunction -Times 1 -ParameterFilter {
                    $Name -eq 'StubResource1BFriendlyName'
                }
            }
            It 'uppermost module was removed' {
                $r = Get-Module StubResourceModule1
                $r | Should beNullOrEmpty
            }
            It 'first nested module remains imported' {
                $r = Get-Module StubResourceModule1a
                $r | Should not beNullOrEmpty
            }
            It 'second nested module remains imported' {
                $r = Get-Module StubResourceModule1b
                $r | Should not beNullOrEmpty
            }
        }
    }
}
Describe 'Assert-ValidZeroDscResource using stub' {
    InModuleScope ZeroDSC {
        Context 'happy path' {
            Mock Compare-Signatures -Verifiable {}
            It 'returns nothing' {
                $r = Assert-ValidZeroDscResource 'StubResource1A'
                $r | Should beNullOrEmpty
            }
            It 'compares the Test- and Set- signatures' {
                Assert-MockCalled Compare-Signatures -Times 1 {
                    $CommandA.Verb -eq 'Test' -and
                    $CommandB.Verb -eq 'Set'
                }
            }
            It 'compares the Set- and Get- signatures' {
                Assert-MockCalled Compare-Signatures -Times 1 {
                    $CommandA.Verb -eq 'Set' -and
                    $CommandB.Verb -eq 'Get'
                }            
            }
            It 'resource module was removed' {
                $r = Get-Module 'StubResource1A'
                $r | Should beNullOrEmpty
            }
        }
    }
}
