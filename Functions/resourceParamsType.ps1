class ResourceParamsBase {
    hidden [string[]] $_DependsOn = (Accessor $this {
            get
            set {
                param ( [string[]] $DependsOn )
                $DependsOn | Test-ValidConfigPath -ErrorAction Stop
                $this._DependsOn = $DependsOn
            }
        })

    [hashtable] $Params = @{}
}
class ResourceParams : ResourceParamsBase {
    hidden [string] $_ComputerName = (Accessor $this {
        get
        set {
            param( [string] $ComputerName )
            $ComputerName | Test-ValidDomainName -ErrorAction Stop
            $this._ComputerName = $ComputerName
        }
    })

    [pscredential] $PSRunAsCredential
}
class AggregateParams : ResourceParamsBase {
    hidden [string] $_Type = (Accessor $this {
        get
        set {
            param( [string] $Type )
            $Type | Test-ValidAggregateTypeName -ErrorAction Stop
            $this._Type = $Type
        }
    })

    hidden [string] $_Test = (Accessor $this {
        get
        set {
            param( [string] $Test )
            $Test | Test-ValidAggregateTest -ErrorAction Stop
            $this._Test = $Test
        }
    })
}

function ConvertTo-ResourceParams
{
    [CmdletBinding()]
    param
    (
        [string]
        $ResourceName,

        [Parameter(ValueFromPipeline = $true)]
        [hashtable]
        $Params
    )
    process
    {
        # create the right type of object
        if ( $ResourceName -eq 'Aggregate' )
        {
            $outputObject = [AggregateParams]::new()
        }
        else
        {
            $outputObject = [ResourceParams]::new()
        }

        # assign from Params hashtable entries to object properties
        foreach
        (
            $propertyName in (
                $outputObject |
                    gm -MemberType *Property |
                    ? {$_.Name -notlike '_*' } |
                    % Name
            )
        )
        {
            if ( $propertyName -notin $Params.Keys )
            {
                continue
            }
            $outputObject.$propertyName = $Params.$propertyName
            $Params.Remove($propertyName) | Out-Null
        }

        # assign what remains of the hashtable to the output object
        $outputObject.Params = $Params

        # confirm that mandatory properties are populated
        if ( $ResourceName -eq 'Aggregate' )
        {
            foreach ( $propertyName in 'Type','Test' )
            {
                if ( $null -eq $outputObject.$propertyName )
                {
                    throw [System.ArgumentException]::new(
                        "Params is missing mandatory entry $propertyName",
                        'Params'
                    )
                }
            }
        }

        return $outputObject
    }
}
