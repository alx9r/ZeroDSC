function zConfiguration 
{
    [CmdletBinding()]
    param
    (
        [scriptblock]
        $ScriptBlock
    )
    process {
        $configObjects = Invoke-ScriptBlock $ScriptBlock
        $configObjects | Assert-ValidConfigObject
        return $configObjects
    }
}