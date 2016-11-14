Import-Module ZeroDsc -Force

enum Event
{
    Start

    # Test Node
    AtEndOfCollection
    AtNodeReady
    AtNodeNotReady
    AtNodeComplete

    # Test Resource
    TestCompleteSuccess
    TestCompleteFailure

    # Set Resource
    SetComplete
}

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

Describe 'ConfigStateMachine run through' {
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
    Context 'state IdleExternal' {
        It 'correct state' {
            $sm.CurrentState.StateName | Should be 'IdleExternal'
        }
        It 'queue empty' { $sm.TriggerQueue.Count | Should be 0 }
        It 'at no node' { $e.Current | Should beNullOrEmpty }
    }
    Context 'transition StartPretest' {
        It 'Start' { $sm.RaiseEvent( [Event]::Start ) }
        It 'RunNext()' { $h = 'another h'; $sm.RunNext() }
        It 'moved to node a' { $e.Current | Should be 'a' }
    }
    Context 'state PretestDistpatch' {
        It 'correct state' {
            $sm.CurrentState.StateName | Should be 'PretestDispatch'
        }
        It 'TestNode was invoked' {
            $h.TestNode | Should be 'invoked'
            $h.Remove( 'TestNode' )
        }
    }
    Context 'transition StartResourcePretest (AtNodeNotReady)' {
        It 'AtNodeReady' { $sm.RaiseEvent( [Event]::AtNodeNotReady ) }
        It 'RunNext()' { $sm.RunNext() }
    }
    Context 'state PretestWaitForExternalTest (node a)' {
        It 'correct state' {
            $sm.CurrentState.StateName | Should be 'PretestWaitForExternalTest'
        }
        It 'at node a' { $e.Current | Should be 'a' }
    }
    Context 'transition EndResourcePretest (TestCompleteSuccess)' {
        It 'TestCompleteSuccess' { $sm.RaiseEvent([Event]::TestCompleteSuccess) }
        It 'RunNext()' { $h = 'another h'; $sm.RunNext() }
        It 'moved to node b' { $e.Current | Should be 'b' }
    }
    Context 'state PretestDispatch' {
        It 'correct state' {
            $sm.CurrentState.StateName | Should be 'PretestDispatch'
        }
        It 'TestNode was invoked' {
            $h.TestNode | Should be 'invoked'
            $h.Remove( 'TestNode' )
        }
    }
    Context 'transition StartResourcePretest (AtNodeReady)' {
        It 'AtNodeReady' { $sm.RaiseEvent( [Event]::AtNodeReady) }
        It 'RunNext()' { $sm.RunNext() }
    }
    Context 'state PretestWaitForExternalTest (node b)' {
        It 'correct state' {
            $sm.CurrentState.StateName | Should be 'PretestWaitForExternalTest'
        }
        It 'at node b' { $e.Current | Should be 'b' }
    }
    Context 'transition EndResourcePretest (TestCompleteFailure)' {
        It 'TestCompleteSuccess' { $sm.RaiseEvent([Event]::TestCompleteFailure) }
        It 'RunNext()' { $h = 'another h'; $sm.RunNext() }
        It 'moved to node c' { $e.Current | Should be 'c' }
    }
    Context 'state PretestDispatch' {
        It 'correct state' {
            $sm.CurrentState.StateName | Should be 'PretestDispatch'
        }
        It 'TestNode was invoked' {
            $h.TestNode | Should be 'invoked'
            $h.Remove( 'TestNode' )
        }
    }
    Context 'transition StartResourcePretest (AtNodeComplete)' {
        It 'AtNodeReady' { $sm.RaiseEvent( [Event]::AtNodeNotReady) }
        It 'RunNext()' { $sm.RunNext() }
    }
    Context 'state PretestWaitForExternalTest (node c)' {
        It 'correct state' {
            $sm.CurrentState.StateName | Should be 'PretestWaitForExternalTest'
        }
        It 'at node c' { $e.Current | Should be 'c' }
    }
    Context 'transition EndResourcePretest (TestCompleteSuccess)' {
        It 'TestCompleteSuccess' { $sm.RaiseEvent([Event]::TestCompleteSuccess) }
        It 'RunNext()' { $h = 'another h'; $sm.RunNext() }
        It 'moved to end of collection' { 
            $e.Current | Should beNullOrEmpty
            $e.MoveNext() | Should be $false
        }
    }
    Context 'state PretestDispatch' {
        It 'correct state' {
            $sm.CurrentState.StateName | Should be 'PretestDispatch'
        }
        It 'TestNode was invoked' {
            $h.TestNode | Should be 'invoked'
            $h.Remove( 'TestNode' )
        }
    }
    Context 'transition StartConfigure' {
        It 'AtEndOfCollection' { $sm.RaiseEvent([Event]::AtEndOfCollection) }
        It 'RunNext()' { $h = 'another h'; $sm.RunNext() }
        It 'moved to a' { $e.Current | Should be 'a' }
    }
    Context 'state ConfigureDispatch' {
        It 'correct state' {
            $sm.CurrentState.StateName | Should be 'ConfigureDispatch'
        }
        It 'TestNode was invoked' {
            $h.TestNode | Should be 'invoked'
            $h.Remove( 'TestNode' )
        }
    }
    Context 'transition MoveConfigureNextResource (AtNodeReady)' {
        It 'AtNodeNotReady' { $sm.RaiseEvent([Event]::AtNodeNotReady) }
        It 'RunNext()' { $h = 'another h'; $sm.RunNext() }
        It 'moved to b' { $e.Current | Should be 'b' }
    }
    Context 'state ConfigureDispatch' {
        It 'correct state' {
            $sm.CurrentState.StateName | Should be 'ConfigureDispatch'
        }
        It 'TestNode was invoked' {
            $h.TestNode | Should be 'invoked'
            $h.Remove( 'TestNode' )
        }
    }
    Context 'transition StartConfigureResourceSet' {
        It 'AtNodeReady' { $sm.RaiseEvent([Event]::AtNodeReady ) }
        It 'RunNext()' { $sm.RunNext() }
    }
    Context 'state ConfigureWaitForSetExternal (node b)' {
        It 'correct state' { 
            $sm.CurrentState.StateName | Should be 'ConfigureWaitForSetExternal'
        }
        It 'at node b' { $e.Current | Should be 'b' }
    }
    Context 'transition StartConfigureResourceTest' {
        It 'SetComplete' { $sm.RaiseEvent([Event]::SetComplete) }
        It 'RunNext()' { $sm.RunNext() }
    }
    Context 'state ConfigureWaitForTestExternal (node b)' {
        It 'correct state' {
            $sm.CurrentState.StateName | Should be 'ConfigureWaitForTestExternal'
        }
        It 'at node b' { $e.Current | Should be 'b' }
    }
    Context 'transition EndConfigureResourceSuccess' {
        It 'TestCompleteSuccess' { $sm.RaiseEvent([Event]::TestCompleteSuccess) }
        It 'RunNext()' { $h = 'another h'; $sm.RunNext() }
    }
    Context 'state ConfigureProgressDispatch' {
        It 'correct state' {
            $sm.CurrentState.StateName | Should be 'ConfigureProgressDispatch'
        }
        It 'TestNode was invoked' {
            $h.TestNode | Should be 'invoked'
            $h.Remove( 'TestNode' )
        }
    }
    Context 'transition MoveConfigureProgressNextResource (AtNodeComplete)' {
        It 'AtNodeComplete' { $sm.RaiseEvent([Event]::AtNodeComplete) }
        It 'RunNext()' { $h = 'another h'; $sm.RunNext() }
        It 'moved to c' { $e.Current | Should be 'c' }
    }
    Context 'state ConfigureProgressDispatch' {
        It 'correct state' {
            $sm.CurrentState.StateName | Should be 'ConfigureProgressDispatch'
        }
        It 'TestNode was invoked' {
            $h.TestNode | Should be 'invoked'
            $h.Remove( 'TestNode' )
        }
    }
    Context 'transition MoveConfigureProgressNextResource (AtNodeComplete)' {
        It 'AtNodeComplete' { $sm.RaiseEvent([Event]::AtNodeComplete) }
        It 'RunNext()' { $h = 'another h'; $sm.RunNext() }
        It 'moved to end of collection' { 
            $e.Current | Should beNullOrEmpty
            $e.MoveNext() | Should be $false
        }
    }
    Context 'state ConfigureProgressDispatch' {
        It 'correct state' {
            $sm.CurrentState.StateName | Should be 'ConfigureProgressDispatch'
        }
        It 'TestNode was invoked' {
            $h.TestNode | Should be 'invoked'
            $h.Remove( 'TestNode' )
        }
    }
    Context 'transition StartNewConfigurePass' {
        It 'AtEndOfCollection' { $sm.RaiseEvent([Event]::AtEndOfCollection) }
        It 'RunNext()' { $h = 'another h'; $sm.RunNext() }
        It 'moved to a' { $e.Current | Should be 'a' }
    }
    Context 'state ConfigureDispatch' {
        It 'correct state' {
            $sm.CurrentState.StateName | Should be 'ConfigureDispatch'
        }
        It 'TestNode was invoked' {
            $h.TestNode | Should be 'invoked'
            $h.Remove( 'TestNode' )
        }
    }
    Context 'transition MoveConfigureProgressNextResource (AtNodeComplete)' {
        It 'AtNodeComplete' { $sm.RaiseEvent([Event]::AtNodeComplete) }
        It 'RunNext()' { $h = 'another h'; $sm.RunNext() }
        It 'moved to b' { $e.Current | Should be 'b' }
    }
    Context 'state ConfigureDispatch' {
        It 'correct state' {
            $sm.CurrentState.StateName | Should be 'ConfigureDispatch'
        }
        It 'TestNode was invoked' {
            $h.TestNode | Should be 'invoked'
            $h.Remove( 'TestNode' )
        }
    }
    Context 'transition MoveConfigureProgressNextResource (AtNodeNotReady)' {
        It 'AtNodeComplete' { $sm.RaiseEvent([Event]::AtNodeNotReady) }
        It 'RunNext()' { $h = 'another h'; $sm.RunNext() }
        It 'moved to c' { $e.Current | Should be 'c' }
    }
    Context 'state ConfigureDispatch' {
        It 'correct state' {
            $sm.CurrentState.StateName | Should be 'ConfigureDispatch'
        }
        It 'TestNode was invoked' {
            $h.TestNode | Should be 'invoked'
            $h.Remove( 'TestNode' )
        }
    }
    Context 'transition End' {
        It 'AtEndOfCollection' { $sm.RaiseEvent([Event]::AtEndOfCollection) }
        It 'RunNext()' { $sm.RunNext() }
    }
    Context 'state Ended' {
        It 'correct state' {
            $sm.CurrentState.StateName | Should be 'Ended'
        }
    }
}
