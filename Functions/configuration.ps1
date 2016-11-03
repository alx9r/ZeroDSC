function zConfiguration 
{
    [CmdletBinding()]
    param
    (
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [scriptblock]
        $ScriptBlock
    )
    process 
    {
        $items = & (Get-Module ZeroDsc).NewBoundScriptBlock($ScriptBlock)
        $configInfo = [RawConfigInfo]::new($Name)
        foreach ( $item in $items )
        {
            $configInfo.Add($item)
        }
        return $configInfo
    }
}