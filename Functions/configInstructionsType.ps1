#region IEnumerable
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
        [ConfigInstructions]::new($ConfigDocument)
    }
}
#endregion

class _ConfigInstructionEnumerator {
    [object] get_Current () { return ''.GetEnumerator() }
    [bool] MoveNext () { return $true }
    Reset () {}
    Dispose () {}
}

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

class ConfigInstructionEnumerator : _ConfigInstructionEnumerator,System.Collections.Generic.IEnumerator[ConfigStep] {
    [System.Collections.Generic.Dictionary[string,ProgressNode]] 
    $Nodes

    $NodeEnumerator

    [StateMachine] $StateMachine

    ConfigInstructionEnumerator ( [ConfigDocument] $ConfigDocument )
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

            if ( $this.NodeEnumerator.Key | Test-DependenciesMet )
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

        $this.StateMachine = New-ConfigStateMachine $testNode $moveNext $reset
    }

    [ConfigStep] get_Current ()
    {
        return Get-CurrentConfigStep -InputObject $this
    }

    [bool] MoveNext () 
    {
        $this.StateMachine | Invoke-RunAllQueued
        if ( $this.StateMachine.CurrentState.StateName -eq 'Ended' )
        {
            return $false
        }
        return $true
    }

    Reset ()
    {
        $this.Nodes | Reset-ProgressNodes
        $this.NodeEnumerator = $this.Nodes.GetEnumerator()
        $this.StateMachine.Reset()
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

function Get-CurrentConfigStep
{
    [CmdletBinding()]
    [OutputType([ConfigStep])]
    param
    (
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
            PretestWaitForExternalTest = 'Test'
            ConfigureWaitForTestExternal = 'Test'
            ConfigureWaitForSetExternal = 'Set'
            ConfigureProgressWaitForTestExternal = 'Test'
            ConfigureProgressWaitForSetExternal = 'Set'
        }.$($InputObject.StateMachine.CurrentState.StateName)

        # extract the phase from the state name
        $phase = @{
            PretestWaitForExternalTest = 'Pretest'
            ConfigureWaitForTestExternal = 'Configure'
            ConfigureWaitForSetExternal = 'Configure'
            ConfigureProgressWaitForTestExternal = 'Configure'
            ConfigureProgressWaitForSetExternal = 'Configure'
        }.$($InputObject.StateMachine.CurrentState.StateName)

        # create the output object
        $outputObject = [ConfigStep]::new()

        # populate the message
        $outputObject.Message = "$verb resource $($InputObject.NodeEnumerator.Key)"

        # populate the phase
        $outputObject.Phase = $phase

        return $outputObject
    }
}