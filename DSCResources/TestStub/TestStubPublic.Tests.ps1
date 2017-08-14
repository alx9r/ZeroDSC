Import-Module ZeroDSC #-Force

Describe 'TestStub Resource Public API' {
    $h = @{}
    It 'is available using Get-DscResource' {
        $h.DSCResource = Get-DscResource TestStub ZeroDSC |
            Sort Version |
            Select -Last 1
    }
    It 'creating new invoker works' {
        $h.Invoker = $h.DSCResource | New-ResourceInvoker
    }
    It 'Get-' {
        $r = $h.Invoker.Invoke('Get',@{Key = 'a'})
        $r.Key | Should be 'a'
    }
    Context 'reset clears state' {
        It 'starts out false' {
            $r = $h.Invoker.Invoke('Test', @{Key = 'a'} )
            $r | Should be $false
        }
        It 'Set-' {
            $r = $h.Invoker.Invoke('Set', @{Key = 'a'} )
        }
        It 'becomes true' {
            $r = $h.Invoker.Invoke('Test', @{Key = 'a'} )
            $r | Should be $true
        }
        It 'setup second key same way' {
            $h.Invoker.Invoke('Set', @{Key = 'b'} )
            $h.Invoker.Invoke('Test', @{Key = 'b'} ) | Should be $true
        }
        It 'reset first key' {
            $h.Invoker.Invoke('Set', @{Key = 'a'; Mode = 'reset'} )
        }
        It 'first key is false agains' {
            $r = $h.Invoker.Invoke('Test', @{Key = 'a'} )
            $r | Should be $false
        }
        It 'second key remains true' {
            $r = $h.Invoker.Invoke('Test', @{Key = 'b'} )
            $r | Should be $true
        }
    }
    $tests = [ordered]@{
        'normal (1)' = @{
            Params = @{ Key = 'a' }
            Values = @(
                #  Verb  | Result
                @( 'Test', $false ),
                @( 'Set',  $null ),
                @( 'Test', $true )
            )
        }
        'normal (2)' = @{
            Params = @{ Key = 'a' }
            Values = @(
                #  Verb  | Result
                @( 'Test', $false ),
                @( 'Set',  $null ),
                @( 'Test', $true )
            )
        }
        'already set' = @{
            Params = @{ Key = 'a'; Mode = 'already set' }
            Values = @(
                # Verb | Result
                @( 'Test', $true ),
                @( 'Set', $null ),
                @( 'Test', $true )
            )
        }
        'incorrigible' = @{
            Params = @{ Key = 'a'; Mode = 'incorrigible' }
            Values = @(
                # Verb | Result
                @( 'Test', $false ),
                @( 'Set', $null ),
                @( 'Test', $false )
            )
        }
        'throw on set' = @{
            Params = @{ Key = 'a'; ThrowOnSet = 'always' }
            Values = @(
                # Verb | Result | Exception
                @( 'Test', $false ),
                @( 'Set', $null, $true ),
                @( 'Test', $false )
            )
        }
        'throw and apply on set' = @{
            Params = @{ Key = 'a'; ThrowOnSet = 'always and apply' }
            Values = @(
                # Verb | Result | Exception
                @( 'Test', $false ),
                @( 'Set', $null, $true ),
                @( 'Test', $true )
            )
        }
        'throw on test' = @{
            Params = @{ Key = 'a'; ThrowOnTest = 'always' }
            Values = @(
                # Verb | Result | Exception
                @( 'Test', $null, $true ),
                @( 'Set', $null ),
                @( 'Test', $null, $true )
            )
        }
        'throw on test after set' = @{
            Params = @{ Key = 'a'; ThrowOnTest = 'after set' }
            Values = @(
                # Verb | Result | Exception
                @( 'Test', $false ),
                @( 'Set', $null ),
                @( 'Test', $null, $true )
            )
        }
    }
    foreach ( $testName in $tests.Keys )
    {
        $params = $tests.$testName.Params
        Context $testName {
            It 'reset' {
                $h.Invoker.Invoke('Set', @{Key = 'a'; Mode = 'reset'} )
            }
            foreach ( $values in $tests.$testName.Values )
            {
                $verb,$result,$exception = $values

                if ( $exception )
                {
                    It "$verb- throws" {
                        {
                            $h.Invoker.Invoke($verb,$params)
                        } |
                            Should throw
                    }
                    continue
                }
                if ( $null -ne $result )
                {
                    It "$verb- returns $result" {
                        $r = $h.Invoker.Invoke($verb,$params)
                        $r | Should be $result
                    }
                    continue
                }
                if ( $null -eq $result )
                {
                    It "$verb-" {
                        $h.Invoker.Invoke($verb,$params)
                    }
                }
            }
        }
    }
}
