function New-ConfigObject
{
    [CmdletBinding()]
    param
    (
        [ValidateScript({$_ | >> | Test-ValidResourceParams})]
        [hashtable]
        $Params,

        [Parameter(Mandatory = $true)]
        [ValidateScript({$_ | Test-ValidResourceName})]
        [ValidateNotNullOrEmpty()]
        [string]
        $ResourceName,

        [Parameter(Mandatory = $true)]
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
            ClassId      = '9ce982ff-9d3f-449c-9aa2-0c245e25c590'
        }
    }
}
function Test-ValidConfigObject
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline=$true)]
        $InputObject
    )
    process
    {
        $validClassIds = @(
            '9ce982ff-9d3f-449c-9aa2-0c245e25c590'
            '2c3cf8e0-d16b-49e2-a2c4-9a2c1a999a1b'
        )
        $cp = &(gcp)
        if 
        ( $validClassIds -notcontains $InputObject.ClassId )
        {
            &(Publish-Failure 'bad configuration object','InputObject' ([System.ArgumentException]))
            return $false
        }
        ($InputObject.Params       | Test-ValidResourceParams @cp ) -and
        ($InputObject.ResourceName | Test-ValidResourceName @cp )
    }
}