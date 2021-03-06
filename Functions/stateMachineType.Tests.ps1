Import-Module ZeroDsc #-Force

InModuleScope ZeroDsc {

Describe New-Transition {
    $params =  @{
        TransitionName = 'name'
        Triggers = 'trigger'
        SourceStateName = 'source'
        TargetStateName = 'target'
        TransitionActions = @(
            { 'Action1' }
            { 'Action2' }
        )
    }
    It 'creates exactly one Transition object' {
        $r = $params | New-Transition
        $r.Count | Should be 1
        $r.GetType() | Should be 'SmTransition'
    }
    It 'correctly populates properties' {
        $r = $params | New-Transition
        $r.TransitionName | Should be 'name'
        $r.Triggers | Should be 'trigger'
        $r.SourceStateName | Should be 'source'
        $r.TargetStateName | Should be 'target'
        $r.TransitionActions[0] | Should match 'Action1'
        $r.TransitionActions[1] | Should match 'Action2'
    }
    It 'throws on superfluous parameter' {
        $params = $params.Clone()
        $params.Superfluous = 'superfluous'
        { $params | New-Transition } |
            Should throw 'The member "Superfluous" was not found'
    }
    Context 'missing mandatory parameters' {
            foreach ( $parameterName in @(
                'TransitionName','Triggers',
                'SourceStateName','TargetStateName'
            )
        )
        {
            $thisParams = $params.Clone()
            It "throws exception on missing $parameterName" {
                $thisParams.Remove($parameterName)
                { $thisParams | New-Transition } |
                    Should throw "Missing mandatory parameter $parameterName"
            }
        }
    }
}

Describe New-State {
    $params = @{
        StateName = 'name'
        EntryActions = @(
            { 'EntryAction1' }
            { 'EntryAction2' }
        )
        ExitActions = @(
            { 'ExitAction1' }
            { 'ExitAction2' }
        )
        IsDefaultState = $true
    }
    It 'creates exactly one state object' {
        $r = $params | New-State
        $r.Count | Should be 1
        $r.GetType() | Should be 'SmState'
    }
    It 'correctly populates properties' {
        $r = $params | New-State
        $r.StateName | Should be 'name'
        $r.EntryActions[0] | Should match 'EntryAction1'
        $r.EntryActions[1] | Should match 'EntryAction2'
        $r.ExitActions[0] | Should match 'ExitAction1'
        $r.ExitActions[1] | Should match 'ExitAction2'
    }
    It 'throws on superfluous parameter' {
        $params = $params.Clone()
        $params.Superfluous = 'superfluous'
        { $params | New-State } |
            Should throw 'The member "Superfluous" was not found'
    }
    It "throws exception on missing name" {
        $thisParams = $params.Clone()
        $thisParams.Remove('StateName')
        { $thisParams | New-State } |
            Should throw "Missing mandatory parameter StateName"
    }
}

Describe New-StateMachine {
    Context 'happy path' {
        BeforeEach {
            $states = @(
                @{ StateName = 'a' ; IsDefaultState = $true }
                @{ StateName = 'b' }
            ) | New-State
            $transitions =  @(
                @{
                    TransitionName = 'AtoB'
                    Triggers = 'trigger1','trigger2'
                    SourceStateName = 'a'
                    TargetStateName = 'b'
                }
            ) | New-Transition
            $a = 1; $b = 2
            $variables = Get-Variable 'a','b'
        }
        It 'returns exactly one statemachine' {
            $r = New-StateMachine $states $transitions
            $r.Count | Should be 1
            $r.GetType() | Should be 'StateMachine'
        }
        It 'correctly populates statelist' {
            $r = New-StateMachine $states $transitions
            $r.StateList.Count | Should be 2
            $r.StateList.a.StateName | Should be a
            $r.StateList.b.StateName | Should be b
        }
        It 'correctly populates CurrentState' {
            $r = New-StateMachine $states $transitions
            $r.CurrentState.StateName | Should be 'a'
        }
        It 'correctly populates transition lists' {
            $r = New-StateMachine $states $transitions
            $r.StateList.a.TransitionList.Count | Should be 2
            $r.StateList.a.TransitionList.trigger1.TransitionName | Should be 'AtoB'
            $r.StateList.a.TransitionList.trigger2.TransitionName | Should be 'AtoB'
            $r.StateList.b.TransitionList.Count | Should be 0
        }
        It 'correctly populates action context variables' {
            $r = New-StateMachine $states $transitions $variables
            $r.ActionArgs[0].Name | Should be 'a'
            $r.ActionArgs[0].Value | Should be '1'
            $r.ActionArgs[1].Name | Should be 'b'
            $r.ActionArgs[1].Value | Should be '2'
        }
    }
    Context 'duplicate default states' {
        $states = @(
            @{StateName = 'a' ; IsDefaultState = $true}
            @{StateName = 'b' ; IsDefaultState = $true}
        ) | New-State
        It 'throws' {
            { New-StateMachine $states } |
                Should throw 'Second default state found in state b'
        }
    }
    Context 'no default state' {
        $states = @(
            @{StateName = 'a' }
        ) | New-State
        It 'throws' {
            { New-StateMachine $states } |
                Should throw 'No default state found'
        }
    }
    Context 'duplicate state names' {
        $states = @(
            @{StateName = 'a' ; IsDefaultState = $true }
            @{StateName = 'a' }
        ) | New-State
        It 'throws' {
            { New-StateMachine $states } |
                Should throw 'Duplicate StateName a'
        }
    }
    Context 'duplicate transition' {
        $states = @{ StateName = 'a' ; IsDefaultState = $true } |
            New-State
        $transitions =  @(
            @{
                TransitionName = 'AtoA1'
                Triggers = 'trigger'
                SourceStateName = 'a'
                TargetStateName = 'a'
            }
            @{
                TransitionName = 'AtoA2'
                Triggers = 'trigger'
                SourceStateName = 'a'
                TargetStateName = 'a'
            }
        ) | New-Transition
        It 'throws' {
            { New-StateMachine $states $transitions } |
                Should throw "Duplicate transition state 'a' trigger 'trigger'"
        }
    }
    Context 'non-existent source state' {
        $states = @{ StateName = 'a' ; IsDefaultState = $true } |
            New-State
        $transitions = @(
            @{
                TransitionName = 'BtoA'
                Triggers = 'trigger'
                SourceStateName = 'b'
                TargetStateName = 'a'
            }
        )
        It 'throws' {
            { New-StateMachine $states $transitions } |
                Should throw 'Non-existent source state b in transition BtoA'
        }
    }
    Context 'non-existent target state' {
        $states = @{ StateName = 'a' ; IsDefaultState = $true }
        $transitions = @(
            @{
                TransitionName = 'AtoB'
                Triggers = 'trigger'
                SourceStateName = 'a'
                TargetStateName = 'b'
            }
        )
        It 'throws' {
            { New-StateMachine $states $transitions } |
                Should throw 'Non-existent target state b in transition AtoB'
        }
    }
}

Describe Invoke-RunNext {
    Context 'changes state' {
        $states = @(
            @{ StateName = 'a' ; IsDefaultState = $true }
            @{ StateName = 'b' }
        ) | New-State
        $transitions =  @(
            @{
                TransitionName = 'AtoB'
                Triggers = 'trigger'
                SourceStateName = 'a'
                TargetStateName = 'b'
            }
        ) | New-Transition
        $sm = New-StateMachine $states $transitions
        It 'starts in default state' {
            $sm.CurrentState.StateName | Should be 'a'
        }
        It 'does nothing without an event in the trigger queue' {
            $sm | Invoke-RunNext
            $sm.CurrentState.StateName | Should be 'a'
        }
        It 'add event to trigger queue' {
            $sm | Add-Event 'trigger'
        }
        It 'RunNext' {
            $sm | Invoke-RunNext
        }
        It 'ends in next state' {
            $sm.CurrentState.StateName | Should be 'b'
        }
    }
    Context 'ignores event that doesn''t match any triggers' {
        $states = @(
            @{ StateName = 'a' ; IsDefaultState = $true }
            @{ StateName = 'b' }
        ) | New-State
        $transitions =  @(
            @{
                TransitionName = 'AtoB'
                Triggers = 'trigger'
                SourceStateName = 'a'
                TargetStateName = 'b'
            }
        ) | New-Transition
        $sm = New-StateMachine $states $transitions
        It 'starts in default state' {
            $sm.CurrentState.StateName | Should be 'a'
        }
        It 'add unrelated event to trigger queue' {
            $sm | Add-Event 'unrelated event'
        }
        It 'RunNext' {
            $sm | Invoke-RunNext
        }
        It 'ends in same state' {
            $sm.CurrentState.StateName | Should be 'a'
        }
    }
    Context 'invokes exit actions' {
        $h = @{}
        $states = @(
            @{
                StateName = 'a' ; IsDefaultState = $true
                ExitActions = @(
                    { $h.Action1 = 'invoked' }
                    { $h.Action2 = 'invoked' }
                )
            }
            @{ StateName = 'b' }
        ) | New-State
        $transitions =  @(
            @{
                TransitionName = 'AtoB'
                Triggers = 'trigger'
                SourceStateName = 'a'
                TargetStateName = 'b'
            }
        ) | New-Transition
        $sm = New-StateMachine $states $transitions
        It 'add event to trigger queue' {
            $sm | Add-Event 'trigger'
        }
        It 'RunNext returns nothing' {
            $r = $sm | Invoke-RunNext
            $r | Should beNullOrEmpty
        }
        It 'actions were invoked' {
            $h.Action1 | Should be 'invoked'
            $h.Action2 | Should be 'invoked'
        }
    }
    Context 'invokes entry actions' {
        $h = @{}
        $states = @(
            @{ StateName = 'a' ; IsDefaultState = $true }
            @{
                StateName = 'b'
                EntryActions = @(
                    { $h.Action1 = 'invoked' }
                    { $h.Action2 = 'invoked' }
                )
            }
        ) | New-State
        $transitions =  @(
            @{
                TransitionName = 'AtoB'
                Triggers = 'trigger'
                SourceStateName = 'a'
                TargetStateName = 'b'
            }
        ) | New-Transition
        $sm = New-StateMachine $states $transitions
        It 'add event to trigger queue' {
            $sm | Add-Event 'trigger'
        }
        It 'RunNext returns nothing' {
            $r = $sm | Invoke-RunNext
            $r | Should beNullOrEmpty
        }
        It 'actions were invoked' {
            $h.Action1 | Should be 'invoked'
            $h.Action2 | Should be 'invoked'
        }
    }
    Context 'invokes transition actions' {
        $h = @{}
        $states = @(
            @{ StateName = 'a' ; IsDefaultState = $true }
            @{ StateName = 'b' }
        ) | New-State
        $transitions =  @(
            @{
                TransitionName = 'AtoB'
                Triggers = 'trigger'
                SourceStateName = 'a'
                TargetStateName = 'b'
                TransitionActions = @(
                    { $h.Action1 = 'invoked' }
                    { $h.Action2 = 'invoked' }
                )
            }
        ) | New-Transition
        $sm = New-StateMachine $states $transitions
        It 'add event to trigger queue' {
            $sm | Add-Event 'trigger'
        }
        It 'RunNext returns nothing' {
            $r = $sm | Invoke-RunNext
            $r | Should beNullOrEmpty
        }
        It 'actions were invoked' {
            $h.Action1 | Should be 'invoked'
            $h.Action2 | Should be 'invoked'
        }
    }
    Context 'invokes actions in correct order' {
        $h = @{}
        $h.i = 1
        $states = @(
            @{
                StateName = 'a' ; IsDefaultState = $true
                ExitActions = { $h.Action1 = $h.i; $h.i++ }
            }
            @{
                StateName = 'b'
                EntryActions = { $h.Action3 = $h.i; $h.i++ }
            }
        ) | New-State
        $transitions =  @(
            @{
                TransitionName = 'AtoB'
                Triggers = 'trigger'
                SourceStateName = 'a'
                TargetStateName = 'b'
                TransitionActions = @(
                    { $h.Action2 = $h.i; $h.i++ }
                )
            }
        ) | New-Transition
        $sm = New-StateMachine $states $transitions
        It 'add event to trigger queue' {
            $sm | Add-Event 'trigger'
        }
        It 'RunNext returns nothing' {
            $r = $sm | Invoke-RunNext
            $r | Should beNullOrEmpty
        }
        It 'actions were invoked in correct order' {
            $h.Action1 | Should be '1'
            $h.Action2 | Should be '2'
            $h.Action3 | Should be '3'
        }
    }
    Context 'action variable accessible from action context' {
        $a = @{ v1 = 1 }
        $b = @{ v1 = 1}
        $variables = Get-Variable 'a','b'
        $states = @(
            @{
                StateName = 'a' ; IsDefaultState = $true
                ExitActions = {
                    $a.v2 = $a.v1
                    $b.v2 = $b.v1
                }
            }
            @{ StateName = 'b' }
        ) | New-State
        $transitions =  @(
            @{
                TransitionName = 'AtoB'
                Triggers = 'trigger'
                SourceStateName = 'a'
                TargetStateName = 'b'
            }
        ) | New-Transition
        $sm = New-StateMachine $states $transitions $variables
        It 'add event to trigger queue' {
            $sm | Add-Event 'trigger'
        }
        It 'RunNext returns nothing' {
            $a = 'another a'
            $b = 'another b'
            $r = $sm | Invoke-RunNext
            $r | Should beNullOrEmpty
        }
        It 'action variables were read and written' {
            $a.v2 | Should be 1
            $b.v2 | Should be 1
        }
    }
    Context 'exception in exit action' {
        $h = @{}
        $states = @(
            @{
                StateName = 'a' ; IsDefaultState = $true
                ExitActions = {
                    $h.Action = 'invoked'
                    throw 'exception in action'
                }
            }
            @{ StateName = 'b' }
        ) | New-State
        $transitions =  @(
            @{
                TransitionName = 'AtoB'
                Triggers = 'trigger'
                SourceStateName = 'a'
                TargetStateName = 'b'
            }
        ) | New-Transition
        $sm = New-StateMachine $states $transitions
        It 'add event to trigger queue' {
            $sm | Add-Event 'trigger'
        }
        It 'RunNext does not throw' {
            $sm | Invoke-RunNext
        }
        It 'actions was invoked' {
            $h.Action | Should be 'invoked'
        }
        It 'state did not change' {
            $sm.CurrentState.StateName | Should be 'a'
        }
    }
}

Describe Reset-StateMachine {
    $states = @(
        @{ StateName = 'a' ; IsDefaultState = $true }
        @{ StateName = 'b' }
    ) | New-State
    $sm = New-StateMachine $states
    $sm.CurrentState = $sm.StateList.b
    $sm.TriggerQueue.Enqueue('eventName')
    It 'returns nothing' {
        $r = $sm | Reset-StateMachine
        $r | Should beNullOrEmpty
    }
    It 'CurrentState is set to default state after clear' {
        $sm.CurrentState -eq $states[0] | Should be $true
    }
    It 'TriggerQueue is empty' {
        $sm.TriggerQueue.Count | Should be 0
    }
}

Describe Add-Event {
    Context 'external invokation' {
        $states = @(
            @{ StateName = 'a' ; IsDefaultState = $true }
            @{ StateName = 'b' }
        ) | New-State
        $transitions =  @(
            @{
                TransitionName = 'AtoB'
                Triggers = 'trigger'
                SourceStateName = 'a'
                TargetStateName = 'b'
            }
        ) | New-Transition
        $sm = New-StateMachine $states $transitions
        It 'event gets added to queue' {
            $sm | Add-Event 'event'
            $r = $sm.TriggerQueue.Dequeue()
            $r | Should be 'event'
        }
    }
    Context 'invokation from internal action' {
        $states = @(
            @{
                StateName = 'a' ; IsDefaultState = $true
                ExitActions = {
                    RaiseEvent 'event raised in action'
                }
            }
            @{ StateName = 'b' }
        ) | New-State
        $transitions =  @(
            @{
                TransitionName = 'AtoB'
                Triggers = 'trigger'
                SourceStateName = 'a'
                TargetStateName = 'b'
            }
        ) | New-Transition
        $sm = New-StateMachine $states $transitions
        It 'event gets added to queue' {
            $sm | Add-Event 'trigger'
            $sm | Invoke-RunNext
            $r = $sm.TriggerQueue.Dequeue()
            $r | Should be 'event raised in action'
        }
    }
}

Describe 'complete StateMachine' {
    enum State { a; b; c; }
    enum Transition { AtoB; BtoC; CtoA }
    enum Event { Next; BDone; StartA }

    $states = @(
        @{ StateName = [State]::a ; IsDefaultState = $true }
        @{
            StateName = [State]::b
            EntryActions = { RaiseEvent([Event]::BDone) }
        }
        @{ StateName = [State]::c }
    ) | New-State

    $transitions = @(
        @{
            TransitionName = [Transition]::AtoB
            Triggers = [Event]::Next
            SourceStateName = [State]::a
            TargetStateName = [State]::b
        }
        @{
            TransitionName = [Transition]::BtoC
            Triggers = [Event]::BDone
            SourceStateName = [State]::b
            TargetStateName = [State]::c
            TransitionActions = { RaiseEvent([Event]::StartA) }
        }
        @{
            TransitionName = [Transition]::CtoA
            Triggers = [Event]::StartA
            SourceStateName = [State]::c
            TargetStateName = [State]::a
        }
    ) | New-Transition

    $sm = New-StateMachine $states $transitions

    It 'starts in default state' {
        $sm.CurrentState.StateName | Should be 'a'
    }
    It 'add event to trigger queue' {
        $sm | Add-Event ([Event]::Next)
    }
    It 'RunNext' {
        $sm | Invoke-RunNext
    }
    It 'changed to state b' {
        $sm.CurrentState.StateName | Should be 'b'
    }
    It 'RunNext' {
        $sm | Invoke-RunNext
    }
    It 'changes to state c' {
        $sm.CurrentState.StateName | Should be 'c'
    }
    It 'RunNext' {
        $sm | Invoke-RunNext
    }
    It 'changes to state a' {
        $sm.CurrentState.StateName | Should be 'a'
    }
    It 'Queue is empty' {
        $sm.TriggerQueue.Count | Should be 0
    }
    It 'add event to trigger queue' {
        $sm | Add-Event ([Event]::Next)
    }
    It 'RunAllQueued' {
        $sm | Invoke-RunAllQueued
    }
    It 'ends in state a' {
        $sm.CurrentState.StateName | Should be 'a'
    }
}
}
