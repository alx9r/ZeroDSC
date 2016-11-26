# Getting Started with ZeroDSC

## New to PowerShell or DSC?
All of the ZeroDSC documentation assumes that you have a working familiarity with both PowerShell and PowerShell DSC.  If you are new to PowerShell or DSC I recommend reviewing the getting started documentation at the [PowerShell Project](https://github.com/PowerShell/PowerShell).

## Installing ZeroDSC

ZeroDSC is a PowerShell module.  To install simply put the root folder (the one named "ZeroDSC") in one of the `$PSModulePath` folders on your system.  For testing and development I recommend installing ZeroDSC to the user modules folder (usually `$Env:UserProfile\Documents\WindowsPowerShell\Modules`). 

### Prerequisites

ZeroDSC requires WMF 5.0.

### Obtaining ZeroDSC

To obtain ZeroDSC I recommend cloning [the repository](https://github.com/alx9r/ZeroDSC.git) to your computer and checking out the [latest release](https://github.com/alx9r/ZeroDSC/releases/latest) using `git clone` and `git checkout`.  Remember, ZeroDSC is still in experimental stages, so expect to pull changes to fix issues.

Alternatively you can download then extract an archive of the module from [this page](https://github.com/alx9r/ZeroDSC/releases/latest).

### Confirming Installation

To confirm that ZeroDSC is installed on your computer, invoke the following commands:

```
C:\> Import-Module ZeroDSC
C:\> Get-Module ZeroDSC

ModuleType Version    Name             ExportedCommands
---------- -------    ----             ----------------
Script     0.1.0      ZeroDSC          {ConfigInstruction...
```

You should see some details about the ZeroDSC module output by the `Get-Module` command as shown above.

## Introductory Topics

For an introduction to ZeroDSC, I recommend reading the following topics.  They are probably best read in the order listed here:

 * [Using the ConfigInstructions Command][]
 * [ZeroDSC Idioms][]
 * [Pester Integration][]
 * [Resource Invokers][]

[Using the ConfigInstructions Command]: configInstructions.md
[ZeroDSC Idioms]: idioms.md
[Pester Integration]: pesterIntegration.md
[Resource Invokers]: resourceInvoker.md

## Feedback

If you have feedback, encounter problems, or have a contribution please open an issue or pull request in [the ZeroDSC Github repository](https://github.com/alx9r/ZeroDSC).
