Import-Module ZeroDsc #-Force

Describe 'Test Environment' {
    It 'add the test stubs to PSModulePath' {
        . "$($PSCommandPath | Split-Path -Parent)\..\Add-StubsToModulePath.ps1"
    }
}

$records = @{}
Describe 'Detect whether module is loaded.' {
    foreach ( $dscResource in Get-DscResource -Module StubResourceModule* )
    {
        $records.($dscResource.Name) = @{}
        $record = $records.($dscResource.Name)
        Context "DSC Resource $($dscResource.Name)" {
            function OmitExtension {
                param( $path )
                return $path.Substring(0,$path.LastIndexOf('.'))
            }
            It 'the DSC Resource type is correct' {
                $dscResource.GetType() |
                    Should be 'Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo'
            }
            It 'path property exists' {
                $record.ResourcePath = $dscResource.Path
                $record.ResourcePath | Should not beNullOrEmpty
            }
            It 'path exists' {
                $record.ResourcePath |
                    Test-Path |
                    Should be $true
            }
            It 'import the path as a module' {
                $record.ModuleInfo = $record.ResourcePath |
                    Import-Module -PassThru
            }
            It 'the module info type is correct' {
                $record.ModuleInfo.GetType() |
                    Should be 'psmoduleinfo'
            }
            It 'the DscResourceInfo and ModuleInfo paths match if extension is omitted' {
                $record.ModuleInfoPathWithoutExtension = OmitExtension $record.ModuleInfo.Path
                $record.ModuleInfoPathWithoutExtension | Should not beNullOrEmpty
                $record.DscResourceInfoPathWithoutExtension = OmitExtension $record.ResourcePath
                $record.DscResourceInfoPathWithoutExtension | Should not beNullOrEmpty
                $record.ModuleInfoPathWithoutExtension |
                    Should be $record.DscResourceInfoPathWithoutExtension
            }
            It 'the module can be found by its path with extension omitted' {
                $r = Get-Module |
                    ? { (OmitExtension $_.Path) -eq (OmitExtension $dscResource.Path) }
                $r.Count | Should be 1
                $r | Should not beNullOrEmpty
            }
            It 'remove the module using results of import' {
                $record.ModuleInfo | Remove-Module
            }
            It 'the module can no longer be found by its path' {
                $r = Get-Module |
                    ? { (OmitExtension $_.Path) -eq (OmitExtension $dscResource.Path) }
                $r | Should beNullOrEmpty
            }
        }
    }
}
