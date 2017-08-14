Import-Module ZeroDsc #-Force
Import-Module PSDesiredStateConfiguration

Describe 'Import-DscResource dynamic keyword still works' {
    It 'build configuration artifacts' {
        Invoke-Expression @"
        configuration TestConfiguration
        {
            Import-DscResource -Name TestStub -ModuleName ZeroDSC -ModuleVersion $((Get-Module ZeroDsc).Version)
            TestStub a
            {
                Key = 'a'
            }
        }
"@

        $r = TestConfiguration -OutputPath ([System.IO.Path]::GetTempPath())
        $r | Should not beNullOrEmpty
        $r.GetType().Name | Should be 'FileInfo'
    }
}
