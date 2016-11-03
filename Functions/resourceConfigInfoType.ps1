class RawResourceConfigInfo {
    [hashtable] $Params
    [string] $ConfigName
    [System.Management.Automation.InvocationInfo]$InvocationInfo
}

class ResourceConfigInfo {
    [ResourceParamsBase] $Params

    hidden [string] $_ResourceName = $($this | Add-Member ScriptProperty 'ResourceName' { 
            # get
            $this._ResourceName
        } { 
            # set
            param ( [string] $ResourceName )
            $ResourceName | Test-ValidResourceName -ErrorAction Stop
            $this._ResourceName = $ResourceName
        })

    hidden [string] $_ConfigName = $($this | Add-Member ScriptProperty 'ConfigName' {
            # get
            $this._ConfigName
        } { 
            # set
            param ( [string] $ConfigName )
            $ConfigName | Test-ValidConfigName -ErrorAction Stop
            $this._ConfigName = $ConfigName
        })

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

        # Process and assign the properties such that the call site of an
        # offending configuration document is included in exception.
        foreach ( $propertyName in 'ConfigName','ResourceName','Params' )
        {
            try
            {
                $sb = @{
                    ConfigName = { $outputObject.ConfigName = $InputObject.ConfigName }
                    ResourceName = { $outputObject.ResourceName = $resourceName }
                    Params = { 
                        $outputObject.Params = $InputObject.Params | 
                            ConvertTo-ResourceParams $InputObject.ConfigName 
                    }
                }.$propertyName 

                & $sb | Out-Null
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

        # return the output object
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