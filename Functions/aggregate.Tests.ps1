Import-Module ZeroDsc -Force

Describe Test-ValidAggregateTypeName {
    Context 'valid TypeNames' {
        It 'returns exactly one boolean' {
            $r = 'Count' | Test-ValidAggregateTypeName
            $r.Count | Should be 1
        }
        It 'Count' {
            $r = 'Count' | Test-ValidAggregateTypeName
            $r | Should be $true
        }
    }
    Context 'invalid TypeNames' {
        It 'returns exactly one boolean' {
            $r = 'Count' | Test-ValidAggregateTypeName
            $r.Count | Should be 1
        }
        It 'invalid' {
            $r = 'invalid' | Test-ValidAggregateTypeName
            $r | Should be $false
        }    
    }
}

Describe Test-ValidAggregateTest {
    Context 'valid tests' {
        It 'returns exactly one boolean' {
            $r = '-gt 0' | Test-ValidAggregateTest
            $r.Count | Should be 1
        }
        foreach ( $test in @(
                '-gt 0'
                '-eq 0'
            )
        )
        {
            It $test {
                $r = $test | Test-ValidAggregateTest
                $r | Should be $true
            }
        }
    }
    Context 'invalid TypeNames' {
        It 'returns exactly one boolean' {
            $r = '-gt 1' | Test-ValidAggregateTest
            $r.Count | Should be 1
        }
        foreach ( $test in @(
                '-gt 1'
                '-eq 1'
            )
        )
        {
            It $test {
                $r = $test | Test-ValidAggregateTest
                $r | Should be $false
            }
        }  
    }
}