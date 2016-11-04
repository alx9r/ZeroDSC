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
    [OutputType([ConfigInfo])]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        [RawConfigInfo]
        $InputObject
    )
    process
    {
        $outputObject = [ConfigInfo]::new()
        $outputObject.Name = $InputObject.Name

        # put the resources into a temporary dictionary
        $resources = New-Object 'System.Collections.Generic.Dictionary`2[System.String,Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]'
        foreach ( $resource in $InputObject.DscResources )
        {
            # check for duplicate resource names
            if ( $resources.ContainsKey( $resource.Name ) )
            {
                throw New-Object System.FormatException(
                    "Duplicate resource named $($resource.Name)"
                )  
            }

            $resources.($resource.Name) = $resource
        }

        # convert the raw configurations, then bind each one to its corresponding resource
        foreach ( $rawConfig in $InputObject.ResourceConfigs )
        {
            # create the structured object from the raw configuration
            $config = $rawConfig | ConvertTo-ResourceConfigInfo
            
            # compose the ConfigPath
            $configPath = $config | ConvertTo-ConfigPath

            # check for duplicate config path
            if ( $outputObject.Resources.ContainsKey($configPath) )
            {
                throw New-Object System.FormatException(
                    @"
Duplicate ConfigPath $configPath
$($config.InvocationInfo.PositionMessage)
"@
                )                
            }

            try
            {
                # bind the structured object to the resource
                $outputObject.Resources.$configPath = $config | ConvertTo-BoundResource -Resource $resources.($config.ResourceName)
            }
            catch
            {
                throw New-Object System.FormatException(
                    @"
Error binding Config $configPath to resource $($config.ResourceName)
$($config.InvocationInfo.PositionMessage)
$($_.Exception.Message)
"@
                )
            }
        }

        return $outputObject
    }
}