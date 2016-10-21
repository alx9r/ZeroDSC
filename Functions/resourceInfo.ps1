function Get-ResourceName
{
    param
    (
        $ModuleName
    )
    process
    {
        
    }
}
function Get-ResourceModule
{
    param
    (
        $Name
    )
    process
    {
        Get-Module | ? {$_.Name -eq $Name -or $_.Path -eq $Name }
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
        $lines = Get-Content $Path
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