function Test-Prerequisites
{
    [CmdletBinding()]
    param
    (
        [ValidateScript({$_ | Test-ValidConfigPath})]
        [string]
        $InstructionName,

        [hashtable]
        $Instructions
    )
    process {}
}
function Assert-ValidPrereqParams
{
    [CmdletBinding()]
    param
    (
        [ValidateScript({$_ | Assert-ValidConfigPath})]
        [ValidateNotNullOrEmpty()]
        [string]
        $DependsOn
    )
    process {}
}