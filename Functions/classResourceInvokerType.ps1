class ClassResourceInvoker : ResourceInvoker 
{
    $ResourceObject

    ClassResourceInvoker(
        [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]
        $ResourceInfo
    ) : base ( $ResourceInfo )
    {
        $this.ResourceObject = $this.ResourceInfo |
            New-ClassResourceObject
    }

    [object] Get( [hashtable] $Params )
    {
        $splat = @{
            Mode = 'Get'
            Params = $Params
            ResourceObject = $this.ResourceObject
        }
        return Invoke-ClassResourceCommand @splat
    }

    Set( [hashtable] $Params )
    {
        $splat = @{
            Mode = 'Set'
            Params = $Params
            ResourceObject = $this.ResourceObject
        }
        Invoke-ClassResourceCommand @splat
    }

    [bool] Test( [hashtable] $Params )
    {
        $splat = @{
            Mode = 'Test'
            Params = $Params
            ResourceObject = $this.ResourceObject
        }
        return Invoke-ClassResourceCommand @splat
    }
}

function New-ClassResourceObject
{
    [CmdletBInding()]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]
        $DscResource
    )
    process
    {
        foreach ( $module in ( @(
                $DscResource.Module
                $DscResource.Module.NestedModules
            ) | ? {$_} ) 
        )
        {
            $module | Import-Module
            try
            {
                $object = iex @"
                    using module $($module.Path)
                    [$($DscResource.ResourceType)]::new()
"@
            }
            catch [System.Management.Automation.RuntimeException]
            {
                if ( $_.Exception -notmatch 'Unable to find type' )
                {
                    throw
                }
            }

            # did we find an object?
            if ( -not $object )
            {
                continue
            }

            # check for the three requisite methods
            $getMethod = Get-Member -InputObject $object -MemberType Method -Name Get
            $setMethod = Get-Member -InputObject $object -MemberType Method -Name Set
            $testMethod = Get-Member -InputObject $object -MemberType Method -Name Test
            if ( -not $getMethod -or -not $setMethod -or -not $testMethod )
            {
                continue
            }

            # check for the DscResource() attribute
            if ( -not (
                    $object.GetType().CustomAttributes | 
                        ? { $_.AttributeType -eq ([System.Management.Automation.DscResourceAttribute]) } 
                )
            )
            {
                continue
            }

            return $object
        }

        throw "Could not create class resource object for DSC Resource $($DscResource.ResourceType)"
    }
}

function Invoke-ClassResourceCommand
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 1)]
        [ValidateSet('Get','Set','Test')]
        $Mode,

        [hashtable]
        $Params,

        $ResourceObject
    )
    process
    {
        $propertyNames = $ResourceObject | Get-Member -MemberType Property | % Name
        foreach ( $key in $Params.Keys )
        {
            if ( $key -notin $propertyNames )
            {
                continue
            }
            $ResourceObject.$key = $Params.$key
        }

        $ResourceObject.$Mode()
    }
}
