#
# Python virtual env manager inspired by VirtualEnvWrapper
#
# Copyright (c) 2017 Regis FLORET, Charles W. Swartz VI
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

$WORKON_HOME=$Env:WORKON_HOME
$Version = "0.1"
Import-LocalizedData -FileName VirtualEnvWrapper.psd1 -BindingVariable Data
$Version = $Data.ModuleVersion


if (!$WORKON_HOME) {
    $WORKON_HOME = "$Env:USERPROFILE\.virtualenvs"
}


if (!(Test-Path $WORKON_HOME)) {
    mkdir $WORKON_HOME
}


<#
.Synopsis
    Change the working virtual environment.

.Description
    Activates the specified python virtual environment. Environment names must match
    a sub-directory in the WORKON_HOME directory and must contain a valid activation script.

 .Parameter EnvName
    Name of the virtual environment to be activated.
#>
function Invoke-ActivateVirtualEnv {
    Param(
        [Parameter(Mandatory=$true)][string]$EnvName
    )

    $EnvPath = Get-VirtualEnvPath $EnvName
    if ((Test-Path $EnvPath) -eq $false) {
        Write-FormattedError "The virtual environment '$EnvName' does not exist"
        return
    }

    if (Test-VirtualEnvActivate $EnvName) {
        Invoke-Expression "deactivate"
    }

    $ActivateScript = "$EnvPath\Scripts\Activate.ps1"
    if ((Test-path $ActivateScript) -eq $false) {
        Write-FormattedError "Unable to find the activation script in '$EnvName'"
        return
    }

    Import-Module $ActivateScript -Force
}


<#
.Synopsis
    List all available virtual environments.

.Description
    Displays all valid and in-valid python virtual environments in the WORKON_HOME directory.
    A python virtual environment is considered valid if it contains a python executable.
#>
function Invoke-ListVirtualEnv {
    $children = Get-ChildItem $WORKON_HOME
    Write-Host "`nWORKON_HOME = $WORKON_HOME`n"
    Write-host ("{0,-35}{1,-10}" -f "Python Virtual Environment", "Version")
    Write-host ("{0,-35}{1,-10}" -f "--------------------------", "-------")

    $failed = New-Object Collections.Generic.List[Int]
    if ($children.Length) {
        foreach ($child in $children) {
            try {
                $Command = ("$WORKON_HOME\{0}\Scripts\Python.exe --version 2>&1" -f $child.Name)
                $PythonVersion = (((Invoke-Expression $Command) -replace "`r|`n", "") -Split " ")[1]
                Write-host ("{0,-35}{1,-10}" -f $child.Name, $PythonVersion)
            } catch {
                $failed += $child.Name
            }
        }
    } else {
        Write-Host "No Python Environment Found"
    }

    if ($failed.Length -gt 0) {
        Write-Host
        Write-Host "Unknown Directories"
        Write-Host "-------------------"
        foreach ($item in $failed) {
            Write-Host "$item"
        }
    }

    Write-Host
}


<#
.Synopsis
    Create a virtual environment.

.Description
    Creates a new python virtual environment in the WORKON_HOME directory.

.Parameter EnvName
    Name of the virtual environment to be created (required).

.Parameter PythonVersion
    Python version used in the virtual environment
#>
function Invoke-MakeVirtualEnv() {
    Param(
        [Parameter(Mandatory=$true)][string]$EnvName,
        [Parameter()][alias("p")][string]$PythonVersion,
        [Parameter()][alias("r")][string]$Requirements,
        [Parameter()][alias("i")][string[]]$Package
    )

    Write-Host "Creating new virtual environment '$EnvName'"

    if (!(New-VirtualEnv $EnvName $PythonVersion)) {
        return
    }

    Invoke-ActivateVirtualEnv $EnvName

    Update-VirtualEnv $Requirements $Package
}


# <#
# .Synopsis
#     Create a temporary virtual environment.
# #>
function Invoke-MakeTempVirtualEnv() {

    Param(
        [Parameter()][alias("p")][string]$PythonVersion,
        [Parameter()][alias("r")][string]$Requirements,
        [Parameter()][alias("i")][string[]]$Package
    )

    $EnvName = "tmp-" + (GetNextID)

    Write-Host "Creating temporary virtual environment '$EnvName'"
    If (!(New-VirtualEnv $EnvName $PythonVersion)) {
        return
    }

    Invoke-ActivateVirtualEnv $EnvName

    Update-VirtualEnv $Requirements $Package

    # We need to wrap the `deactivate` command defined in the venv Activate
    # script so that virtual environments are removed when deactivated.
    $ENV:_DEACTIVATE_SCRIPT_BLOCK = (Get-Command "deactivate").ScriptBlock

    function global:deactivate {
        $EnvName = (Get-Item -Path $ENV:VIRTUAL_ENV).Name
        Invoke-Expression $ENV:_DEACTIVATE_SCRIPT_BLOCK
        Write-Host "Removing temporary virtual environment $EnvName"
        $null = Remove-VirtualEnv $EnvName
        Remove-Item ENV:\_DEACTIVATE_SCRIPT_BLOCK
    }
}


<#
.Synopsis
    Remove a virtual environment.

.Description
    Removes the specified python virtual environment from the WORKON_HOME directory. Note that a
    virtual environment must be deactivated before it can be removed.

 .Parameter EnvName
    Name of the virtual environment to be removed (required).
#>
function Invoke-RemoveVirtualEnv {
    Param(
        [Parameter(Mandatory=$true)][string]$EnvName
    )

    if (Remove-VirtualEnv($EnvName)) {
        Write-Host "The virtual environment '$EnvName' has been removed"
    }
}


<#
.Synopsis
    Displays information about the virtualenvwrapper and available commands.
#>
function Invoke-VirtualEnvWrapper() {
    Write-Host
    Write-Host "VirtualEnvWrapper for PowerShell."
    Write-Host
    Write-Host "Version $Version"
    Write-Host
    Write-Host "WORKON_HOME = $WORKON_HOME"
    Write-Host
    Write-Host "Commands"
    Write-Host "lsvirtualenv:  List all available virtual environments."
    Write-Host "mkvirtualenv:  Create a new virtual environment."
    Write-Host "mktmpenv:      Create a temporary virtual environment."
    Write-Host "rmvirtualenv:  Remove a virtual environment."
    Write-Host "workon:        Change the working virtual environment."
    Write-Host
}


function Get-VirtualEnvPath($Path) {
    # Helper function: Get the absolute path for the environment
    return Join-Path $WORKON_HOME $Path
}


function New-VirtualEnv($EnvName, $PythonVersion) {
    # Helper function: Create the specified virtual environment in WORKON_HOME.
    if ($EnvName.StartsWith("-")) {
        Write-FormattedError "Virtual environments cannot start with a minus (-)"
        return $false
    }

    if ((Test-VirtualEnvExists $EnvName)) {
        Write-FormattedError "The virtual environment '$EnvName' already exists"
        return $false
    }

    $Command = "py"
    if ($PythonVersion) {
        $Command = "$Command -$PythonVersion"
    }

    $EnvPath = Get-VirtualEnvPath $EnvName
    Invoke-Expression "$Command -m venv '$EnvPath' --prompt '$EnvName'"

    return $true
}


function GetNextID($MaxSize = 10) {
    # Helper function: Create a random identifier string.
    $Guid = [guid]::NewGuid()
    $Id = [string]$Guid
    $Id = $Id.Replace("-", "")
    return $Id.substring(0, $MaxSize)
}


function Remove-VirtualEnv($EnvName) {
    # Helper function: Remove the specified virtual environment from WORKON_HOME.
    if ((Test-VirtualEnvActivate $EnvName)) {
        Write-FormattedError "The virtual environment '$EnvName' is active. Please 'deactivate' " `
                             "before to dispose the environment before"
        return $false
    }

    $EnvPath = Get-VirtualEnvPath $EnvName
    if (Test-Path $EnvPath) {
        Remove-Item -Path $EnvPath -Recurse
        return $true
    } else {
        Write-FormattedError "Can find virtual environment '$EnvName'"
    }

    return $false
}


function Test-VirtualEnvActivate($EnvName) {
    # Helper Function: Tests if a virtual environment is active.
    if (!$ENV:VIRTUAL_ENV) {
        return $false
    }
    $ActivateEnvName = Split-Path $ENV:VIRTUAL_ENV -Leaf
    return $ActivateEnvName -eq $EnvName
}


function Test-VirtualEnvExists($EnvName) {
    # Helper Function: Tests if a python virtual environment exists.
    $directory = Get-ChildItem $WORKON_HOME -Filter $EnvName -Directory
    return $null -ne $directory
}


function Update-VirtualEnv($Requirements, $Packages) {
    # Helper Function: Install packages into a virtual environment.
    if ($Requirements) {

        if (!(Test-Path $Requirements)) {
            Write-FormattedError "Specified requirements files does not exist"
        }
        Invoke-Expression "python -m pip install -r $Requirements"
    }

    foreach ($Package in $Packages) {
        Invoke-Expression "python -m pip install $Package"
    }
}


function Write-FormattedError($message) {
    # Helper Function: Display a formatted error message
    Write-Host $message -ForegroundColor Red
}


# Powershell aliases to match original virtualenvwrapper API (must be before Export-ModuleMember)
New-Alias -Name lsvirtualenv -Value Invoke-ListVirtualEnv
New-Alias -Name mkvirtualenv -Value Invoke-MakeVirtualEnv
New-Alias -Name mktmpenv -Value Invoke-MakeTempVirtualEnv
New-Alias -Name rmvirtualenv -Value Invoke-RemoveVirtualEnv
New-Alias -Name workon -Value Invoke-ActivateVirtualEnv
New-Alias -Name virtualenvwrapper -Value Invoke-VirtualEnvWrapper


Export-ModuleMember -Function Invoke-ListVirtualEnv -Alias lsvirtualenv
Export-ModuleMember -Function Invoke-MakeVirtualEnv -Alias mkvirtualenv
Export-ModuleMember -Function Invoke-RemoveVirtualEnv -Alias rmvirtualenv
Export-ModuleMember -Function Invoke-MakeTempVirtualEnv -Alias mktmpenv
Export-ModuleMember -Function Invoke-ActivateVirtualEnv -Alias workon
Export-ModuleMember -Function Invoke-VirtualEnvWrapper -Alias virtualenvwrapper


# The following script block will perform auto-completion of virtual environment names
$ScriptBlock = {
    # Parameters passed into the script block by the Register-ArgumentCompleter command
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    # The list of values that the typed text is compared to
    $Values = Get-ChildItem $WORKON_HOME

    # Determines if what has been typed matches the value from the list
    foreach ($Value in $Values) {
        if ($Value.Name -like "$wordToComplete*") {
            $Value.Name
        }
    }
}


# Assign autocomplete to functions (must be last)
Register-ArgumentCompleter -CommandName Invoke-ActivateVirtualEnv -ParameterName EnvName -ScriptBlock $ScriptBlock
Register-ArgumentCompleter -CommandName Invoke-RemoveVirtualEnv -ParameterName EnvName -ScriptBlock $ScriptBlock