function New-PrereqObject
{
    [CmdletBinding()]
    param
    (
        [ValidateScript({$_ | Test-ValidPrereqParams})]
        [hashtable]
        $Params,

        [ValidateScript({$_ | Test-ValidResourceName})]
        [ValidateNotNullOrEmpty()]
        [string]
        $ResourceName,

        [ValidateScript({$_ | Test-ValidConfigName})]
        [ValidateNotNullOrEmpty()]
        [string]
        $ConfigName
    )
    process
    {
        New-Object psobject -Property @{
            Params       = $Params
            ResourceName = $ResourceName
            ConfigName   = $ConfigName
            ClassId      = '2c3cf8e0-d16b-49e2-a2c4-9a2c1a999a1b'
        }
    }
}
function Assert-ValidPrereqObject
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline=$true)]
        $InputObject
    )
    process
    {
        if ( $InputObject.ClassId -ne '2c3cf8e0-d16b-49e2-a2c4-9a2c1a999a1b' )
        {
            throw 'bad prerequisite object'
        }
        $InputObject.Params | Assert-ValidResourceParams
        $InputObject.ResourceName | Assert-ValidResourceName
    }
}