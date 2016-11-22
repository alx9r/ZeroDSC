## ConfigInstructions

The ZeroDSC command `ConfigInstructions` is used to generate new instructions from ZeroDSC configuration documents.  Instructions can be piped directly to `Invoke-ConfigStep` to apply the configuration.  The ZeroDSC engine ensures that the invocation order of the `Set` and `Test` steps for the resources being configured is correct.

### Example Usage

As an example, we will use ZeroDSC to create some registry entries in `HKEY_CURRENT_USER`.

First we will obtain a [ConfigInstructions] object use `ConfigInstructions`.  `ConfigInstructions` has two parameters: `Name` and `Scriptblock`.  ZeroDSC configuration documents are just scriptblocks that emit particular kinds of objects when invoked.

Using the [reference for the *Registry* resource](https://msdn.microsoft.com/en-us/powershell/dsc/registryresource) we can come up with the following configuration document for our registry entries:

    $document = {
        Get-DscResource Registry | Import-DscResource
    
        Registry Version @{
            Key = 'HKEY_CURRENT_USER\MyApplication'
            ValueName = 'Version'
            ValueType = 'String'
            ValueData = '1.0.0'
            Ensure = 'Present'
            DependsOn = '[Registry]MyKey'
        }
    
        Registry Date @{
            Key = 'HKEY_CURRENT_USER\MyApplication'
            ValueName = 'Date'
            ValueType = 'String'
            ValueData = [string](Get-Date)
            Ensure = 'Present'
            DependsOn = '[Registry]MyKey'    
        }
    
        Registry MyKey @{
            Key = 'HKEY_CURRENT_USER\MyApplication'
            ValueName = [string]::Empty
            Ensure = 'Present'
        }
    }

To obtain our instructions object, we use `ConfigInstructions`:

    $instructions = ConfigInstructions MyConfiguration $document

The instructions object implements `IEnumerable` so we can output steps ZeroDSC is expecting to perform to the console:

    PS C:\> $instructions
      Phase Verb ResourceName      Message                        
      ----- ---- ------------      -------                        
    Pretest Test [Registry]Version Test resource [Registry]Version
    Pretest Test [Registry]Date    Test resource [Registry]Date   
    Pretest Test [Registry]MyKey   Test resource [Registry]MyKey

Each of the objects that were emitted above is a step object.  ZeroDSC expects each step object to be invoked before the next is emitted.  If they are not invoked, ZeroDSC marks the steps as skipped.  Since we didn't invoke any steps, ZeroDSC marked all three Pretest steps as skipped and stopped.  That is why we see only three steps.  Let's see what happens when we invoke the steps:

    PS C:\> $instructions | Invoke-ConfigStep
         Phase Verb ResourceName      Progress
         ----- ---- ------------      --------
       Pretest Test [Registry]Version  Pending
       Pretest Test [Registry]Date     Pending
       Pretest Test [Registry]MyKey    Pending
     Configure  Set [Registry]MyKey    Pending
     Configure Test [Registry]MyKey   Complete
     Configure  Set [Registry]Version  Pending
     Configure Test [Registry]Version Complete
     Configure  Set [Registry]Date     Pending
     Configure Test [Registry]Date    Complete

`Invoke-ConfigStep` outputs results objects that include information about each step that was invoked.  From that output we can see that ZeroDSC started by *Pretest*ing each of the configurations.  The progress "Pending" for the first three steps indicates that none of those configurations is complete yet.  ZeroDSC then enters the *Configure* phase and invokes `Set` and `Test` for `[Registry]MyKey`.  That configuration is mentioned last in our document but it is configured first because the other two configurations depend on it.  The word "Complete" in the line

     Configure Test [Registry]MyKey   Complete

marks the first configuration that ZeroDSC successfully completed.  ZeroDSC then invokes `Set` and `Test` for the remaining configurations as their dependency `[Registry]MyKey` is now complete.  We can see from the remaining output that both `[Registry]Version` and `[Registry]Date` have progressed to `Complete`.

Running `Get-Item` confirms that the entries were created:

    PS C:\> Get-Item HKCU:\MyApplication

    Hive: HKEY_CURRENT_USER
	Name                           Property                                        
	----                           --------                                        
	MyApplication                  Version : 1.0.0                                 
    							   Date    : 11/21/2016 17:46:38                   

Let's simulate a change to the entries by removing Date:

    PS C:\> Remove-ItemProperty HKCU:\MyApplication Date

Running the instructions again corrects that change:

    PS C:\> instructions | Invoke-ConfigStep
         Phase Verb ResourceName      Progress
         ----- ---- ------------      --------
       Pretest Test [Registry]Version Complete
       Pretest Test [Registry]Date     Pending
       Pretest Test [Registry]MyKey   Complete
     Configure  Set [Registry]Date     Pending
     Configure Test [Registry]Date    Complete

Note that this time ZeroDSC determined during the *Pretest* phase that `[Registry]Version` and `[Registry]MyKey` were already complete.  ZeroDSC only invoked `Set` and `Test` for `[Registry]Date` which is the entry we removed.