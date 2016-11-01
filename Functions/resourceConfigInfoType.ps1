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

Set-Alias Aggregate New-ResourceConfigInfo

function New-ResourceConfigInfo
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ConfigName,

        [ValidateNotNull()]
        [hashtable]
        $Params
    )
    process
    {
        $resourceName = $PSCmdlet.MyInvocation.Line | Get-ResourceNameFromInvocationLine
        if ( $resourceName -eq 'Aggregate' )
        {
            $configInfo = [AggregateConfigInfo]::new()
        }
        else
        {
            $configInfo = [ResourceConfigInfo]::new()
        }
        $configInfo.Params = $Params
        $configInfo.ConfigName = $ConfigName
        $configInfo.ResourceName = $resourceName
        return $configInfo
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