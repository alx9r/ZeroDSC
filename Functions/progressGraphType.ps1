enum Progress
{
    Complete
    Pending
    Failed
}
class ProgressNode {
    [Progress] $Progress = [Progress]::Pending
    [BoundResourceBase] $Resource
}
class ProgressGraph {
    [System.Collections.Generic.Dictionary[string,ProgressNode]] 
    $Resources = [System.Collections.Generic.Dictionary[string,ProgressNode]]::new()

    $ResourceEnumerator

    [bool]
    $ProgressMadeThisPass = $false

    [ConfigStep] GetNext()
    {
        return $this | Get-NextConfigStep
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
        $end = -not ($ProgressGraph.ResourceIterator.MoveNext())
        
        if ( $end -and -not $ProgressGraph.ProgressMadeThisPass)
        {
            # nothing left to do
            return $null
        }

        if ( $end )
        {
            $ProgressGraph.ResourceIterator.Reset()
            $ProgressGraph.ResourceIterator.MoveNext()
        }

        # advance to first resource that's ready and needs invoking
        while 
        (
            -not $ProgressGraph.ResourceIterator.Current.Progress -eq [Progress]::Pending -and
            -not $ProgressGraph.ResourceIterator.Current.Resource.Config.Name |
                Test-DependenciesMet $ProgressGraph.Resources
        )
        {
            $ProgressGraph.ResourceIterator.MoveNext()
        }

        # populate the object
        $configStep = [ConfigStep]::new()
        $configStep.Invoker = {
            if ( $ProgressGraph.ResourceIterator.Current.Resource.Invoke('Test') )
            {
                $ProgressGraph.ResourceIterator.Current.Progress = [progress]::Complete
                return 'Already set'
            }
            
            $ProgressGraph.ResourceIterator.Current.Resource.Invoke('Set') | Out-Null

            if ( $ProgressGraph.ResourceIterator.Current.Resource.Invoke('Test') )
            {
                $ProgressGraph.ResourceIterator.Current.Progress = [progress]::Complete
                return 'Set succeeded'
            }

            $ProgressGraph.ResourceIterator.Current.Progress = [progress]::Failed
            return 'Set failed'
        }.GetNewClosure()

        return $configStep
    }
}
