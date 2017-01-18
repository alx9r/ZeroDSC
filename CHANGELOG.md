## 0.2.0 (2017-01-18)
 - implement Test-ConfigStep
 - improvements to class resource invoker and ConvertTo-ConfigDocument to tolerate multiple DSC resource versions

## 0.1.1 (2017-01-02)
 - improve "Installing ZeroDSC Section" in documentation
 - improve public appearance of `Import-DscResource`
 - use `InModuleScope{}` instead of `-Args ExportAll`
 - remove `ExportAll` parameter
 - explicitly import module `PSDesiredStateConfiguration`
 - various improvements to the `IEnumerator`, `[ConfigStateMachine]`, and `[ConfigStep]` to explicitly handle exceptions thrown by resources
 - consolidate the `[Event]` enum
 - implement "always and apply" for `ThrowOnSet` in the `TestStub` DSC resource
 - improve how `Get-MofResourceCommands` tests whether a module is already loaded

## 0.1.0 (2016-11-26)
 - created invokers for class- and MOF-based resources
 - interprets minimal configuration document format
 - implemented binding of configurations to resources including basic error checking
 - completed the core of an extensible multi-pass configuration algorithm
 - implemented `IEnumerable<ConfigStep>` for the instructions objects so that configuration steps can be invoked and interacted with using idiomatic PowerShell
 - published "Getting Started" documentation

This changelog is inspired by the 
[Pester](https://github.com/pester/Pester/blob/master/CHANGELOG.md) file 
(which was inspired by the
[Vagrant](https://github.com/mitchellh/vagrant/blob/master/CHANGELOG.md) 
file).
