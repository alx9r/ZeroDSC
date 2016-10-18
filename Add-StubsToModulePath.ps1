$resourcesFolder = "$(Split-Path $PSCommandPath -Parent)\Resources"
$modulePathFolders = $env:PSModulePath.Split(';')
if ( $resourcesFolder -notin $modulePathFolders )
{
    $env:PSModulePath = "$env:PSModulePath;$resourcesFolder"
}