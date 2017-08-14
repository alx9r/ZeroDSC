function New-ConfigDocumentModule
{
    New-Module {
        'Import-DscResource' |
            % {
                Set-Item Function:\$_ (
                    [scriptblock]::Create(
                        (Get-Item Function:\$_).ScriptBlock
                    )
                ) -Force
            }

        function Invoke-InModule {
            param
            (
                [Parameter(Position = 1)]
                [scriptblock]
                $Scriptblock,

                [Parameter(Position = 2)]
                $ArgumentList = @(),

                [Parameter(Position = 3)]
                [hashtable]
                $NamedArgs = @{}
            )

            & $Scriptblock @ArgumentList @NamedArgs
        }
    }
}
