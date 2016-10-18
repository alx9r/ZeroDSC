function Import-ZeroDscModule
{
    param
    (
        $Name
    )
    process
    {
        # import the module by name
        $module = Import-Module $Name -PassThru

        try
        {
            # import its nested modules, they might be required by the
            # resources in this module
            $module | 
                % NestedModules | 
                Import-Module

            # extract the resource names
            $resourceNames = Get-ChildItem "$($module.Path)\DSCResources" -Directory

            foreach ( $name in $resourceNames )
            {
                # import each resource as a module
                Get-DscResource $name |
                        % Path |
                        Import-Module
            }
            # assert that each resource is valid
            $resourceNames | Assert-ValidZeroDscResource

            # create the config function for each resource
            $resourceNames | Set-DscResourceConfigFunction
        }
        finally
        {
            # remove the module
            $module | Remove-Module
        }
    }
}
function Assert-ValidZeroDscResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        $Name
    )
    process
    {
        $dscResource = Get-DscResource $Name

        if ( $dscResource.ImplementedAs -ne 'PowerShell' )
        {
            throw 'must be a PowerShell DscResource'
        }

        $dscResource.Path | Import-Module        
    }
}
function Set-DscResourceConfigFunction
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        $Name
    )
    process
    {
    }
}