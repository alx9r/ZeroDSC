Import-Module ZeroDSC -Force

$records = @{}

Describe 'Test Environment' {
    It 'add the test stubs to PSModulePath' {
        . "$($PSCommandPath | Split-Path -Parent)\..\Add-StubsToModulePath.ps1"
    }
}
<#
Describe Invoke-ProcessConfiguration {
    It 'selects Mode Set by default' {}
    It 'selects Mode Test for TestOnly' {}
    Context 'one instruction, prerequisite failed' {
        It 'does not invoke Invoke-ProcessIdempotent' {}
        It 'invokes Test-Prerequisites once' {}
    }
    Context 'one instruction, prerequisite met' {
        It 'correctly invokes Test-Prerequisites' {}
        It 'correctly invokes Invoke-ProcessIdempotent' {}
    }
    Context 'one instruction, is prerequisite, prerequisite met' {}
    Context 'one instruction, is prerequisite, prerequisite failed' {}
    Context 'two instructions, in order, success' {}
    Context 'two instructions, in order, fail first' {}
    Context 'two instructions, in order, fail second' {}
    Context 'two instructions, first after second, success' {}
    Context 'two instructions, first after second, fail first' {}
    Context 'two instructions, first after second, fail second' {}
    Context 'two instructions, one prerequisite, first after second, success' {}
    Context 'two instructions, one prerequisite, first after second, fail first' {}
    Context 'two instructions, one prerequisite, first after second, fail second' {}
}
#>
<#
Describe 'Invoke-ResourceConfiguration' {
    Context 'stub' {
        It 'correctly returns value (1)' {
            $ConfigDocument = New-ConfigDocument ConfigName {
                Get-DscResource StubResource1A | Import-DscResource
                StubResource1A ResourceName @{
                    StringParam1 = 's1'
                    BoolParam = $true
                }
            }
            $splat = @{
                DscResources = $ConfigDocument.DscResources
                ResourceConfig = $ConfigDocument.ResourceConfigs.'[StubResource1A]ResourceName'
                Mode = 'Test'
            }
            $r = Invoke-ResourceConfiguration @splat
            $r | Should be $true
        }
        It 'correctly returns value (2)' {
            $ConfigDocument = New-ConfigDocument ConfigName {
                Get-DscResource StubResource1A | Import-DscResource
                StubResource1A ResourceName @{
                    StringParam1 = 's1'
                    BoolParam = $false
                }
            }
            $splat = @{
                DscResources = $ConfigDocument.DscResources
                ResourceConfig = $ConfigDocument.ResourceConfigs.'[StubResource1A]ResourceName'
                Mode = 'Test'
            }
            $r = Invoke-ResourceConfiguration @splat
            $r | Should be $false
        }
    }
}
#>