class _ConfigInstructions : System.Collections.IEnumerable {
    [System.Collections.IEnumerator] GetEnumerator () {
        return [_ConfigInstructionEnumerator]::new()
    }
}
class ConfigInstructions : _ConfigInstructions,System.Collections.Generic.IEnumerable[ConfigStep]{
    [ConfigDocument] $ConfigDocument

    [System.Collections.Generic.IEnumerator[ConfigStep]] GetEnumerator ()
    {
        return [ConfigInstructionEnumerator]::new($this.ConfigDocument)
    }

    ConfigInstructions ( [ConfigDocument] $ConfigDocument )
    {
        $this.ConfigDocument = $ConfigDocument
    }
}

function New-ConfigInstructions
{
    [CmdletBinding()]
    [OutputType([ConfigInstructions])]
    param
    (
        [parameter(ValueFromPipeline = $true)]
        [ConfigDocument]
        $ConfigDocument
    )
    process
    {
        ,[ConfigInstructions]::new($ConfigDocument)
    }
}

enum Event
{
    Start

    # Test Node
    AtEndOfCollection
    AtNodeReady
    AtNodeNotReady
    AtNodeComplete
    AtNodeSkipped
    AtNodeFailed

    # Test Resource
    TestCompleteSuccess
    TestCompleteFailure

    # Set Resource
    SetComplete
}

class _ConfigInstructionEnumerator : System.Collections.IEnumerator {
    [System.Collections.Generic.Dictionary[string,ProgressNode]] 
    $Nodes

    $NodeEnumerator

    [StateMachine] $StateMachine

    [ConfigStep] $CurrentStep

    _ConfigInstructionEnumerator ( [ConfigDocument] $ConfigDocument )
    {
        $this.Nodes = $ConfigDocument.Resources | New-ProgressNodes
        $this.NodeEnumerator = $this.Nodes.GetEnumerator()
        $this.InitializeStateMachine()
        $this.StateMachine.RaiseEvent([Event]::Start)
    }

    InitializeStateMachine ()
    {
        # scriptblock that tests the current node's progress
        # and raises a state machine event accordingly
        $testNode = { 
            if
            (
                $null -eq $this.NodeEnumerator.Value -and
                -not $this.NodeEnumerator.MoveNext()
            )
            {
                RaiseEvent( [Event]::AtEndOfCollection )
                return
            }

            if ( [Progress]::Complete -eq $this.NodeEnumerator.Value.Progress )
            {
                RaiseEvent( [Event]::AtNodeComplete )
                return
            }

            if ( [Progress]::Skipped -eq $this.NodeEnumerator.Value.Progress )
            {
                RaiseEvent( [Event]::AtNodeSkipped )
                return
            }

            if ( [Progress]::Failed -eq $this.NodeEnumerator.Value.Progress )
            {
                RaiseEvent( [Event]::AtNodeFailed )
                return
            }

            if ( $this.NodeEnumerator.Key | Test-DependenciesMet $this.Nodes )
            {
                RaiseEvent( [Event]::AtNodeReady )
                return
            }

            RaiseEvent ( [Event]::AtNodeNotReady )
        }

        # scriptblock that moves to the next node
        $moveNext = { $this.NodeEnumerator.MoveNext() }

        # scriptblock that resets the enumerator
        $reset = { $this.NodeEnumerator.Reset() }

        # variables that will be available inside the above scripblocks
        $variables = Get-Variable 'this'

        $this.StateMachine = New-ConfigStateMachine $testNode $moveNext $reset $variables
    }

    [object] _get_Current()
    {
        return Get-CurrentConfigStep -InputObject $this
    }

    [object] get_Current ()
    {
        return $this._get_Current()
    }

    [bool] MoveNext () 
    {
        return Move-NextConfigStep -Enumerator $this
    }

    Reset ()
    {
        $this.Nodes | Reset-ProgressNodes
        $this.NodeEnumerator.Reset()
        $this.StateMachine.Reset()
        $this.StateMachine.RaiseEvent('Start')
    }
    Dispose () {}
}

class ConfigInstructionEnumerator : _ConfigInstructionEnumerator,System.Collections.Generic.IEnumerator[ConfigStep]
{
    ConfigInstructionEnumerator ( [ConfigDocument] $ConfigDocument ) : base( $ConfigDocument ) {}

    [ConfigStep] get_Current () 
    {
        return ([ConfigInstructionEnumerator]$this)._get_Current() 
    }
}

function New-ConfigInstructionEnumerator
{
    [CmdletBinding()]
    [OutputType([ConfigInstructionEnumerator])]
    param
    (
        [parameter(ValueFromPipeline = $true)]
        [ConfigDocument]
        $ConfigDocument
    )
    process
    {
        return ,[ConfigInstructionEnumerator]::new($ConfigDocument)
    }
}

function Move-NextConfigStep
{
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
        [ConfigInstructionEnumerator]
        $Enumerator
    )
    process
    {
        # the current step has not been invoked
        if 
        (
            $Enumerator.StateMachine.CurrentState.StateName -match
            '(Pretest|Configure).*External' -and
            -not $Enumerator.CurrentStep.Invoked
        )
        {
            # mark the node as skipped
            $Enumerator.NodeEnumerator.Value.Progress = 'Skipped'

            # raise the skipped event
            $Enumerator.StateMachine.RaiseEvent('StepSkipped')
        }

        # clear the reference to the config step
        $Enumerator.CurrentStep = $null

        # process to end of internal events
        $Enumerator.StateMachine | Invoke-RunAllQueued

        if ( $Enumerator.StateMachine.CurrentState.StateName -eq 'Ended' )
        {
            return $false
        }
        return $true
    }
}

function Get-CurrentConfigStep
{
    [CmdletBinding()]
    [OutputType([ConfigStep])]
    param
    (
        [Parameter(Position = 1)]
        [ConfigInstructionEnumerator]
        $InputObject
    )
    process
    {
        # if node enumerator is not pointing to an object, return null
        if ( $null -eq $InputObject.NodeEnumerator.Key )
        {
            return $null
        }

        # extract the verb from the state name
        $verb = @{
            PretestWaitForTestExternal = 'Test'
            ConfigureWaitForTestExternal = 'Test'
            ConfigureWaitForSetExternal = 'Set'
            ConfigureProgressWaitForTestExternal = 'Test'
            ConfigureProgressWaitForSetExternal = 'Set'
        }.$($InputObject.StateMachine.CurrentState.StateName)

        # extract the phase from the state name
        $phase = @{
            PretestWaitForTestExternal = 'Pretest'
            ConfigureWaitForTestExternal = 'Configure'
            ConfigureWaitForSetExternal = 'Configure'
            ConfigureProgressWaitForTestExternal = 'Configure'
            ConfigureProgressWaitForSetExternal = 'Configure'
        }.$($InputObject.StateMachine.CurrentState.StateName)

        # create the output object and populate some fields
        $outputObject = New-Object ConfigStep -Property @{
            ResourceName = $InputObject.NodeEnumerator.Key
            Message = "$verb resource $($InputObject.NodeEnumerator.Key)"
            Verb = $verb
            Phase = $phase
            StateMachine = $InputObject.StateMachine
            Node = $InputObject.NodeEnumerator.Value
        }

        # populate the action
        $outputObject.Action = @{
            Test = { 
                # invoke the test
                $result = $resource.Resource.Invoke('Test')

                # raise the completion event
                RaiseEvent(@{
                    $false = 'TestCompleteFailure'
                    $true = 'TestCompleteSuccess'
                }.([bool]$result))

                # report the node's progress
                $resource.Progress = @{
                    Pretest = @{
                        $false = 'Pending'
                        $true = 'Complete'
                    }
                    Configure = @{
                        $false = 'Failed'
                        $true = 'Complete'
                    }
                }.$phase.([bool]$result)

                return $result
            }
            Set = {
                # invoke the set
                $resource.Resource.Invoke('Set')

                # raise the completion event
                RaiseEvent('SetComplete')
            }
        }.$verb

        # populate the action arguments
        $resource = $InputObject.NodeEnumerator.Value
        $outputObject.ActionArgs = Get-Variable 'resource','phase'

        # keep a reference
        $InputObject.CurrentStep = $outputObject

        return $outputObject
    }
}

function Invoke-ConfigStep
{
    [CmdletBinding()]
    [OutputType([ConfigStepResult])]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        [ConfigStep]
        $ConfigStep
    )
    process
    {
        # prepare the actions' invocation context
        $functions = @{
            RaiseEvent = { param($EventName) $ConfigStep.StateMachine.RaiseEvent($EventName) }
        }

        # invoke the action
        $result = $ConfigStep.Action.InvokeWithContext($functions,$ConfigStep.ActionArgs)

        # mark the step as invoked
        $ConfigStep.Invoked = $true

        # return the result object
        return New-Object ConfigStepResult -Property @{
            Message = $ConfigStep.Message + ' Complete'
            Step = $ConfigStep
            Result = $result
        }
    }
}
