enum TestNodeEvent
{
    AtEndOfNodes
    AtNodeReady
    AtNodeNotReady
    AtNodeComplete
}

function New-ConfigStateMachine
{
    [CmdletBinding()]
    [OutputType([StateMachine])]
    param
    (
        # Tests the current node.  Raises a [TestNodeEvent].
        [scriptblock]
        $TestNode,

        # Moves the resource enumerator to the next resource.
        [scriptblock]
        $MoveNext,

        # Resets the resource enumerator.
        [scriptblock]
        $Reset
    )
    process
    {
        <#
        === Nodes ===
        A node of the external resource node collection.  A node can be tested 
        by invoking TestNode for the following:
            - The node is already complete.  A node is complete when a test of
              the underlying resource has returned true in the past.  TestNode
              must raise AtNodeComplete for such a node.
            - The node is ready for configuration. A node is ready for configuration
              when all nodes it depends on are complete.  TestNode must raise
              AtNodeComplete for such a node.
            - The node is not ready for configuration.  A nod is not ready for
              configuration when nodes it depends on are not complete.  TestNode
              must raise AdNodeNotReady for such a node.

        === Phases ===
        Pretest - An initial pass is made through all resources.  Each resource
        is tested.
        Configure - After Pretest, further passes are made through all resources.
        Each resource whose dependencies have been met is set then tested.  Passes
        are repeated until no further progress is made.

        Progress is defined as any resource configuration successfully
        completing.

        === Prefixes ===
        Pretest - the pre-test phase
        Configure - configure phase when no progress has been made on the
        current pass
        ConfigureProgress - configure phase when progress has been made on 
        the current pass

        === External Suffix ===
        Most actions are invoked internally.  Setting and testing of Resources are 
        invoked externally by users.  States that await action by a user have the
        suffix External

        #>
        enum State
        {
            IdleExternal

            # Pretest Phase
            PretestDispatch
            PretestWaitForExternalTest

            # Configure Phase
            ConfigureDispatch
            ConfigureWaitForTestExternal
            ConfigureWaitForSetExternal

            ConfigureProgressDispatch
            ConfigureProgressWaitForTestExternal
            ConfigureProgressWaitForSetExternal
            
            Ended
        }

        enum Transition
        {
            StartPretest

            # Pretest Phase
            StartResourcePretest
            EndResourcePretest

            # ConfigurePhase
            StartConfigure
            StartConfigureResourceSet
            StartConfigureResourceTest
            EndConfigureResourceSuccess
            EndConfigureResourceFailed
            MoveConfigureNextResource

            StartConfigureProgressResourceSet
            StartConfigureProgressResourceTest
            MoveConfigureProgressNextResource
            StartNewConfigurePass

            End
        }

        enum Event
        {
            MoveNextNode
            AtEndOfCollection
            AtNodeReady
            AtNodeNotReady
            AtNodeComplete
            SetComplete
            TestCompleteSuccess
            TestCompleteFailure
        }

        $states = @(
            @{
                StateName = [State]::IdleExternal
                IsDefaultState = $true
            }
            @{ 
                StateName = [State]::PretestDispatch
                EntryActions = $TestNode
            }
            @{ StateName = [State]::PretestWaitForExternalTest }
            @{ 
                StateName = [State]::ConfigureDispatch
                EntryActions = $TestNode
            }
            @{ StateName = [State]::ConfigureWaitForTestExternal }
            @{ StateName = [State]::ConfigureWaitForSetExternal }
            @{ 
                StateName = [State]::ConfigureProgressDispatch
                EntryActions = $TestNode
            }
            @{ StateName = [State]::ConfigureProgressWaitForTestExternal }
            @{ StateName = [State]::ConfigureProgressWaitForSetExternal }
            @{ StateName = [State]::Ended }
        ) | New-State

        $transitions = @(
            @{ 
                TransitionName = [Transition]::StartPretest
                Triggers = [Event]::Start
                SourceStateName = [State]::IdleExternal
                TargetStateName = [State]::PretestDispatch
            }
            @{ 
                TransitionName = [Transition]::StartResourcePretest
                Triggers = [Event]::AtNodeReady,[Event]::AtNodeNotReady,[Event]::AtNodeComplete
                SourceStateName = [State]::PretestDispatch
                TargetStateName = [State]::PretestWaitForExternalTest
            }
            @{ 
                TransitionName = [Transition]::EndResourcePretest
                Triggers = [Event]::TestCompleteSuccess,[Event]::TestCompleteFailure
                SourceStateName = [State]::PretestWaitForExternalTest
                TargetStateName = [State]::PretestDispatch
                TransitionActions = $MoveNext
            }
            @{ 
                TransitionName = [Transition]::StartConfigure
                Triggers = [Event]::AtEndOfCollection
                SourceStateName = [State]::PretestDispatch
                TargetStateName = [State]::ConfigureDispatch
                TransitionActions = $Reset
            }
            @{ 
                TransitionName = [Transition]::StartConfigureResourceSet
                Triggers = [Event]::AtNodeReady
                SourceStateName = [State]::ConfigureDispatch
                TargetStateName = [State]::ConfigureProgressWaitForSetExternal
            }
            @{ 
                TransitionName = [Transition]::StartConfigureResourceTest
                Triggers = [Event]::SetComplete
                SourceStateName = [State]::ConfigureWaitForSetExternal
                TargetStateName = [State]::ConfigureWaitForTestExternal
            }
            @{ 
                TransitionName = [Transition]::EndConfigureResourceSuccess
                Triggers = [Event]::TestCompleteSuccess
                SourceStateName = [State]::ConfigureWaitForTestExternal
                TargetStateName = [State]::ConfigureProgressDispatch
            }
            @{ 
                TransitionName = [Transition]::EndConfigureResourceFailed
                Triggers = [Event]::TestCompleteFailure
                SourceStateName = [State]::ConfigureWaitForTestExternal
                TargetStateName = [State]::ConfigureDispatch
            }
            @{
                TransitionName = [Transition]::MoveConfigureNextResource
                Triggers = [Event]::AtNodeComplete,[Event]::AtNodeNotReady
                SourceStateName = [State]::ConfigureDispatch
                TargetStateName = [State]::ConfigureDispatch
                TransitionActions = $MoveNext
            }
            @{ 
                TransitionName = [Transition]::StartConfigureProgressResourceSet
                Triggers = [Event]::AtNodeReady
                SourceStateName = [State]::ConfigureProgressDispatch
                TargetStateName = [State]::ConfigureProgressWaitForSetExternal
            }
            @{ 
                TransitionName = [Transition]::StartConfigureProgressResourceTest
                Triggers = [Event]::SetComplete
                SourceStateName = [State]::ConfigureProgressWaitForSetExternal
                TargetStateName = [State]::ConfigureProgressWaitForTestExternal
            }
            @{ 
                TransitionName = [Transition]::MoveConfigureProgressNextResource
                Triggers = [Event]::AtNodeComplete,[Event]::AtNodeNotReady
                SourceStateName = [State]::ConfigureProgressDispatch
                TargetStateName = [State]::ConfigureDispatch
            }
            @{ 
                TransitionName = [Transition]::StartNewConfigurePass
                Triggers = [Event]::AtEndOfCollection
                SourceStateName = [State]::ConfigureProgressDispatch
                TargetStateName = [State]::ConfigureDispatch
                TransitionActions = $Reset
            }
            @{ 
                TransitionName = [Transition]::End
                Triggers = [Event]::AtEndOfCollection
                SourceStateName = [State]::ConfigureDispatch
                TargetStateName = [State]::Ended
            }
        ) | New-Transition

        return New-StateMachine $states $transitions
    }
}