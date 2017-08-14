Import-Module ZeroDSC #-Force

InModuleScope ZeroDSC {
Describe Test-ConfigStep {
    foreach ( $values in @(
            @('all complete',  @('Complete','Complete'), $true,  2),
            @('all pending',   @('Pending','Pending'),   $false, 1),
            @('first pending', @('Pending','Complete'),  $false, 1),
            @('last pending',  @('Complete','Pending'),  $false, 2)
        )
    )
    {
        $testName,$results,$returnValue,$invokations = $values
        Context $testName {
            $q = [System.Collections.Queue]::new()
            $a = [System.Collections.ArrayList]::new()
            Mock Invoke-ConfigStep -Verifiable { return $q.Dequeue() }
            It 'populate the results queue' {
                foreach ( $result in $results )
                {
                    $item = New-Object psobject -Property @{
                        Progress = $result
                    }
                    $q.Enqueue( $item )
                }
            }
            It 'populate the input array' {
                foreach ( $result in $results )
                {
                    $item = [ConfigStep]::new()
                    $item.Verb = 'Test'
                    $item.Phase = 'Pretest'
                    $a.Add( $item )
                }
                foreach ( $result in $results )
                {
                    'Test','Set' |
                        % {
                            $item = [ConfigStep]::new()
                            $item.Verb = $_
                            $item.Phase = 'Configure'
                            $a.Add( $item )
                        }
                }
            }
            It "returns $returnValue" {
                $r = $a | Test-ConfigStep
                $r | Should be $returnValue
            }
            It 'correctly invokes commands' {
                Assert-MockCalled Invoke-ConfigStep $invokations -Exactly
            }
        }
    }
}
}
