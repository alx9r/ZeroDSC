## Using the ConfigInstructions Command

The ZeroDSC command `ConfigInstructions` is used to generate new instructions from ZeroDSC configuration documents.  Instructions can be piped directly to `Invoke-ConfigStep` to apply the configuration.  The ZeroDSC engine ensures that the `Set` and `Test` steps are invoked for the resources in the correct order and only as necessary.

### Creating an Instructions Object

An instructions object is obtained by passing a ZeroDSC configuration document to the command `ConfigInstructions`.  Consider the following configuration document which describes some registry entries in `HKEY_CURRENT_USER`:

```PowerShell
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
```

The following creates an instructions object from the configuration document:

```PowerShell
$instructions = ConfigInstructions MyConfiguration $document
```

### Exploring the Instructions Object

The instructions object emits configuration steps corresponding to each step that must be invoked to apply the configurations described in the configuration document.  ZeroDSC takes into account dependencies, progress, and whether a step was invoked or skipped to determine which step should be emitted next.  Because ZeroDSC determines which step comes next based on the results of other steps, the steps can change from one run to the next. 

To allow easy retrieval of configuration steps from instructions objects, instructions objects implement `IEnumerable`.  PowerShell streamlines interaction with `IEnumerable` objects so they can be efficiently used in `foreach()` statements and as sources in the pipeline.  `IEnumerable` also allows us to output step objects easily to the console:

    PS C:\> $instructions

      Phase Verb ResourceName      Message                        
      ----- ---- ------------      -------                        
    Pretest Test [Registry]Version Test resource [Registry]Version
    Pretest Test [Registry]Date    Test resource [Registry]Date   
    Pretest Test [Registry]MyKey   Test resource [Registry]MyKey

ZeroDSC expects each step object to be invoked before the next is emitted.  If they are not invoked, ZeroDSC marks the steps as skipped.  Since we didn't invoke any steps, ZeroDSC marked all three *Pretest* steps as skipped.  Because all the steps were skipped, ZeroDSC stopped without entering the *Configure* phase.  That is why we see only three steps.  

### Invoking Steps and Exploring Results

Each step is invoked by piping it to `Invoke-ConfigStep`.  `Invoke-ConfigStep` emits a results object for each step that was invoked.  Piping an instructions object to `Invoke-ConfigStep` invokes each step in the order determined by ZeroDSC:

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

The results of each test was output to the console.  From that output we can see that ZeroDSC started by *Pretest*ing each of the configurations.  The progress "Pending" for the first three steps indicates that the application of none of those configurations is complete yet.  ZeroDSC then enters the *Configure* phase and invokes `Set` and `Test` for `[Registry]MyKey`.  That configuration is mentioned last in our document but it is configured first because the other two configurations depend on it.  The word "Complete" in the line

     Configure Test [Registry]MyKey   Complete

marks the first configuration that ZeroDSC successfully applied.  ZeroDSC then invokes `Set` and `Test` for the remaining configurations as their dependency `[Registry]MyKey` is now complete.  We can see from the remaining output that both `[Registry]Version` and `[Registry]Date` progressed to `Complete`.

### Re-Applying the Configuration

Configurations applied using ZeroDSC are designed to be idempotent and `Set` is only invoked for a resource if it is not already completely applied.  This means that invoking the configuration steps a second time or many times is safe:

    PS C:\> $instructions | Invoke-ConfigStep
    
      Phase Verb ResourceName      Progress
      ----- ---- ------------      --------
    Pretest Test [Registry]Version Complete
    Pretest Test [Registry]Date    Complete
    Pretest Test [Registry]MyKey   Complete

The output reveals that, as expected, each of the configurations is already complete.  Running `Get-Item` confirms that the registry entries described in the configuration document were indeed created:

    PS C:\> Get-Item HKCU:\MyApplication

    Hive: HKEY_CURRENT_USER
	Name                           Property                                        
	----                           --------                                        
	MyApplication                  Version : 1.0.0                                 
    							   Date    : 11/21/2016 17:46:38                   

A change to the registry entries can be simulated by removing Date:

    PS C:\> Remove-ItemProperty HKCU:\MyApplication Date

Running the instructions again corrects that change:

    PS C:\> $instructions | Invoke-ConfigStep
    
         Phase Verb ResourceName      Progress
         ----- ---- ------------      --------
       Pretest Test [Registry]Version Complete
       Pretest Test [Registry]Date     Pending
       Pretest Test [Registry]MyKey   Complete
     Configure  Set [Registry]Date     Pending
     Configure Test [Registry]Date    Complete

On this run ZeroDSC determined during the *Pretest* phase that `[Registry]Version` and `[Registry]MyKey` were already complete.  ZeroDSC invoked `Set` only for `[Registry]Date` which is the entry we removed.
