$record = @{}

$guid = [guid]::NewGuid().Guid
$tempPath = "$([System.IO.Path]::GetTempPath())FileResourceTest"

Describe 'File' {
    Context 'setup' {
        $fqClassName = @{
            Namespace = 'root/microsoft/windows/DesiredStateConfiguration'
            ClassName = 'MSFT_FileDirectoryConfiguration'
        }
        It 'get the class' {
            $record.MSFT_FileDirectoryConfiguration = Get-CimClass @fqClassName
            $record.MSFT_FileDirectoryConfiguration |
                Should not beNullOrEmpty
        }
        if ( -not $record.MSFT_FileDirectoryConfiguration )
        {
            It 'start a session with elevated credentials' {
                $record.ElevatedSession = New-CimSession -Credential (
                    Get-Credential -Message 'elevated credential to access MSFT_FileDirectoryConfiguration class'
                )
            }
            It 'get the class with other credentials' {
                $record.MSFT_FileDirectoryConfiguration = Get-CimClass @fqClassName -CimSession $record.ElevatedSession
                $record.MSFT_FileDirectoryConfiguration |
                    Should not beNullOrEmpty                
            }
        }
        It 'the class is of type CimClass' {
            $record.MSFT_FileDirectoryConfiguration |
                Should beOfType ([cimclass])
        }
        It 'create the input instance' {
            $record.InputResource = [ciminstance]::new($record.MSFT_FileDirectoryConfiguration)
            $record.InputResource |
                Should not beNullOrEmpty
        }
        It 'the input instance is of type MSFT_FileDirectoryConfiguration' {
            $r = $record.InputResource | 
                Get-Member |
                Select -First 1
            $r.TypeName |
                Should be 'Microsoft.Management.Infrastructure.CimInstance#ROOT/microsoft/windows/DesiredStateConfiguration/MSFT_FileDirectoryConfiguration'
        }
        It 'set the properties of the input instance' {
            $record.InputResource.DestinationPath = "$tempPath\$guid.txt"
            $record.InputResource.Contents = 'some contents'
        }
        It 'there is no file is at the destination' {
            Test-Path "$tempPath\$guid.txt" |
                Should be $false
        }
    }
    Context 'invocation' {
        $splat = @{
            CimClass = $record.MSFT_FileDirectoryConfiguration
            Arguments = @{
                Flags = 0 # Uint32 "Flags passed to the providers. Reserved for future use."
                InputResource = $record.InputResource
            }
        }        
        It 'invoke Test() [1]' {
            $record.Test1 = Invoke-CimMethod TestTargetResource @splat
            $record.Test1 | Should not beNullOrEmpty
        }
        It 'result is false' {
            $record.Test1.Result |
                Should be $false
        }
        It 'theres is still no file is at the destination' {
            Test-Path "$tempPath\$guid.txt" |
                Should be $false
        }
        It 'invoke Get() [1]' {
            $record.Get1 = Invoke-CimMethod GetTargetResource @splat
            $record.Get1 | Should not beNullOrEmpty
        }
        It 'invoke Set() [1]' {
            $record.Set1 = Invoke-CimMethod SetTargetResource @splat
            $record.Set1 | Should not beNullOrEMpty
        }
        It 'invoke Test() [2]' {
            $record.Test2 = Invoke-CimMethod TestTargetResource @splat
            $record.Test2 | Should not beNullOrEmpty
        }
        It 'result is true' {
            $record.Test2.Result |
                Should be $true
        }
        It 'theres is a file is at the destination' {
            Test-Path "$tempPath\$guid.txt" |
                Should be $true
        }
        It 'the contents are correct' {
            Get-Content "$tempPath\$guid.txt" |
                Should be 'some contents'
        }
        It 'invoke Get() [2]' {
            $record.Get2 = Invoke-CimMethod GetTargetResource @splat
            $record.Get2 | Should not beNullOrEmpty
        }
        It 'change the Contents property of the InputResource' {
            $record.InputResource.Contents = 'new contents'
        }
        It 'invoke Test() [3]' {
            $record.Test3 = Invoke-CimMethod TestTargetResource @splat
            $record.Test3 | Should not beNullOrEmpty
        }
        It 'result is false' {
            $record.Test3.Result |
                Should be $false
        }
        It 'invoke Set() [3]' {
            $record.Set3 = Invoke-CimMethod SetTargetResource @splat
            $record.Set3 | Should not beNullOrEMpty
        }
        It 'theres is a file is at the destination' {
            Test-Path "$tempPath\$guid.txt" |
                Should be $true
        }
        It 'the contents are correct' {
            Get-Content "$tempPath\$guid.txt" |
                Should be 'new contents'
        }
    }
    Context 'cleanup' {
        It "remove $guid.txt" {
            Remove-Item "$tempPath\$guid.txt" -Force -ea Stop
        }
    }
}
