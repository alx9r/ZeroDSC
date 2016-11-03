class BoundResourceBase {
    [ResourceConfigInfo]
    $Config
}
class BoundResource : BoundResourceBase {
    [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]
    $Resource
}
class BoundAggregate : BoundResourceBase {}

function ConvertTo-BoundResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        [ResourceConfigInfo]
        $Config,

        [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]
        $Resource
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
        }

        $outputObject.Config = $Config


        return $outputObject
    }
}