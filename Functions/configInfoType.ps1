class RawConfigInfo
{
    [string]
    $Name

    [System.Collections.Generic.List[Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]]
    $DscResources = (New-Object System.Collections.Generic.List[Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo])

    [System.Collections.Generic.List[RawResourceConfigInfo]]
    $ResourceConfigs = (New-Object System.Collections.Generic.List[RawResourceConfigInfo])

    RawConfigInfo([string] $name) 
    {
        $this.Name = $name
    }

    Add( [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo] $item )
    {
        $this.DscResources.Add($item)
    }

    Add ( [RawResourceConfigInfo]  $item )
    {
        $this.ResourceConfigs.Add($item)
    }
}

class ConfigInfo
{
    [string]
    $Name

    $Resources = (New-Object 'System.Collections.Generic.Dictionary`2[System.String,BoundResourceBase]')
}


function ConvertTo-ConfigInfo
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        [RawConfigInfo]
        $InputObject
    )
    process
    {
    }
}