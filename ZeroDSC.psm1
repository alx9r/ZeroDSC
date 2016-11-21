Import-Module PSDesiredStateConfiguration,ToolFoundations

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

# Export all the functions and module members here.
# Use the module manifest to filter exported module members.
Export-ModuleMember -Function * -Alias *