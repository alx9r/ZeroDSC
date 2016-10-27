function ConvertTo-ZeroDscResourceModule
{
    param
    (
        [Parameter(ValueFromPipeline = $true,
                   Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]
        $DscResource
    )
    process
    {
        New-Module -Name (Get-DynamicModuleName $DscResource) -ScriptBlock (
            [scriptblock]::Create( @"
                function $($DscResource.ResourceType)
                {
                    $((Get-Item Function:\New-ResourceConfigInfo).Scriptblock)
                }
"@
            )
        )
    }
}

function Remove-ZeroDscResourceModule
{
    param
    (
        [Parameter(ValueFromPipeline = $true,
                   Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]
        $DscResource
    )
    process
    {
        $moduleName = $DscResource |
            Get-DynamicModuleName
        
        $moduleName | 
            Get-Module |
            Remove-Module

        Get-ChildItem function: |
            ? { $_.Source -eq $moduleName } |
            Remove-Item
    }
}

function Get-DynamicModuleName
{
    param
    (
        [Parameter(ValueFromPipeline = $true,
                   Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]
        $DscResource
    )
    process
    {
        return "$($DscResource.ResourceType)_$($DscResource.Version)-Dyn"
    }
}