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

    Add( $item )
    {
        if ( $item -is [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo] )
        {
            $this.DscResources.Add($item.ResourceType,$item)
            return
        }
        if ( $item -is [ResourceConfigInfo] )
        {
            $this.ResourceConfigs.Add($item.GetConfigPath(), $item)
            return
        }
        throw 'Could not add $item because it is an unrecognized type.'
    }
}
