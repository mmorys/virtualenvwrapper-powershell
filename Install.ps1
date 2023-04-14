#
# VirtualEnvWrapper for Power shell
#
# Installation script
#

$PowerShellProfile = $PROFILE.CurrentUserAllHosts
$PowerShellPath = Split-Path $PowerShellProfile

Import-LocalizedData -BaseDirectory .\VirtualEnvWrapper -FileName VirtualEnvWrapper.psd1 -BindingVariable Data
$ModuleVersion = $Data.ModuleVersion

$InstallationDirectory = Join-Path $PowerShellPath Modules
$InstallationPath = Join-Path $InstallationDirectory "VirtualEnvWrapper"
$InstallationPath = Join-Path $InstallationPath $ModuleVersion


function Ask-User($Message)
{
    Do
    {
        $Key = (Read-Host "$Message [Y/n]").ToLower()
    } While ($Key -ne "y" -And $Key -ne "n")

    return $Key
}

$key = Ask-User "Do you want to install VirtualEnvWrapper for PowerShell?"
if ($key -eq "n")
{
    Exit
}

if (!(Test-Path $InstallationDirectory))
{
    Write-Host "Creating directory: $InstallationDirectory"
    New-Item -ItemType Directory -Force -Path $InstallationDirectory
}

if (Test-Path $InstallationPath) {
    Write-Host "Removing previously installed version $ModuleVersion"
    Remove-Item -Recurse -Force $InstallationPath
}

Copy-Item -Recurse .\VirtualEnvWrapper $InstallationPath

if (!(Test-Path $PowerShellProfile))
{
    $key = Ask-User "The PowerShell profile is missing. Do you want to create it?"
    if ($key -eq "y")
    {
        Copy-Item Profile.ps1 $PowerShellProfile
    }
}
else
{
    $From = Get-Content -Path Profile.ps1

    if(!(Select-String -SimpleMatch "VirtualEnvWrapper" -Path $PowerShellProfile))
    {
        Add-Content -Path $PowerShellProfile -Value "`r`n"
        Add-Content -Path $PowerShellProfile -Value $From
    }
}

Write-Host "Installation complete. Please restart PowerShell to use VirtualEnvWrapper"
Write-Host