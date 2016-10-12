Describe Test-Prerequisites {
    Context 'only ConfigObjects' {
        It 'returns true when DependsOn is empty' {}
        It 'returns true when DependsOn refers to a completed instruction' {}
        It 'returns false when DependsOn refers to an uncompleted instruction' {}
        It 'returns true when DependsOn refers to two completed instructions' {}
        It 'returns false when DependsOn refers to one completed and one uncompleted instruction' {}
        It 'returns false when DependsOn refers to two uncompleted instructions' {}
        It 'returns true when an aggregate condition is met' {}
        It 'returns false whan an aggregate condition is not met' {}
    }
    Context 'only PrereqObjects' {
        It 'correctly invokes each objects'' Test- command' {}
        It 'correctly returns false for Count -eq 0' {}
        It 'correctly returns true for Count -eq 0' {}
        It 'correctly returns false for COunt -ge 1' {}
        It 'correctly returns true for Count -ge 1' {}
    }
}