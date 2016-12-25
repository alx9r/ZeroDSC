function New-ConfigStateMachine
{
    [CmdletBinding()]
    [OutputType([StateMachine])]
    param
    (
        # Tests the current node.  Raises a [TestNodeEvent].
        [Parameter(Position = 1)]
        [scriptblock]
        $TestNode,

        # Moves the resource enumerator to the next resource.
        [Parameter(Position = 2)]
        [scriptblock]
        $MoveNext,

        # Resets the resource enumerator.
        [Parameter(Position = 3)]
        [scriptblock]
        $Reset,

        [Parameter(Position = 4)]
        [psvariable[]]
        $ActionArgs
    )
    process
    {
        <#
        === Nodes ===
        A node of the external resource node collection.  A node can be tested
        by invoking TestNode for the following:
            * Complete - The node is already complete.  A node is complete when a test of
              the underlying resource has returned true in the past.  TestNode
              must raise AtNodeComplete for such a node.
            * Ready - The node is ready for configuration. A node is ready for configuration
              when all nodes it depends on are complete.  TestNode must raise
              AtNodeComplete for such a node.
            * Not Ready - The node is not ready for configuration.  A node is not ready for
              configuration when nodes it depends on are not complete.  TestNode
              must raise AtNodeNotReady for such a node.
            * Skipped - A configuration step for the node was skipped.  TestNode must raise
              AtNodeSkipped for such a node.
            * Failed - Configuration of the node has failed.  TestNode must raise
              AtNodeFailed for such a node.
            * End of Collection - The node is past the end of the collection.  TestNode must
              raise AtEndOfCollection.

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
            PretestWaitForTestExternal

            # Configure Phase (No Progress)
            ConfigureDispatch
            ConfigureWaitForTestExternal
            ConfigureWaitForSetExternal

            # Configure Phase (Progress)
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

            # Configure Phase (No Progress)
            StartConfigure
            StartConfigureResourceSet
            SkipConfigureResourceTest
            StartConfigureResourceTest
            EndConfigureResourceSuccess
            EndConfigureResourceFailed
            MoveConfigureNextResource

            # Configure Phase (Progress)
            StartConfigureProgressResourceSet
            StartConfigureProgressResourceTest
            SkipConfigureProgressResourceTest
            EndConfigureProgressResource
            MoveConfigureProgressNextResource
            StartNewConfigurePass

            End
        }

        $states = @(

            @{
                StateName = [State]::IdleExternal
                IsDefaultState = $true
            }

            # Pretest Phase
            @{
                StateName = [State]::PretestDispatch
                EntryActions = $TestNode
            }
            @{ StateName = [State]::PretestWaitForTestExternal }

            # Configure Phase (No Progress)
            @{
                StateName = [State]::ConfigureDispatch
                EntryActions = $TestNode
            }
            @{ StateName = [State]::ConfigureWaitForTestExternal }
            @{ StateName = [State]::ConfigureWaitForSetExternal }

            # Configure Phase (Progress)
            @{
                StateName = [State]::ConfigureProgressDispatch
                EntryActions = $TestNode
            }
            @{ StateName = [State]::ConfigureProgressWaitForTestExternal }
            @{ StateName = [State]::ConfigureProgressWaitForSetExternal }


            @{ StateName = [State]::Ended }
        ) | New-State

        $transitions = @(

            # Pretest Phase
            @{
                TransitionName = [Transition]::StartPretest
                Triggers = [Event]::Start
                SourceStateName = [State]::IdleExternal
                TargetStateName = [State]::PretestDispatch
                TransitionActions = $MoveNext
            }
            @{
                TransitionName = [Transition]::StartResourcePretest
                Triggers = [Event]::AtNodeReady,[Event]::AtNodeNotReady
                SourceStateName = [State]::PretestDispatch
                TargetStateName = [State]::PretestWaitForTestExternal
            }
            @{
                TransitionName = [Transition]::EndResourcePretest
                Triggers = [Event]::TestCompleteSuccess,[Event]::TestCompleteFailure,
                           [Event]::StepSkipped,[Event]::TestThrew
                SourceStateName = [State]::PretestWaitForTestExternal
                TargetStateName = [State]::PretestDispatch
                TransitionActions = $MoveNext
            }

            # Configure Phase (No Progress)
            @{
                TransitionName = [Transition]::StartConfigure
                Triggers = [Event]::AtEndOfCollection
                SourceStateName = [State]::PretestDispatch
                TargetStateName = [State]::ConfigureDispatch
                TransitionActions = $Reset,$MoveNext
            }
            @{
                TransitionName = [Transition]::StartConfigureResourceSet
                Triggers = [Event]::AtNodeReady
                SourceStateName = [State]::ConfigureDispatch
                TargetStateName = [State]::ConfigureWaitForSetExternal
            }
            @{
                TransitionName = [Transition]::SkipConfigureResourceTest
                Triggers = [Event]::StepSkipped
                SourceStateName = [State]::ConfigureWaitForSetExternal
                TargetStateName = [State]::ConfigureDispatch
            }
            @{
                TransitionName = [Transition]::StartConfigureResourceTest
                Triggers = [Event]::SetComplete,[Event]::SetThrew
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
                Triggers = [Event]::TestCompleteFailure,[Event]::StepSkipped,[Event]::TestThrew
                SourceStateName = [State]::ConfigureWaitForTestExternal
                TargetStateName = [State]::ConfigureDispatch
            }
            @{
                TransitionName = [Transition]::MoveConfigureNextResource
                Triggers = [Event]::AtNodeComplete,[Event]::AtNodeNotReady,
                           [Event]::AtNodeSkipped,[Event]::AtNodeFailed,
                           [Event]::AtNodeException
                SourceStateName = [State]::ConfigureDispatch
                TargetStateName = [State]::ConfigureDispatch
                TransitionActions = $MoveNext
            }

            # Configure Phase (Progress)
            @{
                TransitionName = [Transition]::StartConfigureProgressResourceSet
                Triggers = [Event]::AtNodeReady
                SourceStateName = [State]::ConfigureProgressDispatch
                TargetStateName = [State]::ConfigureProgressWaitForSetExternal
            }
            @{
                TransitionName = [Transition]::SkipConfigureProgressResourceTest
                Triggers = [Event]::StepSkipped
                SourceStateName = [State]::ConfigureProgressWaitForSetExternal
                TargetStateName = [State]::ConfigureProgressDispatch
            }
            @{
                TransitionName = [Transition]::StartConfigureProgressResourceTest
                Triggers = [Event]::SetComplete,[Event]::SetThrew
                SourceStateName = [State]::ConfigureProgressWaitForSetExternal
                TargetStateName = [State]::ConfigureProgressWaitForTestExternal
            }
            @{
                TransitionName = [Transition]::EndConfigureProgressResource
                Triggers = [Event]::TestCompleteSuccess,[Event]::TestCompleteFailure,
                           [Event]::StepSkipped,[Event]::TestThrew
                SourceStateName = [State]::ConfigureProgressWaitForTestExternal
                TargetStateName = [State]::ConfigureProgressDispatch
            }
            @{
                TransitionName = [Transition]::MoveConfigureProgressNextResource
                Triggers = [Event]::AtNodeComplete,[Event]::AtNodeNotReady,
                           [Event]::AtNodeSkipped,[Event]::AtNodeFailed,
                           [Event]::AtNodeException
                SourceStateName = [State]::ConfigureProgressDispatch
                TargetStateName = [State]::ConfigureProgressDispatch
                TransitionActions = $MoveNext
            }
            @{
                TransitionName = [Transition]::StartNewConfigurePass
                Triggers = [Event]::AtEndOfCollection
                SourceStateName = [State]::ConfigureProgressDispatch
                TargetStateName = [State]::ConfigureDispatch
                TransitionActions = $Reset,$MoveNext
            }


            @{
                TransitionName = [Transition]::End
                Triggers = [Event]::AtEndOfCollection
                SourceStateName = [State]::ConfigureDispatch
                TargetStateName = [State]::Ended
            }
        ) | New-Transition

        return New-StateMachine $states $transitions $ActionArgs
    }
}
