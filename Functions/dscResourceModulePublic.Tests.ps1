Import-Module ZeroDsc -Force

Describe 'Import-DscResource dynamic keyword still works' {
    It 'build configuration artifacts' {
        configuration TestConfiguration
        {
            Import-DscResource -Name TestStub -ModuleName ZeroDSC
            TestStub a
            {
                Key = 'a'
            }
        }

        $r = TestConfiguration -OutputPath ([System.IO.Path]::GetTempPath())
        $r | Should not beNullOrEmpty
        $r.GetType().Name | Should be 'FileInfo'
    }
}
