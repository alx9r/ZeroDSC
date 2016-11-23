## Pester Integration

ZeroDSC is designed to integrate with the [Pester testing framework](https://github.com/pester/Pester).  Pester can iterate through the steps emitted by the instructions objects.  Invoking each step produces a results object whose values Pester can test.  The invocation of each step corresponds to a Pester test.  Pester produces well-formatted output for each test that is suitable for test-oriented development and use by continuous integration systems.

### Creating Instructions

Exceptions can occur when ZeroDSC processes a configuration document.  Invoking `ConfigDocument` inside a Pester `It{}` block ensures that such an exception is surfaced:

    Describe 'ConfigInstructions exception' {
        It 'get instructions' {
            ConfigInstructions Name {
                Get-DscResource TestStub ZeroDSC | Import-DscResource
                TestStub Name { Mode = 'normal' }
            }
        }
    } 

Running that test outputs

    Describing ConfigInstructions exception
     [-] get instructions 293ms
       PSInvalidCastException: Cannot convert the " Mode = 'normal' " value of type "System.Management.Automation.ScriptBlock" to type "System.Collections.Hashtable".
       ArgumentTransformationMetadataException: Cannot convert the " Mode = 'normal' " value of type "System.Management.Automation.ScriptBlock" to type "System.Collections.Hashtable".
       ParameterBindingArgumentTransformationException: Cannot process argument transformation on parameter 'Params'. Cannot convert the " Mode = 'normal' " value of type "System.Management.Automation.ScriptBlock" to type "System.Collections.Hashtable".
       at <ScriptBlock>, C:\temp\configInstructionsException.ps1: line 5
       ...
    

and some more details that I have not shown here.  Looking at the output we immediately see that the error occurred during the "get instructions" test.  We can see that a `PSInvalidCastException` occurred on line 5.  Line 5 reads

     TestStub Name { Mode = 'normal' }

and by careful inspection we can see that the `@` was forgotten when passing the parameters hashtable so PowerShell interpreted it as a scriptblock.

To demonstrate successful output, here is a corrected test:

    $document = {
        Get-DscResource TestStub ZeroDSC | Import-DscResource
        TestStub Name @{ Mode = 'normal' }
    }

    Describe 'ConfigInstructions exception' {
        $h = @{}
        It 'get instructions' {
            $h.Instructions = ConfigInstructions Name $document
        }
    }

Running this test outputs

	Describing ConfigInstructions exception
 	[+] get instructions 519ms

and we have successfully created our instructions and are ready to build on that test in the examples below.

### Iterating Through Steps

Each configuration step can be converted into Pester output by iterating through the instructions with a `foreach()` loop.  Here is the same test we have been working with, with another configuration added to the document, and iterating over the steps:

    $document = {
        Get-DscResource TestStub ZeroDSC | Import-DscResource
        TestStub a @{ Mode = 'normal' }
        TestStub b @{ Mode = 'normal' }
    }

    Describe 'Config Step Iteration' {
        $h = @{}
        It 'get instructions' {
            $h.Instructions = ConfigInstructions Name $document
        }
        foreach ( $step in $h.Instructions )
        {
            It $step.Message {}
        }
    }

Running that test outputs the following:

	Describing Config Step Iteration
 	 [+] get instructions 296ms
 	 [?] Pretest: Test resource [TestStub]a 52ms
	 [?] Pretest: Test resource [TestStub]b 14ms

The `[?]` is Pester's way of indicating that the test is pending.  That is because we aren't actually doing anything inside the `It{}` block yet.

### Invoking the Steps and Testing the Results

Now that we have an `It{}` block for each step, each step can be invoked and the result tested:

    $document = {
        Get-DscResource TestStub ZeroDSC | Import-DscResource
        TestStub a @{ Mode = 'normal' }
        TestStub b @{ Mode = 'normal' }
    }

    Describe 'Config Step Invocation and Result Testing' {
        $h = @{}
        It 'get instructions' {
            $h.Instructions = ConfigInstructions Name $document
        }
        foreach ( $step in $h.Instructions )
        {
            It $step.Message {
                $result = $step | Invoke-ConfigStep
                $result.Progress | Should not be 'Failed'
            }
        }
    }

Running this the first time outputs the following:

	Describing Config Step Invocation and Result Testing
 	 [+] get instructions 9.3s
     [+] Pretest: Test resource [TestStub]a 1.11s
     [+] Pretest: Test resource [TestStub]b 101ms
     [+] Configure: Set resource [TestStub]a 132ms
     [+] Configure: Test resource [TestStub]a 88ms
     [+] Configure: Set resource [TestStub]b 143ms
     [+] Configure: Test resource [TestStub]b 208ms

Because each step is invoked, ZeroDSC proceeds to the *Configure* phase after the *Pretest*s are invoked.  That is why there are six steps where there were only two before.  Running the test again yields the following:

    Describing Config Step Invocation and Result Testing
     [+] get instructions 342ms
     [+] Pretest: Test resource [TestStub]a 81ms
     [+] Pretest: Test resource [TestStub]b 24ms

We are back to two steps again because configuration `[TestStub]a` and `[TestStub]b` have already been applied.

If we change the document so that `Test`ing our resources always returns false

    $document = {
        Get-DscResource TestStub ZeroDSC | Import-DscResource
        TestStub a @{ Mode = 'incorrigible' }
        TestStub b @{ Mode = 'incorrigible' }
    }

and run the test again

    Describing Config Step Result Failed
     [+] get instructions 324ms
     [+] Pretest: Test resource [TestStub]a 74ms
     [+] Pretest: Test resource [TestStub]b 25ms
     [+] Configure: Set resource [TestStub]a 43ms
     [-] Configure: Test resource [TestStub]a 39ms
       Expected: value was {Failed}, but should not have been the same
       16:                 $result.Progress | Should not be 'Failed'
       at <ScriptBlock>, C:\temp\configInstructionsResultFailed.ps1: line 16
     [+] Configure: Set resource [TestStub]b 48ms
     [-] Configure: Test resource [TestStub]b 38ms
       Expected: value was {Failed}, but should not have been the same
       16:                 $result.Progress | Should not be 'Failed'
       at <ScriptBlock>, C:\temp\configInstructionsResultFailed.ps1: line 16

we see that `[TestStub]a` and `[TestStub]b`'s progress is failed when it should not have been.  This fine-grained testing and precise reporting speeds finding the root cause of failures.