function Test-ValidAggregateTypeName
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        [string]
        $TypeName
    )
    process
    {
        if ( $TypeName -notin 'Count' )
        {
            &(Publish-Failure "$TypeName is not a valid aggregate type name",'TypeName' ([System.ArgumentException]))
            return $false
        }

        return $true
    }
}

function Test-ValidAggregateTest
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        [string]
        $Test
    )
    process
    {
        if ( $Test -notin '-eq 0','-gt 0' )
        {
            &(Publish-Failure "$Test is not a valid aggregate test",'Test' ([System.ArgumentException]))
            return $false
        }

        return $true
    }
}
