Import-Module ZeroDSC -Force

Describe Invoke-ProcessConfiguration {
    InModuleScope ZeroDSC {
        Mock Test-ValidConfigObject {}
        Mock ConvertTo-Instructions {}
        Mock Test-Prerequisites {}
        Mock Invoke-ProcessIdempotent {}
        Context 'ConvertTo-Instructions' {
            Mock Test-ValidConfigObject {}
            Mock ConvertTo-Instructions -Verifiable
            It 'correctly invokes ConvertTo-Instructions' {
                $splat = @{
                    ResourceName = 'ResourceName'
                    ConfigName = 'ConfigName'
                }
                New-ConfigObject @splat | Invoke-ProcessConfiguration
                Assert-MockCalled ConvertTo-Instructions -ParameterFilter {
                    $InputObject.ResourceName -eq 'ResourceName' -and
                    $InputObject.ConfigName -eq 'ConfigName'
                }
            }
        }
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
}
