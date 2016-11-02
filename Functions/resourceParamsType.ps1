class ResourceParamsBase {
    [string] $_ComputerName = $($this | Add-Member ScriptProperty 'ComputerName' {
            $this._ComputerName
        } {
            param( [string] $ComputerName )
            $ComputerName | Test-ValidDomainName -ErrorAction Stop
            $this._ComputerName = $ComputerName
        })

    [string[]] $_DependsOn = $($this | Add-Member ScriptProperty 'DependsOn' {
            $this._DependsOn
        } {
            param ( [string[]] $DependsOn )
            $DependsOn | Test-ValidConfigPath -ErrorAction Stop
            $this._DependsOn = $DependsOn
        })

    [hashtable] $Params = @{}
}
class ResourceParams : ResourceParamsBase {
    [pscredential] $PSRunAsCredential
}
class AggregateParams : ResourceParamsBase {
    [string] $_Type = $($this | Add-Member ScriptProperty 'Type' {
            $this._Type
        } {
            param( [string] $Type )
            $Type | Test-ValidAggregateTypeName -ErrorAction Stop
            $this._Type = $Type
        })

    [string] $_Test = $($this | Add-Member ScriptProperty 'Test' {
            $this._Test
        } {
            param( [string] $Test )
            $Test | Test-ValidAggregateTest -ErrorAction Stop
            $this._Test = $Test
        })
}