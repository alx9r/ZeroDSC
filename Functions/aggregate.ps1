function Aggregate 
{
    [CmdletBinding()]
    param
    (
        $ConfigName,
        
        [ValidateScript({$_ | >> | Assert-ValidAggregateParams})]
        [hashtable]
        $Params
    )
    process {
        $splat = @{
            Params = $Params
            ResourceName = 'Aggregate'
            ConfigName   = $ConfigName
        }
        New-PrereqObject @splat
    }
}
function Assert-ValidAggregateParams
{
    [CmdletBinding()]
    param
    (
        [ValidateSet('Count')]
        $Type,

        [ValidateString({$_ | Assert-ValidAggregateTestString})]
        [string]
        $Test,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]
        $Name
    )
    process
    {
        $true
    }
}
function Assert-ValidAggregateTestString
{
    [CmdletBinding()]
    param
    (
        [ValidateSet('-gt 0','-eq 0')]
        $String
    )
    process { $true }
}
function Test-Aggregate
{
    [CmdletBinding()]
    param
    (
        [hashtable]
        $Instructions,

        [string]
        $ConfigPath,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]
        $Name
    )
    process {}
}