class SmTransition
{
    [string] $TransitionName
    [string[]] $Triggers
    [string] $SourceStateName
    [string] $TargetStateName
    [scriptblock[]] $TransitionActions
}

class SmState
{
    [string] $StateName
    
    [System.Collections.Generic.Dictionary[string,SmTransition]]
    $TransitionList = [System.Collections.Generic.Dictionary[string,SmTransition]]::new()
    
    [scriptblock[]] $EntryActions
    [scriptblock[]] $ExitActions
    [bool]  $IsDefaultState
}

class StateMachine
{
    [System.Collections.Generic.Dictionary[string,SmState]] 
    $StateList = [System.Collections.Generic.Dictionary[string,SmState]]::new()
    
    [System.Collections.Generic.Queue[string]] 
    $TriggerQueue = [System.Collections.Generic.Queue[string]]::new()
    
    [SmState] $CurrentState
    [SmState] $PreviousState

    RaiseEvent ( [string] $EventName )
    {
        $this | Add-Event $EventName
    }

    RunAllQueued () 
    {
        $this | Invoke-RunAllQueued
    }
    RunNext ()
    {
        $this | Invoke-RunNext
    }
}

function Add-Event
{
    [CmdletBinding()]
    param
    (
        [parameter(ValueFromPipeline = $true)]
        [StateMachine]
        $StateMachine,

        [parameter(position = 1)]
        [string]
        $EventName
    )
    process
    {
        $StateMachine.TriggerQueue.Enqueue($EventName) | Out-Null
    }
}


function Invoke-RunNext
{
    [CmdletBinding()]
    param
    (
        [parameter(ValueFromPipeline = $true)]
        [StateMachine]
        $StateMachine
    )
    process
    {
        # check for an empty event queue
        if ( -not $StateMachine.TriggerQueue.Count )
        {
            return
        }

        # get the oldest event
        $eventName = $StateMachine.TriggerQueue.Dequeue()

        # event is not a trigger
        if ( -not $StateMachine.CurrentState.TransitionList.ContainsKey($eventName) )
        {
            return
        }

        try
        {
            # prepare the actions' invocation context variable
            $functions = @{
                RaiseEvent = { param($EventName) $StateMachine.RaiseEvent($EventName) }
            }

            # invoke the exit actions
            foreach ( $action in $StateMachine.CurrentState.ExitActions )
            {
                $action.InvokeWithContext($functions,$null) | Out-Null
            }

            # extract the transition
            $transition = $StateMachine.CurrentState.TransitionList.$eventName

            # invoke the transition actions
            foreach ( $action in $transition.TransitionActions )
            {
                $action.InvokeWithContext($functions,$null) | Out-Null
            }

            # extract the next state
            $nextState = $StateMachine.StateList.$($transition.TargetStateName)

            # invoke the entry actions
            foreach ( $action in $nextState.EntryActions )
            {
                $action.InvokeWithContext($functions,$null) | Out-Null
            }
        }
        catch
        {
            # don't change state if one of the actions threw an exception
            return
        }

        # move to the next state
        $StateMachine.CurrentState = $StateMachine.StateList.$($transition.TargetStateName)
    }
}

function Invoke-RunAllQueued
{
    [CmdletBinding()]
    param
    (
        [parameter(ValueFromPipeline = $true)]
        [StateMachine]
        $StateMachine
    )
    process
    {
        while ( $StateMachine.TriggerQueue.Count )
        {
            $StateMachine | Invoke-RunNext
        }
    }
}

function New-State
{
    [CmdletBinding()]
    [OutputType([SmState])]
    param
    (
        [parameter(ValueFromPipeline = $true)]
        [hashtable]
        $InputObject
    )
    process
    {
        New-Object SmState -Property $InputObject

        if ( -not $InputObject.ContainsKey('StateName' ) )
        {
            throw [System.ArgumentException]::new(
                "Missing mandatory parameter StateName",
                'InputObject'
            )
        }
    }
}

function New-Transition
{
    [CmdletBinding()]
    [OutputType([SmTransition])]
    param
    (
        [parameter(ValueFromPipeline = $true)]
        [hashtable]
        $InputObject
    )
    process
    {
        $outputObject = New-Object SmTransition -Property $InputObject

        'TransitionName','Triggers','SourceStateName','TargetStateName' |
            ? { -not $InputObject.ContainsKey($_) } |
            % {
                throw [System.ArgumentException]::new(
                    "Missing mandatory parameter $_",
                    'InputObject'
                )
            }

        return $outputObject
    }
}

function New-StateMachine
{
    [CmdletBinding()]
    [OutputType([StateMachine])]
    param
    (
        [Parameter(position = 1)]
        [SmState[]]
        $States,

        [Parameter(position = 2)]
        [SmTransition[]]
        $Transitions
    )
    process
    {
        $outputObject = [StateMachine]::new()

        foreach ( $state in $States )
        {

            # duplicate state names
            if ( $outputObject.StateList.ContainsKey($state.StateName) )
            {
                throw [System.ArgumentException]::new(
                    "Duplicate StateName $($state.StateName)",
                    'States'
                )
            }

            # populate statelist
            $outputObject.StateList.$($state.StateName) = $state

            # populate CurrentState
            if ( $state.IsDefaultState )
            {
                # duplicate default state
                if ( $outputObject.CurrentState )
                {
                    throw [System.ArgumentException]::new(
                        "Second default state found in state $($state.StateName)",
                        'States'
                    )
                }

                $outputObject.CurrentState = $state
            }
        }

        # no default state
        if ( -not $outputObject.CurrentState )
        {
            throw [System.ArgumentException]::new(
                "No default state found",
                'States'
            )
        }

        foreach ( $transition in $Transitions )
        {
            # non-existent source state
            if ( -not $outputObject.StateList.ContainsKey($transition.SourceStateName) )
            {
                throw [System.ArgumentException]::new(
                    "Non-existent source state $($transition.SourceStateName) in transition $($transition.TransitionName)",
                    'Transitions'
                )
            }

            # non-existent target state
            if ( -not $outputObject.StateList.ContainsKey($transition.TargetStateName) )
            {
                throw [System.ArgumentException]::new(
                    "Non-existent target state $($transition.TargetStateName) in transition $($transition.TransitionName)",
                    'Transitions'
                )                
            }

            # duplicate transition
            if ( $outputObject.StateList.$($transition.SourceStateName).TransitionList.ContainsKey($transition.Triggers) )
            {
                throw [System.ArgumentException]::new(
                    "Duplicate transition state '$($transition.SourceStateName)' trigger '$($transition.Triggers)'",
                    'Transitions'
                )
            }

            # populate transition lists
            foreach ( $trigger in $transition.Triggers )
            {
                $outputObject.StateList.$($transition.SourceStateName).TransitionList.$trigger = $transition
            }
        }

        return $outputObject
    }
}
