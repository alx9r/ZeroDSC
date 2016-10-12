function New-ConfigurationObject
{
    [CmdletBinding()]
    param
    (
        [ValidateScript({$_ | Assert-ValidResourceParams})]
        [hashtable]
        $Params,

        [ValidateScript({$_ | Assert-ValidResourceName})]
        [ValidateNotNullOrEmpty()]
        [string]
        $ResourceName,

        [ValidateScript({$_ | Assert-ValidConfigName})]
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
            ClassId      = '9ce982ff-9d3f-449c-9aa2-0c245e25c590'
        }
    }
}
function Assert-ValidConfigObject
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline=$true)]
        $InputObject
    )
    process
    {
        if ( $InputObject.ClassId -ne '9ce982ff-9d3f-449c-9aa2-0c245e25c590' )
        {
            throw 'bad configuration object'
        }
        $InputObject.Params | Assert-ValidResourceParams
        $InputObject.ResourceName | Assert-ValidResourceName
    }
}