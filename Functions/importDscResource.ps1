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
            $resourceNames = Get-ChildItem "$($module.ModuleBase)\DSCResources" -Directory

            # get each resource
            $resources = $resourceNames | % { Get-DscResource $_ }

            # import each resource as a module
            $resources |
                % Path |
                Import-Module

            # extract friendly resource names
            $friendlyNames = $resources | % FriendlyName

            # assert that each resource is valid
            $friendlyNames | Assert-ValidZeroDscResource

            # create the config function for each resource
            $friendlyNames | Set-DscResourceConfigFunction
        }
        finally
        {
            # remove the module
            $module | Remove-Module
        }

        # import the nested modules again
        $module |
            % NestedModules |
            Import-Module
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
        # get the DSC resource
        $dscResource = Get-DscResource $Name

        # import the resource as a module
        $module = $dscResource.Path | Import-Module -PassThru

        # get the commands
        $getCommand = Get-Command -Name Get-TargetResource -Module $module.Name
        $setCommand = Get-Command -Name Set-TargetResource -Module $module.Name
        $testCommand = Get-Command -Name Test-TargetResource -Module $module.Name

        # compare their signatures
        Compare-Signatures $testCommand $setCommand -ErrorAction Stop
        Compare-Signatures $setCommand $getCommand -ErrorAction Stop

        # remove the resource as a module
        $module | Remove-Module
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
function Compare-Signatures
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 1)]
        [System.Management.Automation.FunctionInfo]
        $CommandA,

        [Parameter(Position = 2)]
        [System.Management.Automation.FunctionInfo]
        $CommandB
    )
    process {}
}
