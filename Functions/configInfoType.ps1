class ConfigInfo
{
    [string]
    $Name

    [System.Collections.Generic.Dictionary`2[System.String,Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]]
    $DscResources

    [System.Collections.Generic.Dictionary`2[System.String,ResourceConfigInfo]]
    $ResourceConfigs

    ConfigInfo([string] $name) 
    {
        $this.Name = $name
        $this.DscResources = New-Object "System.Collections.Generic.Dictionary``2[System.String,Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]"
        $this.ResourceConfigs = New-Object "System.Collections.Generic.Dictionary``2[System.String,ResourceConfigInfo]"
    }

    Add( [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo] $item )
    {
        $this.DscResources.Add($item.ResourceType,$item)
    }

    Add( [ResourceConfigInfo] $item )
    {
        $this.ResourceConfigs.Add(($item | ConvertTo-ConfigPath), $item)
    }
}
