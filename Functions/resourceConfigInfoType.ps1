class ResourceConfigInfo {
    [hashtable] $Params
    [string] $ResourceName
    [string] $ConfigName
}

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
        $configInfo = [ResourceConfigInfo]::new()
        $configInfo.Params = $Params
        $configInfo.ConfigName = $ConfigName
        $configInfo.ResourceName = $PSCmdlet.MyInvocation.Line | Get-ResourceNameFromInvocationLine
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