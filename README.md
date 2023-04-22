# VirtualEnvWrapper for Windows PowerShell

A Windows PowerShell clone of [virtualenvwrapper](https://github.com/python-virtualenvwrapper/virtualenvwrapper). Currently this project implements a subset of the commands provided by virtualenvwrapper for creating, deleting, and managing python virtual environments. Exact parity with the original virtualenvwrapper is a guide, but not a rule, some features may be added, not implemented, or altered.

## Installation

Clone the repository and install virtualenvwrapper with the following command:

```shell
> ./Install.ps1
```

This will install the module in the **PSModulePath** and update the current PowerShell profile.


## Commands

* `lsvirtualenv` (alias: `Invoke-ListVirtualEnv`) : List all available virtual environments.
* `mkvirtualenv` (alias: `Invoke-MakeVirtualEnv`) : Create a new virtual environment.
* `rmvirtualenv` (alias: `Invoke-RemoveVirtualEnv`) : Remove an existing virtual environment.
* `workon` (alias `Invoke-ActivateVirtualEnv`): Activate an existing virtual environment.
* `mktmpenv` (alias `Invoke-MakeTempVirtualEnv`):  Create a new temporary virtual environment.
* `virtualenvwrapper`: (alias `Invoke-VirtualEnvWrapper`) Display help and available commands.
* `deactivate`: Exit a virtual environment (only available when a virtual environment is activate).

### Development

Use the following command to temporarily install the module in the current shell:

```shell
> .\InstallDev.ps1
```
