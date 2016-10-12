function Test-ValidResourceParams
{
    [CmdletBinding()]
    param
    (
        [ValidateScript({$_ | Test-ValidConfigPath})]
        [ValidateNotNullOrEmpty()]
        [string]
        $DependsOn,

        [bool]
        $TestOnly
    )
    process
    {
        $true
    }
}