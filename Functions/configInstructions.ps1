function ConfigInstructions
{
    [CmdletBinding()]
    param
    (
        [Parameter(position = 1)]
        [string]
        $Name,

        [Parameter(position = 2)]
        [scriptblock]
        $Scriptblock
    )
    process
    {
        return New-RawConfigDocument $Name $Scriptblock |
            ConvertTo-ConfigDocument |
            New-ConfigInstructions
    }
}
