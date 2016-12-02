## Resource Invokers

ZeroDSC implements `[ResourceInvoker]` objects that can be used to easily invoke DSC resources that are available using the `Get-DscResource` command.

### Getting an Invoker for a Resource

An invoker object is obtained by piping a `[DscResourceInfo]` object to `New-ResourceInvoker`.  `[DscResourceInfo]` is the type emitted by the built-in command `Get-DscResource`.  The following creates a resource invoker object for the built-in *Registry* resource.

    PS C:\> $invoker = Get-DscResource Registry | New-ResourceInvoker

### Exploring the Invoker Object

The invoker object exposes a few properties

    PS C:\> $invoker
    Name     ModuleName                  Version Properties                            
    ----     ----------                  ------- ----------                            
    Registry PSDesiredStateConfiguration 1.1     {Key, ValueName, DependsOn, Ensure...}    

and has an `.Invoke()` method with parameters `Mode` and `Params`

    PS C:\> $invoker | Get-Member
    TypeName: MofResourceInvoker
    Name        MemberType     Definition                                                     
    ----        ----------     ----------                                                     
    ...
    Invoke      Method         System.Object Invoke(string Mode, hashtable Params)            
    ...

where `Mode` can be `Test`,`Set`, or `Get` and `Params` contains the configuration parameters to pass to the `*-TargetResource` functions or methods of the resource.

### Example Invocation

Using `$invoker` from above, we will create a registry key at `HKEY_CURRENT_USER:\ZeroDSC`.  Using the [reference for the *Registry* resource](https://msdn.microsoft.com/en-us/powershell/dsc/registryresource) we can build a hashtable that contains the parameters to create the registry key:

    $params = @{
        Key = 'HKEY_CURRENT_USER\ZeroDSC'
        ValueName = [string]::Empty
        Ensure = 'Present'
    }

Invoking `Test` for the resource reveals whether that key exists.

    PS C:\> $invoker.Invoke('Test',$params)
    False

A result of false indicates that the key is not present.  That is confirmed when we run `Get-Item`.

    PS C:\> Get-Item 'HKCU:\ZeroDSC'
    Get-Item : Cannot find path 'HKCU:\ZeroDSC' because it does not exist.

Invoking `Set` for the resource should create the key.

    PS C:\> $invoker.Invoke('Set',$params)
    
Now invoking `Test` again should return true

    PS C:\> $invoker.Invoke('Test',$params)
    True

and running `Get-Item` again confirms that the key now exists.

    PS C:\> Get-Item 'HKCU:\ZeroDSC' | fl *
    
    Property      : {}
    PSPath        : Microsoft.PowerShell.Core\Registry::HKEY_CURRENT_USER\ZeroDSC
    PSParentPath  : Microsoft.PowerShell.Core\Registry::HKEY_CURRENT_USER
    PSChildName   : ZeroDSC
    ...
    
To clean up we can remove the key by changing `Ensure` to `Absent` and invoking `Set` again:

    PS C:\> $params.Ensure = 'Absent'
    PS C:\> $invoker.Invoke('Set',$params)
    PS C:\> $invoker.Invoke('Test',$params)
    True
    PS C:\> Get-Item 'HKCU:\ZeroDSC'
    Get-Item : Cannot find path 'HKCU:\ZeroDSC' because it does not exist.
