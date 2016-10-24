function Get-ResourceModule
{
    param
    (
        [ValidateNotNull()]
        $Name
    )
    process
    {
        try
        {
            $Name = [string]($Name | Resolve-Path -ErrorAction Stop)
        }
        catch {}
        foreach ( $module in (Get-Module) )
        {
            if ( $module.Name -eq $Name -or $module.Path -eq $Name )
            {
                $module
                continue
            }
            
            try
            {
                if ( $Name -eq (Get-FriendlyNameFromMof "$($module.ModuleBase)\$($module.Name).schema.mof") )
                {
                    $module
                    continue
                }
            }
            catch {}
        }
    }
}
function Get-ResourceNameFromImplementingAssembly
{
    param
    (
        [ValidateNotNullOrEmpty()]
        [psmoduleinfo]
        $Module
    )
    process
    {
        $Module.ImplementingAssembly.DefinedTypes |
            ? { 
                $_.CustomAttributes |
                    ? { $_.AttributeType.Name -eq 'DscResourceAttribute' }
            } |
            % Name
    }
}
function Get-ResourceNameFromDscResourcesFolder
{
    param
    (
        [ValidateNotNullOrEmpty()]
        [psmoduleinfo]
        $Module
    )
    process
    {
        $folderNames = Get-ChildItem "$($Module.ModuleBase)\DSCResources" 
        
        foreach ( $folderName in $folderNames )
        {
            $mofPath = "$($Module.ModuleBase)\DSCResources\$folderName\$folderName.schema.mof"
            
            if ( -not ( Test-Path $mofPath -PathType Leaf ) )
            {
                continue
            }
            
            Get-FriendlyNameFromMof $mofPath
        }
    }
}
function Get-FriendlyNameFromMof
{
    param
    (
        $Path
    )
    process
    {
        $lines = Get-Content $Path -ErrorAction Stop
        $regex = [regex]'^\[.*FriendlyName\("(?<FriendlyName>.*)"\).*\]$'
        foreach ( $line in $lines )
        {
            $match = $regex.Match($line)
            if ( $match.Success )
            {
                return (ConvertFrom-RegexNamedGroupCapture -Match $match -Regex $regex).FriendlyName
            }
        }
    }
}