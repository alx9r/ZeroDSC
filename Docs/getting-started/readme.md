# Getting Started with ZeroDSC

## New to PowerShell or DSC?
All of the ZeroDSC documentation assumes that you have a working familiarity with both PowerShell and PowerShell DSC.  If you are new to PowerShell or DSC I recommend reviewing the getting started documentation at the [PowerShell Project](https://github.com/PowerShell/PowerShell).

## Installing ZeroDSC

ZeroDSC is a PowerShell module.  To install it you simply need to put the root folder (named "ZeroDSC") in one of the `$PSModulePath` folders on your system.  Until I adopt a release process, I recommend cloning the repository to your user modules folder (usually `$Env:UserProfile\Documents\WindowsPowerShell\Modules`) using `git` and switching to the `master` branch.  Remember, ZeroDSC is still in experimental stages, so expect to pull changes to fix issues.

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

If you have feedback or encounter problems, please open an issue in [the ZeroDSC Github repository](https://github.com/alx9r/ZeroDSC).
