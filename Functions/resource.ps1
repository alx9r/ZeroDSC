function Assert-ValidResourceParams
{
    [CmdletBinding()]
    param
    (
        [ValidateScript({$_ | Assert-ValidConfigPath})]
        [ValidateNotNullOrEmpty()]
        [string]
        $DependsOn,

        [bool]
        $TestOnly
    )
    process {}
}