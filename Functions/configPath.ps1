function Test-ValidConfigPath 
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline=$true)]
        $String
    )
    process
    {
        if ( $String -eq [string]::Empty )
        {
            return $true
        }
        if ( $String -eq $null )
        {
            return $true
        }

        $cp = &(gcp)
        (Get-ConfigPathPart ResourceName | Test-ValidResourceName @cp) -and
        (Get-ConfigPathPart ConfigName   | Test-ValidConfigName @cp)
    }
}
function ConvertTo-ConfigPath
{
    [CmdletBinding()]
    param
    (
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
        return "[$ResourceName]$ConfigName"
    }
}
function Get-ConfigPathPart 
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline=$true)]
        $String,

        [Parameter(Position = 1,
                   Mandatory = $true)]
        [ValidateSet('ResourceName','ConfigName')]
        $PartName
    )
    process
    {
        $regex = [regex]'^\[(?<ResourceName>.*)\](?<ConfigName>.*)$'
        $match = $regex.Match($String)
        (ConvertFrom-RegexNamedGroupCapture -Match $match -Regex $regex).$PartName
    }
}
function Test-ValidResourceName
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline=$true)]
        $String
    )
    process
    {
        if ( [string]::Empty,$null -contains $String )
        {
            &(Publish-Failure 'ResourceName cannot be Null or Empty String','String' ([System.ArgumentException]))
            return $false
        }
        if ( $String -notmatch '^[0-9a-zA-Z]*$' )
        {
            &(Publish-Failure "$String is not a valid ResourceName",'String' ([System.ArgumentException]))
            return $false
        }
        return $true
    }
}
function Test-ValidConfigName
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline=$true)]
        $String
    )
    process
    {
        if ( [string]::Empty,$null -contains $String )
        {
            &(Publish-Failure 'ConfigName cannot be Null or Empty String','String' ([System.ArgumentException]))
            return $false
        }
        if ( $String -notmatch '^[0-9a-zA-Z]*$' )
        {
            &(Publish-Failure "$String is not a valid ConfigName",'String' ([System.ArgumentException]))
            return $false
        }
        return $true
    }
}
