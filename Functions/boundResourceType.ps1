class BoundResourceBase {
    [ResourceConfigInfo]
    $Config
}
class BoundResource : BoundResourceBase {
    [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]
    $Resource

    [ResourceInvoker]
    $Invoker
}
class BoundAggregate : BoundResourceBase {}

function ConvertTo-BoundResource
{
    [CmdletBinding()]
    param
    (
        [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]
        $Resource,

        [Parameter(ValueFromPipeline = $true)]
        [ResourceConfigInfo]
        $Config
    )
    process
    {
        if
        ( 
            $Config -isnot [AggregateConfigInfo] -and
            -not $Resource
        )
        {
            throw New-Object System.ArgumentException(
                'Resource argument is missing',
                'Resource'
            )
        }

        if
        (
            $Config -is [AggregateConfigInfo] -and
            $Resource
        )
        {
            throw New-Object System.ArgumentException(
                'Resource argument was provided for aggregate Config',
                'Resource'
            )
        }

        if ( $Config -is [AggregateConfigInfo] )
        {
            $outputObject = [BoundAggregate]::new()      
        }
        else
        {
            $outputObject = [BoundResource]::new()
            $outputObject.Resource = $Resource
            $outputObject.Invoker = $Resource | New-ResourceInvoker
        }

        $outputObject.Config = $Config


        return $outputObject
    }
}