# Changelog for VirtualEnvWrapper Powershell

## 2023-04-23 (v.0.4.0)
    * When creating a virtual environment it is now possible to upgrade core python dependencies (pip adn setuptools) wiht `-Upgrade` flag

## 2023-04-23 (v.0.3.0)
    * Added Requirements and Package parameters to mkvirtualenv and mktmpenv

## 2023-04-21 (v.0.2.0)
    * Added python version parameter to mktmpenv
	* Removed interactivity of install script

## 2023-04-11 (v.0.1.6)
    * Forked version; major rewrite (@cswartzvi)

## 2021-05-07 (v.0.1.4)
    * Fix various compatibility issues with PowerShell 7 (thanks to @mmorys and @dbellandi)

## 2020-11-26 (v0.1.3)
	* Fix issue #21 due to working branch accidentaly merged on master

## 2020-11-17 (v0.1.2)
	* Fix bug on Get-VirtualEnvs for user with space in name
	* Fix uncomplete environment

## 2019-11-10 (v0.1.1)
	* Partially merge Swiffer PR
	* Start tagging

## 2015-05-13
	* Fix bug #1 (thanks to franciscosucre)
	* Add installation script
	* Improve ReadMe
	* Add changelog file
	* Fix Workon bug which deactivate a python env even if the new one didn't exists
	* Change Python virtual environment path with system variable
	* Add version asking
	* Avoid virtual envs that begins with '-'
