function Import-ZeroDscModule
{
    param
    (
        $ModuleName
    )
    process
    {
        Import-Module $ModuleName | Out-Null
        $module = Get-Module $ModuleName
        $module | % NestedModules | Import-Module
        $resourceNames = Get-ChildItem "$($module.Path)\DSCResources" -Directory

        foreach ( $name in $resourceNames )
        {
            Get-DscResource $name |
                    % Path |
                    Import-Module
            Assert-ValidZeroDscResource $name
            Set-DscResourceConfigFunction $name
        }        
    }
}
function Assert-ValidZeroDscResource
{
    param
    (
        $ModuleName
    )
    process
    {
        $dscResource = Get-DscResource $ModuleName

        if ( $dscResource.ImplementedAs -ne 'PowerShell' )
        {
            throw 'must be a PowerShell DscResource'
        }

        $dscResource.Path | Import-Module        
    }
}
function Set-DscResourceConfigFunction
{
    param
    (
        $ModuleName
    )
    process
    {
    }
}