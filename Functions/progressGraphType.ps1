enum Progress
{
    Complete
    Pending
    SetButNotTested
    Failed
    Undefined
}
class ProgressNode {
    [Progress] $Progress = [Progress]::Pending
    [BoundResourceBase] $Resource
}
class ProgressGraph {
    [System.Collections.Generic.Dictionary[string,ProgressNode]] 
    $Resources = [System.Collections.Generic.Dictionary[string,ProgressNode]]::new()

    $ResourceEnumerator

    [ConfigPhase]
    $Phase = [ConfigPhase]::Pretest

    [ConfigStep] GetNext()
    {
        return $this | Get-NextConfigStep
    }
}

function Get-NextConfigStep
{
    [CmdletBinding()]
    [OutputType([ConfigStep])]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        [ProgressGraph]
        $ProgressGraph
    )
    process
    {
        # move to the next node except when we've set but haven't tested
        if ( -not ([Progress]::SetButNotTested -eq $ProgressGraph.ResourceEnumerator.Value.Progress) )
        {
            $end = -not $ProgressGraph.ResourceEnumerator.MoveNext()
        }

        # terminate
        if 
        ( 
            $end -and
            [ConfigPhase]::Configure -eq $ProgressGraph.Phase 
        )
        {
            return $null
        }

        # if the iterator is at end start at the beginning again
        if ( $end )
        {
            $ProgressGraph.ResourceEnumerator.Reset()
            $ProgressGraph.ResourceEnumerator.MoveNext() | Out-Null
        }

        # advance from Pretest to Configure phase
        if ( $end -and $ProgressGraph.Phase -eq [ConfigPhase]::Pretest )
        {
            $ProgressGraph.Phase = [ConfigPhase]::Configure
        }

        # return a Test step
        if 
        ( 
            [ConfigPhase]::Pretest -eq $ProgressGraph.Phase -or
            (
                [ConfigPhase]::Configure -eq $ProgressGraph.Phase -and
                [Progress]::SetButNotTested -eq $ProgressGraph.ResourceEnumerator.Value.Progress
            )
        )
        {
            return $ProgressGraph.ResourceEnumerator.Value |
                New-ConfigStep Test $ProgressGraph.Phase
        }

        # return a Set step
        if ( [ConfigPhase]::Configure -eq $ProgressGraph.Phase )
        {
            return $ProgressGraph.ResourceEnumerator.Value |
                New-ConfigStep Set $ProgressGraph.Phase
        }
    }
}

function New-ConfigStep
{
    [CmdletBinding()]
    [OutputType([ConfigStep])]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        [ProgressNode]
        $Node,

        [Parameter(position = 1)]
        [ConfigStepType]
        $Mode,

        [Parameter(position = 2)]
        [ConfigPhase]
        $Phase
    )
    process
    {
        $message = "$Mode $($Node.Resource.Config.GetConfigPath())"

        $scriptblock = {
            # save the initial state for later
            $progressBefore = $Node.Progress

            # set progress to undefined in case invokation throws an exception
            $Node.Progress = [Progress]::Undefined

            # invoke the resource
            $raw = $Node.Resource.Invoke($Mode)

            # create the results object
            $splat = @{
                Raw = $raw
                Message = $message
                Type = $Mode
            }
            $results = New-ConfigStepResult @splat

            # update the node's progress
            $Node.Progress = @{
                [ConfigStepType]::Set = @{
                    [ConfigStepResultCode]::Unknown = @{
                        # progress before     ===>    progress after
                        [Progress]::Pending =         [Progress]::SetButNotTested
                    }
                }
                [ConfigStepType]::Test = @{
                    [ConfigStepResultCode]::Success = @{
                        [Progress]::Pending =         [Progress]::Complete
                        [Progress]::SetButNotTested = [Progress]::Complete
                    }
                    [ConfigStepResultCode]::Failure = @{
                        [Progress]::Pending =         [Progress]::Pending
                        [Progress]::SetButNotTested = [Progress]::Failed
                    }
                }
            }.$Mode.$($results.Code).$progressBefore

            # return the results object
            return $results
        }.GetNewClosure()

        return New-Object ConfigStep -Property @{
            Message = $message
            Phase = $Phase
            Invoker = $scriptblock
        }
    }
}

function ConvertTo-ProgressGraph
{
    [CmdletBinding()]
    [OutputType([ProgressGraph])]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        [ConfigDocument]
        $InputObject
    )
    process
    {
        $outputObject = [ProgressGraph]::new()

        # convert resources to ProgressNodes
        foreach ( $key in $InputObject.Resources.Keys )
        {
            $value = $InputObject.Resources.$key
            $node = [ProgressNode]::new()
            $node.Progress = 'Pending'
            $node.Resource = $value
            $outputObject.Resources.Add($key,$node)
        }

        $outputObject.ResourceEnumerator = $outputObject.Resources.GetEnumerator()

        return $outputObject
    }
}