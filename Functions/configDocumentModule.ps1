function New-ConfigDocumentModule
{
    New-Module {
        'Import-DscResource','New-RawResourceConfigInfo','Aggregate' |
            % {
                Set-Item Function:\Import-DscResource (
                    [scriptblock]::Create(
                        (Get-Item Function:\Import-DscResource).ScriptBlock
                    )
                ) -Force
            }
        Set-Alias Aggregate New-RawResourceConfigInfo
    }
}
