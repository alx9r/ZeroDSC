class ResourceConfigInfo {
    [hashtable] $Params
    [string] $ResourceName
    [string] $ConfigName
}

class AggregateConfigInfo : ResourceConfigInfo {}

Set-Alias Aggregate New-ResourceConfigInfo

function New-ResourceConfigInfo
{
    [CmdletBinding()]
    param
    (
        [ValidateNotNullOrEmpty()]
        [string]
        $ConfigName,

        [ValidateNotNull()]
        [hashtable]
        $Params
    )
    process
    {
        $resourceName = $PSCmdlet.MyInvocation.Line | Get-ResourceNameFromInvocationLine
        if ( $resourceName -eq 'Aggregate' )
        {
            $configInfo = [AggregateConfigInfo]::new()
        }
        else
        {
            $configInfo = [ResourceConfigInfo]::new()
        }
        $configInfo.Params = $Params
        $configInfo.ConfigName = $ConfigName
        $configInfo.ResourceName = $resourceName
        return $configInfo
    }
}

function Get-ResourceNameFromInvocationLine
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        [string]
        $String
    )
    process
    {
        $regex = [regex]'^\s*(?<ResourceName>[^\f\n\r\t\v\x85\p{Z}`]*)'
        $match = $regex.Match($String)
        (ConvertFrom-RegexNamedGroupCapture -Match $match -Regex $regex).ResourceName
    }
}