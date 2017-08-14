function ConfigInstructions
{
    [CmdletBinding()]
    param
    (
        [Parameter(position = 1,
                   Mandatory = $true)]
        [string]
        $Name,

        [Parameter(position = 2,
                   Mandatory = $true)]
        [scriptblock]
        $Scriptblock,

        [Parameter(ValueFromPipeline = $true)]
        [hashtable]
        $NamedArgs = @{},

        [object[]]
        $ArgumentList = @()
    )
    process
    {
        $splat = @{
            Name = $Name
            Scriptblock = $Scriptblock
            NamedArgs = $NamedArgs
            ArgumentList = $ArgumentList
        }
        return New-RawConfigDocument @splat |
            ConvertTo-ConfigDocument |
            New-ConfigInstructions
    }
}
