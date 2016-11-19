enum Progress
{
    Undefined
    Complete
    Pending
    Failed
    Skipped
}
class ProgressNode {
    [Progress] $Progress = [Progress]::Pending
    [BoundResourceBase] $Resource
}

function New-ProgressNodes
{
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.Dictionary[string,ProgressNode]])]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        [System.Collections.Generic.Dictionary[System.String,BoundResourceBase]]
        $InputObject
    )
    process
    {
        $outputObject = [System.Collections.Generic.Dictionary[string,ProgressNode]]::new()

        # convert resources to ProgressNodes
        foreach ( $key in $InputObject.Keys )
        {
            $value = $InputObject.$key
            $node = [ProgressNode]::new()
            $node.Progress = 'Pending'
            $node.Resource = $value
            $outputObject.Add($key,$node)
        }
        return $outputObject
    }
}

function Reset-ProgressNodes
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        [System.Collections.Generic.Dictionary[System.String,ProgressNode]]
        $Nodes
    )
    process
    {
        foreach ( $node in $Nodes.GetEnumerator() )
        {
            $node.Value.Progress = [Progress]::Pending
        }
    }
}