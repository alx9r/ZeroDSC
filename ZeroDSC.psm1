Import-Module PSDesiredStateConfiguration #,ToolFoundations

$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path

# dot source the type files first
. "$moduleRoot\Functions\LoadTypes.ps1"

# then the other files
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