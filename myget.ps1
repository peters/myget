## Attempt to build a .nupkg for one of the sample projects using MyGet.org

param(
    [string] $packageVersion = "",
    [bool] $fakeBuildRunner = $false
)

# Initialization
$rootFolder = Split-Path -parent $script:MyInvocation.MyCommand.Path
. $rootFolder\myget.include.ps1

# Fake build runner so that we can test that this script works.
if($fakeBuildRunner) {
    MyGet-Set-EnvironmentVariable "BuildRunner" "myget"
    MyGet-Set-EnvironmentVariable "PackageVersion" "1.0.0"
} else {
    MyGet-Set-EnvironmentVariable "BuildRunner" ""
    MyGet-Set-EnvironmentVariable "PackageVersion" ""
}

if(-not (MyGet-BuildRunner "myget")) {
    MyGet-Die "Try running .\examples\build.all.samples.ps1 DUDE!"
}

# Get package version
$packageVersion = MyGet-Package-Version $packageVersion

# Run powershell unit tests for myget.include.ps1
git submodule update --init --recursive
. $rootFolder\powershelltests.ps1

# x86/x64
. $rootFolder\examples\build.sample.mixedplatforms-BUILD-SOLUTION.ps1 -packageVersion $packageVersion