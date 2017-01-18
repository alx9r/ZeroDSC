class ClassResourceInvoker : ResourceInvoker
{
    hidden $ResourceObject

    ClassResourceInvoker(
        [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]
        $ResourceInfo
    ) : base ( $ResourceInfo )
    {
        $this.ResourceObject = $this.ResourceInfo |
            New-ClassResourceObject
    }

    hidden [object] _Invoke ( [string] $Mode, [hashtable] $Params )
    {
        $splat = @{
            Mode = $Mode
            Params = $Params
            ResourceObject = $this.ResourceObject
        }
        return Invoke-ClassResourceCommand @splat
    }
}


function Test-ClassResourceType
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
        try
        {
            $DscResource |
                New-ClassResourceObject |
                Out-Null
            return $true
        }
        catch
        {
            return $false
        }
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

            # $module isn't always a fully-populated object at this point
            # We get the loaded modules(s) of the right name and select the
            # one at the right path.
            $liveModule = Get-Module $module.Name |
                ? { $_.ModuleBase -eq $module.ModuleBase } |
                Select -First 1

            try
            {
                $object = $liveModule.NewBoundScriptBlock(
                    [scriptblock]::Create("[$($DscResource.Name)]::new()")
                ).InvokeReturnAsIs()
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

        throw "Could not create class resource object for DSC Resource $($DscResource.Name)"
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

        $result = $ResourceObject.$Mode()

        if ( $null -eq $result )
        {
            return $null
        }
        return $result
    }
}
