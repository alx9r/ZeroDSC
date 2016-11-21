Import-Module PSDesiredStateConfiguration

$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path

# dot source the external dependencies...
"$moduleRoot\External\*.ps1" |
    Get-Item |
    ? { $_.Name -notmatch 'Tests\.ps1$' } |
    % { . $_.FullName }

# ...then the type files...
. "$moduleRoot\Functions\LoadTypes.ps1"

# ...and then the remaining .ps1 files
"$moduleRoot\Functions\*.ps1" |
    Get-Item |
    ? {
        $_.Name -notmatch 'Tests\.ps1$' -and
        $_.Name -notmatch 'Types?\.ps1$'
    } |
    % { . $_.FullName }


if ( $args[0] -eq 'ExportAll' )
{
    # This option is provided to streamline testing of
    # non-public module members.
    Export-ModuleMember -Function * -Alias *
}
else
{
    # the list of module members to export by default
    Export-ModuleMember -Function @(
        'Import-DscResource'
        'New-RawConfigDocument'
        'ConvertTo-ConfigDocument'
        'New-ConfigInstructions'
        'Invoke-ConfigStep'

        'New-ResourceInvoker'
    )
}