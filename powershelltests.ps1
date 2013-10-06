Set-StrictMode -Version Latest

$scriptsPath = Split-Path $MyInvocation.MyCommand.Path
$currentFolder = Get-Location

git submodule update --init --recursive

Set-Location "$currentFolder\tests"

. $scriptsPath\external\pester\bin\pester.bat

Set-Location $currentFolder