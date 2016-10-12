function Assert-ValidConfigPath 
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline=$true)]
        $String
    )
    process{}
}
function ConvertTo-ConfigPath
{
    [CmdletBinding()]
    param
    (
        [ValidateScript({$_ | Assert-ValidResourceName})]
        [ValidateNotNullOrEmpty()]
        [string]
        $ResourceName,
        
        [ValidateScript({$_ | Assert-ValidConfigName})]
        [ValidateNotNullOrEmpty()]
        [string]
        $ConfigName
    )
    process {}
}
function Get-ConfigPathPart 
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline=$true)]
        $String,

        [ValidateSet('ResourceName','ConfigName')]
        $PartName
    )
    process{}
}
function Assert-ValidResourceName
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline=$true)]
        $String
    )
    process{}
}
function Assert-ValidConfigName
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline=$true)]
        $String
    )
    process{}
}
