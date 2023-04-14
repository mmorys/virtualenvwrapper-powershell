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


if (!$WORKON_HOME) {
    $WORKON_HOME = "$Env:USERPROFILE\.virtualenvs"
}


if (!(Test-Path $WORKON_HOME)) {
    mkdir $WORKON_HOME
}


# <#
# .Synopsis
#     Create a temporary environment.
# #>
# function New-TemporaryVirtualEnv() {
#     Param(
#         [Parameter(HelpMessage="Change directory into the newly created virtual environment")]
#         [alias("c")]
#         [switch]
#         $Cd = $False,

#         [Parameter(HelpMessage="Don't change directory")]
#         [alias("n")]
#         [switch]$NoCd = $false,

#         # Reimplement New-VirtualEnv parameters
#         [Parameter(HelpMessage="The requirements file")]
#         [alias("r")]
#         [string]$Requirement,

#         [Parameter(HelpMessage="The Python directory where the python.exe lives")]
#         [string]$Python,

#         [Parameter(HelpMessage="The package to install. Repeat the parameter for more than one")]
#         [alias("i")]
#         [string[]]$Packages,

#         [Parameter(HelpMessage="Associate an existing project directory to the new environment")]
#         [alias("a")]
#         [string]$Associate
#     )

#     Begin
#     {
#         if ($NoCd -eq $true) {
#             $Cd = $false;
#         }
#     }

#     Process
#     {
#         $uuid = (Invoke-Expression "python -c 'import uuid; print(str(uuid.uuid4()))'")
#         $dest_dir = "$WORKON_HOME/$uuid"

#         # Recompose command line
#         $args = ""
#         foreach($param in $PSBoundParameters.GetEnumerator())
#         {
#             $args += (" -{0} {1}" -f $param.Key,$param.Value)
#         }

#         Invoke-Expression "New-VirtualEnv $uuid $args"

#         $message = "This is a temporary environment. It will be deleted when you run 'deactivate'."
#         Write-Host $message
#         $message | Out-File -FilePath "$dest_dir/README.tmpenv"

#         # Write deactivation file. See Workon rewriting deactivate feature
#         $post_deactivate_file_content = @"
# if ((est-Path -Path `"$dest_dir/README.tmpenv`") {
#     Write-Host `"Removing temporary environment $uuid`"
#     # Change the location else MS Windows will refuse to remove the directory
#     Set-Location `"$WORKON_HOME`"
#     Remove-VirtualEnv $uuid
# }
# "@
#         $post_deactivate_file_content | Out-File -FilePath "$WORKON_HOME/$uuid/postdeactivate.ps1"

#         if ($Cd -Eq $true) {
#             Set-Location -Path "$WORKON_HOME/$uuid"
#         }
#     }
# }


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
function New-VirtualEnv() {
    Param(
        [Parameter(Mandatory=$true)][string]$EnvName,
        [Parameter()][alias("p")][string]$PythonVersion
    )

    if ($EnvName.StartsWith("-")) {
        Write-FormattedError "Virtual environments cannot start with a minus (-)"
        return
    }

    if ((Test-VirtualEnvExists $EnvName)) {
        Write-FormattedError "The virtual environment '$EnvName' already exists"
        return
    }

    Write-Host "Creating new virtual environment '$EnvName' ..." -NoNewline

    $Command = "py"
    if ($PythonVersion) {
        $Command = "$Command -$PythonVersion"
    }

    $EnvPath = Get-VirtualEnvPath $EnvName
    Invoke-Expression "$Command -m venv '$EnvPath' --prompt '$EnvName'"

    Write-Host " Done"
    Write-Host
    Write-Host "Activate the environment with the following command:"
    Write-Host "workon $EnvName"
    Write-Host
    Write-Host "Deactivate the environment with the following command:"
    Write-Host "deactivate"
    Write-Host
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
function Remove-VirtualEnv {
    Param(
        [Parameter(Mandatory=$true)][string]$EnvName
    )

    if ((Test-VirtualEnvActivate $EnvName) -eq $true) {
        Write-FormattedError "The virtual environment '$EnvName' is active. Please 'deactivate' " `
                             "before to dispose the environment before"
        return
    }

    $EnvPath = Get-VirtualEnvPath $EnvName
    if (Test-Path $EnvPath) {
        Remove-Item -Path $EnvPath -Recurse
        Write-Host "The virtual environment '$EnvName' has been removed"
    } else {
        Write-FormattedError "Can find virtual environment '$EnvName'"
    }
}


<#
.Synopsis
    List all available virtual environments.

.Description
    Displays all valid and in-valid python virtual environments in the WORKON_HOME directory.
    A python virtual environment is considered valid if it contains a python executable.
#>
function Show-VirtualEnvs {
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
    Change the working virtual environment.

.Description
    Activates the specified python virtual environment. Environment names must match
    a sub-directory in the WORKON_HOME directory and must contain a valid activation script.

 .Parameter EnvName
    Name of the virtual environment to be activated.
#>
function Start-VirtualEnv {
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
    Displays information about the virtualenvwrapper and available commands.
#>
function Show-VirtualEnvWrapper() {
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
    Write-Host "rmvirtualenv:  Remove a virtual environment."
    Write-Host "workon:        Change the working virtual environment."
    Write-Host
}


function Get-VirtualEnvPath($Path) {
    # Helper function: Get the absolute path for the environment
    return Join-Path $WORKON_HOME $Path
}


function Test-VirtualEnvActivate($EnvName) {
    # Helper Function: Tests if a virtual environment is active.
    return $Env:VIRTUAL_ENV -eq $EnvName
}


function Test-VirtualEnvExists($EnvName) {
    # Helper Function: Tests if a python virtual environment exists.
    $directory = Get-ChildItem $WORKON_HOME -Filter $EnvName -Directory
    return $null -ne $directory
}


function Write-FormattedError($message) {
    # Helper Function: Display a formatted error message
    Write-Host $message -ForegroundColor Red
}


# Powershell aliases to match original virtualenvwrapper API (must be before Export-ModuleMember)
New-Alias -Name lsvirtualenv -Value Show-VirtualEnvs
New-Alias -Name mkvirtualenv -Value New-VirtualEnv
New-Alias -Name mktmpenv -Value New-TemporaryVirtualEnv
New-Alias -Name rmvirtualenv -Value Remove-VirtualEnv
New-Alias -Name workon -Value Start-VirtualEnv
New-Alias -Name virtualenvwrapper -Value Show-VirtualEnvWrapper


Export-ModuleMember -Function Show-VirtualEnvs -Alias lsvirtualenv
Export-ModuleMember -Function New-VirtualEnv -Alias mkvirtualenv
Export-ModuleMember -Function Remove-VirtualEnv -Alias rmvirtualenv
Export-ModuleMember -Function Start-VirtualEnv -Alias workon
Export-ModuleMember -Function Show-VirtualEnvWrapper -Alias virtualenvwrapper


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
Register-ArgumentCompleter -CommandName Start-VirtualEnv -ParameterName EnvName -ScriptBlock $ScriptBlock
Register-ArgumentCompleter -CommandName Remove-VirtualEnv -ParameterName EnvName -ScriptBlock $ScriptBlock