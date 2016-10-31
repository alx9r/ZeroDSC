
try
{
    $splat = @{
        Namespace = 'root/microsoft/windows/DesiredStateConfiguration'
        ClassName = 'MSFT_FileDirectoryConfiguration'
    }
    Get-CimClass @splat -ea Stop | Out-Null
    . "$($PSCommandPath | Split-Path -Parent)\FileTests.ps1"
}
catch [Microsoft.Management.Infrastructure.CimException]
{
}