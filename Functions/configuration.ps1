function New-ConfigDocument 
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
        $ConfigDocument = [RawConfigDocument]::new($Name)
        foreach ( $item in $items )
        {
            $ConfigDocument.Add($item)
        }
        return $ConfigDocument
    }
}