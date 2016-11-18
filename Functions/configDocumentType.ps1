class RawConfigDocument
{
    [string]
    $Name

    [System.Collections.Generic.List[Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]]
    $DscResources = (New-Object System.Collections.Generic.List[Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo])

    [System.Collections.Generic.List[RawResourceConfigInfo]]
    $ResourceConfigs = (New-Object System.Collections.Generic.List[RawResourceConfigInfo])

    RawConfigDocument([string] $name) 
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

class ConfigDocument
{
    [string]
    $Name

    $Resources = [System.Collections.Generic.Dictionary[System.String,BoundResourceBase]]::new()
}

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
            if 
            (
                $item -isnot [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo] -and
                $item -isnot [RawResourceConfigInfo]
            )
            {
                throw [System.ArgumentException]::new(
                    "Invalid object type $($item.GetType().ToString()) emitted by Scriptblock.",
                    'Scriptblock'
                )
            }

            $ConfigDocument.Add($item)
        }
        return $ConfigDocument
    }
}

function ConvertTo-ConfigDocument
{
    [CmdletBinding()]
    [OutputType([ConfigDocument])]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        [RawConfigDocument]
        $InputObject
    )
    process
    {
        $outputObject = [ConfigDocument]::new()
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
            $configPath = $config.GetConfigPath()

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