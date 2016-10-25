Import-Module ZeroDsc -Force

$records = @{}
$guid1 = [guid]::NewGuid().Guid
$guid2 = [guid]::NewGuid().Guid
$tempPath = "$([System.IO.Path]::GetTempPath())xArchiveTest"

Describe xArchive {
    It 'create working folder' {
        New-Item $tempPath -ItemType Directory -ea SilentlyContinue
        Test-Path $tempPath -PathType Container |
            Should be $true
    }
    It 'set up source file' {
        $guid1 | Set-Content "$tempPath\src.txt" -ea Stop
        $splat = @{
            Path = "$tempPath\src.txt"
            DestinationPath = "$tempPath\src.zip"
        }
        Compress-Archive @splat -Force -ea Stop
    }
    Context 'direct use of Expand-Archive' {
        It 'expand source file' {
            $splat = @{
                Path = "$tempPath\src.zip"
                DestinationPath = "$tempPath\dst"
            }
            Expand-Archive @splat -Force -ea Stop
        }
        It 'check the contents of the resultant file' {
            $r = Get-Content "$tempPath\dst\src.txt" -ea Stop
            $r | Should be $guid1
        }
    }
    Context 'using xArchive' {
        $p =  @{
            Path = "$tempPath\src.zip"
            Destination = "$tempPath\dst"
            Validate = $true
            Force = $true
        }
        It 'create invoker' {
            $records.Invoker = Get-DscResource xArchive | New-ResourceInvoker
        }
        It 'Test-TargetResource is true' {
            $r = $records.Invoker.Test($p)
            $r | Should be $true
        }
        It 'Set-TargetResource works' {
            $records.Invoker.Set($p)
        }
        It 'Test-TargetResource is still true' {
            $r = $records.Invoker.Test($p)
            $r | Should be $true
        }
        It 'change the source file' {
            $guid2 | Set-Content "$tempPath\src.txt" -ea Stop
            $splat = @{
                Path = "$tempPath\src.txt"
                DestinationPath = "$tempPath\src.zip"
            }
            Compress-Archive @splat -Force -ea Stop
        }
        It 'Test-TargetResource is false' {
            $r = $records.Invoker.Test($p)
            $r | Should be $false
        }
        It 'Set-TargetResource works' {
            $records.Invoker.Set($p)
        }
        It 'Test-TargetResource is true again' {
            $r = $records.Invoker.Test($p)
            $r | Should be $true
        }
    }
}