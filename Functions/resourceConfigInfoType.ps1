class RawResourceConfigInfo {
    [hashtable] $Params
    [string] $ConfigName
    [System.Management.Automation.InvocationInfo]$InvocationInfo
}

class ResourceConfigInfo {
    [hashtable] $Params

    hidden [string] $_ResourceName = $($this | Add-Member ScriptProperty 'ResourceName' `
        { # get
            $this._ResourceName
        }`
        { # set
            param ( [string] $ResourceName )
            $ResourceName | Test-ValidResourceName -ErrorAction Stop
            $this._ResourceName = $ResourceName
        }
    )

    hidden [string] $_ConfigName = $($this | Add-Member ScriptProperty 'ConfigName' `
        { # get
            $this._ConfigName
        }`
        { # set
            param ( [string] $ConfigName )
            $ConfigName | Test-ValidConfigName -ErrorAction Stop
            $this._ConfigName = $ConfigName
        }
    )

    [string] GetConfigPath() 
    { 
        return ConvertTo-ConfigPath $this.ResourceName $this.ConfigName 
    }
}

class AggregateConfigInfo : ResourceConfigInfo {}

Set-Alias Aggregate New-RawResourceConfigInfo

function New-RawResourceConfigInfo
{
    [CmdletBinding()]
    param
    (
        [string]
        $ConfigName,

        [hashtable]
        $Params
    )
    process
    {
        $outputObject = [RawResourceConfigInfo]::new()
        $outputObject.Params = $Params
        $outputObject.ConfigName = $ConfigName
        $outputObject.InvocationInfo = $PSCmdlet.MyInvocation
        return $outputObject
    }
}

function ConvertTo-ResourceConfigInfo
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        [RawResourceConfigInfo]
        $InputObject
    )
    process
    {
        # try to extract the resource name
        $resourceName = $InputObject.InvocationInfo.Line | Get-ResourceNameFromInvocationLine
        
        # create the right object type
        if ( $resourceName -eq 'Aggregate' )
        {
            $outputObject = New-Object AggregateConfigInfo
        }
        else
        {
            $outputObject = New-Object ResourceConfigInfo
        }

        # validate properties
        foreach ( $propertyName in 'ConfigName','ResourceName' )
        {
            try
            {
                @{
                    ConfigName = $InputObject.ConfigName
                    ResourceName = $resourceName
                }.$propertyName | & "Test-Valid$propertyName" -ErrorAction Stop | Out-Null

            }
            catch 
            {
                throw New-Object System.FormatException(
                    @"
$propertyName Error
$($InputObject.InvocationInfo.PositionMessage)
$($_.Exception.Message)
"@
                )
            }
        }

        # assign the properties from the input object to the output object
        $outputObject.ConfigName = $InputObject.ConfigName
        $outputObject.ResourceName = $resourceName
        $outputObject.Params = $InputObject.Params

        # return the output obj
        return $outputObject
    }
}

function Get-ResourceNameFromInvocationLine
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        [string]
        $String
    )
    process
    {
        $regex = [regex]"^[\s]*(\$[a-z\(\)\.\']*)?(\s=\s)?(?<ResourceName>[^\f\n\r\t\v\x85\p{Z}`]*)"
        $match = $regex.Match($String)
        (ConvertFrom-RegexNamedGroupCapture -Match $match -Regex $regex).ResourceName
    }
}