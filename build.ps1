## THIS FILE IS USING TO BUILD A MYGET CI PACKAGE OF THIS REPOSITORY

# Initialization
$rootFolder = Split-Path -parent $script:MyInvocation.MyCommand.Path
. $rootFolder\myget.include.ps1

if(-not (MyGet-BuildRunner "myget")) {
    MyGet-Die "Try running .\examples\build.all.samples.ps1 DUDE!"
}

# Get package version
$packageVersion = MyGet-Package-Version $packageVersion

# Run powershell unit tests for myget.include.ps1
git submodule update --init --recursive
. $rootFolder\powershelltests.ps1

# x86/x64
. $rootFolder\build.sample.mixedplatforms-BUILD-SOLUTION.ps1 -packageVersion $packageVersion