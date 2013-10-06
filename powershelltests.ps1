Set-StrictMode -Version Latest

$scriptPath = Split-Path $MyInvocation.MyCommand.Path
$currentFolder = Get-Location

Set-Location "$currentFolder\tests"

. $rootDirectory\external\pester\bin\pester.bat

Set-Location $currentFolder