## THIS FILE IS USING TO BUILD A CI PACKAGE OF THIS REPOSITORY
## Think of it as a poor man's pester test

param(
    [string]$packageVersion = $null
)

# Initialization
$rootFolder = Split-Path -parent $script:MyInvocation.MyCommand.Definition
. $rootFolder\myget.include.ps1

if(MyGet-BuildRunner -eq "myget") {
    MyGet-Die "Try running .\build.all.samples.ps1 DUDE!"
}

# x86/x64
. $rootFolder\build.sample.x86.x64-BUILD-SOLUTION.ps1 -packageVersion $packageVersion