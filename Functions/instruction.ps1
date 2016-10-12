function ConvertTo-Instructions
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        [ValidateScript({$_ | Asset-ValidConfigObject})]
        $InputObject
    )
    begin
    {
        $instructions = @{}
    }
    process
    {
        $configPath = ConvertTo-ConfigPath $InputObject.ResourceName $InputObject.ConfigName
        $instructions.$configPath = @{
            ConfigObject = $InputObject
            Params       = $InputObject.Params
            SetCommandName  = "Set-$($InputObject.ResourceName)"
            TestCommandName = "Test-$($InputObject.ResourceName)"
            DependsOn    = $InputObject.Params.DependsOn
            TestOnly     = $InputObject.Params.TestOnly
        }

    }
    end
    {
        return $instructions
    }
}
