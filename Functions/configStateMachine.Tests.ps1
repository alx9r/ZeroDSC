Import-Module ZeroDsc -Force -Args ExportAll

Describe 'ConfigStateMachine basics' {
    Context 'basics' {
        It 'doesn''t throw' {
            New-ConfigStateMachine
        }
        It 'returns exactly one state machine object' {
            $r = New-ConfigStateMachine
            $r.Count | Should be 1
            $r.GetType() | Should be 'StateMachine'
        }
    }
}

$tests = @{
    'Basic Operation' = @(
            # node,   stateName,                   testNodeInvoked, eventName
        @($null, 'IdleExternal',                        $false,'Start'              ),
        @('a',   'PretestDispatch',                     $true ,'AtNodeReady'        ),
        @('a',   'PretestWaitForTestExternal',          $false,'TestCompleteSuccess'),
        @('b',   'PretestDispatch',                     $true ,'AtNodeReady'        ),
        @('b',   'PretestWaitForTestExternal',          $false,'TestCompleteFailure'),
        @('c',   'PretestDispatch',                     $true ,'AtNodeReady'        ),
        @('c',   'PretestWaitForTestExternal',          $false,'TestCompleteFailure'),
        @($null, 'PretestDispatch',                     $true ,'AtEndOfCollection'  ),
        @('a',   'ConfigureDispatch',                   $true ,'AtNodeComplete'     ),
        @('b',   'ConfigureDispatch',                   $true ,'AtNodeReady'        ),
        @('b',   'ConfigureWaitForSetExternal',         $false,'SetComplete'        ),
        @('b',   'ConfigureWaitForTestExternal',        $false,'TestCompleteSuccess'),
        @('b',   'ConfigureProgressDispatch',           $true ,'AtNodeComplete'     ),
        @('c',   'ConfigureProgressDispatch',           $true ,'AtNodeReady'        ),
        @('c',   'ConfigureProgressWaitForSetExternal', $false,'SetComplete'        ),
        @('c',   'ConfigureProgressWaitForTestExternal',$false,'TestCompleteSuccess'),
        @('c',   'ConfigureProgressDispatch',           $true ,'AtNodeComplete'     ),
        @($null, 'ConfigureProgressDispatch',           $true ,'AtEndOfCollection'  ),
        @('a',   'ConfigureDispatch',                   $true ,'AtNodeComplete'     ),
        @('b',   'ConfigureDispatch',                   $true ,'AtNodeComplete'     ),
        @('c',   'ConfigureDispatch',                   $true ,'AtNodeComplete'     ),
        @($null, 'ConfigureDispatch',                   $true ,'AtEndOfCollection'  ),
        @($null, 'Ended')
    )
}

foreach ( $testName in $tests.Keys )
{
    Describe "ConfigStateMachine ($testName)" {
        $l = [System.Collections.Generic.List[string]]@('a','b','c')
        $e = $l.GetEnumerator()
        $h = @{}
        $splat = @{
            TestNode = { $h.TestNode = 'invoked' }
            MoveNext = { $e.MoveNext() }
            Reset = { $e.Reset() }
            ActionArgs = Get-Variable 'h'
        }
        $sm = New-ConfigStateMachine @splat
        $i = 0
        foreach ( $value in $tests.$testName )
        {
            $node,$stateName,$testNodeInvoked,$eventName = $value
            Context "Step $i" {
                It "state $stateName" {
                    $sm.CurrentState.StateName | Should be $stateName
                }
                It "queue empty" {
                    $sm.TriggerQueue.Count | Should be 0
                }
                It "at node $node" {
                    $e.Current | Should be $node
                }
                if ( $eventName )
                {
                    It "raise event $eventName" {
                        $sm.RaiseEvent($eventName)
                    }
                }
                if ( $testNodeInvoked )
                {
                    It 'TestNode was invoked' {
                        $h.TestNode | Should be 'invoked'
                        $h.Remove('TestNode')
                    }
                }
                else
                {
                    It 'TestNode was not invoked' {
                        $H.TestNode | Should beNullOrEmpty
                    }
                }
                if ( $stateName -ne 'Ended' )
                {
                    It ".RunNext()" {
                        $sm.RunNext()
                    }
                }
            }
            $i ++
        }
    }
}
