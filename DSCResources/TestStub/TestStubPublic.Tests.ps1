Import-Module ZeroDSC -Force

Describe 'TestStub Resource Public API' {
    $h = @{}
    It 'is available using Get-DscResource' {
        $h.DSCResource = Get-DscResource TestStub ZeroDSC
    }
    It 'creating new invoker works' {
        $h.Invoker = $h.DSCResource | New-ResourceInvoker
    }
    It 'Get-' {
        $r = $h.Invoker.Invoke('Get',@{Mode = 'normal'})
        $r.Mode | Should be 'normal'
    }
    Context 'reset clears state' {
        It 'starts out false' {
            $r = $h.Invoker.Invoke('Test', @{Mode = 'normal'} )
            $r | Should be $false
        }
        It 'Set-' {
            $r = $h.Invoker.Invoke('Set', @{Mode = 'normal'} )
        }
        It 'becomes true' {
            $r = $h.Invoker.Invoke('Test', @{Mode = 'normal'} )
            $r | Should be $true
        }
        It 'reset' {
            $h.Invoker.Invoke('Set', @{Mode = 'reset'} )
        }
        It 'is false agains' {
            $r = $h.Invoker.Invoke('Test', @{Mode = 'normal'} )
            $r | Should be $false
        }
    }
    $tests = [ordered]@{
        'normal (1)' = @{
            Params = @{ Mode = 'normal' }
            Values = @(
                #  Verb  | Result
                @( 'Test', $false ),
                @( 'Set',  $null ),
                @( 'Test', $true )
            )
        }
        'normal (2)' = @{
            Params = @{ Mode = 'normal' }
            Values = @(
                #  Verb  | Result
                @( 'Test', $false ),
                @( 'Set',  $null ),
                @( 'Test', $true )
            )
        }
        'already set' = @{
            Params = @{ Mode = 'already set' }
            Values = @(
                # Verb | Result
                @( 'Test', $true ),
                @( 'Set', $null ),
                @( 'Test', $true )
            )
        }
        'incorrigible' = @{
            Params = @{ Mode = 'incorrigible' }
            Values = @(
                # Verb | Result
                @( 'Test', $false ),
                @( 'Set', $null ),
                @( 'Test', $false )
            )
        }
        'throw on set' = @{
            Params = @{ Mode = 'normal'; ThrowOnSet = 'always' }
            Values = @(
                # Verb | Result | Exception
                @( 'Test', $false ),
                @( 'Set', $null, $true ),
                @( 'Test', $false )
            )
        }
        'throw on test' = @{
            Params = @{ Mode = 'normal'; ThrowOnTest = 'always' }
            Values = @(
                # Verb | Result | Exception
                @( 'Test', $null, $true ),
                @( 'Set', $null ),
                @( 'Test', $null, $true )
            )
        }
        'throw on test after set' = @{
            Params = @{ Mode = 'normal'; ThrowOnTest = 'after set' }
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
                $h.Invoker.Invoke('Set', @{Mode = 'reset'} )
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
