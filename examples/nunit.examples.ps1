param(
    [string]$packageVersion = "1.0.0",
    [string]$config = "Release"
)

$rootFolder = Split-Path -parent $script:MyInvocation.MyCommand.Path
$rootFolder = Join-Path $rootFolder ..

$buildOutputFolder = Join-Path $rootFolder "bin"
$anyCpuOutputDirectory = Join-Path $rootFolder "bin\sample.solution.anycpu"
$mixedPlatformsOutputDirectory = Join-Path $rootFolder "bin\sample.solution.mixedplatforms"

. $rootFolder\myget.include.ps1

$packageVersion = MyGet-Package-Version $packageVersion

if(-not (Test-Path $buildOutputFolder)) {
    MyGet-Die "Please run .\examples\build.all.samples.ps1 and try again!"
}

MyGet-Write-Diagnostic "Run all tests"

MyGet-TestRunner-Nunit -rootFolder $rootFolder `
        -buildFolder $buildOutputFolder

MyGet-Write-Diagnostic "Run all anycpu tests"

MyGet-TestRunner-Nunit -rootFolder $rootFolder `
        -buildFolder $anyCpuOutputDirectory

MyGet-Write-Diagnostic "Run all mixed platform tests"

MyGet-TestRunner-Nunit -rootFolder $rootFolder `
        -buildFolder $mixedPlatformsOutputDirectory

MyGet-Write-Diagnostic "Run all mixed tests with minimum framework of v4.0"

MyGet-TestRunner-Nunit -rootFolder $rootFolder `
        -buildFolder $mixedPlatformsOutputDirectory\$packageVersion\x64 `
        -minTargetFramework v4.0

MyGet-Write-Diagnostic "Run all mixed tests with minimum framework of v4.5.1"

MyGet-TestRunner-Nunit -rootFolder $rootFolder `
        -buildFolder $mixedPlatformsOutputDirectory\$packageVersion\x64\Release\v4.5.1
