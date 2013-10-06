param(
    [string[]]$platforms = @(
        "x86",
        "x64"
    ),
    [string[]]$targetFrameworks = @(
        "v2.0", 
        "v3.5", 
        "v4.0",
        "v4.5", 
        "v4.5.1"
    ),
    [string]$packageVersion = $null,
    [string]$config = "Release",
    [string]$target = "Rebuild",
    [string]$verbosity = "Minimal",

    [bool]$clean = $true
)

# Initialization
$rootFolder = Split-Path -parent $script:MyInvocation.MyCommand.Path
$rootFolder = Join-Path $rootFolder ..

. $rootFolder\myget.include.ps1

# Myget
$packageVersion = MyGet-Package-Version $packageVersion

# Clean
if($clean) { MyGet-Build-Clean $rootFolder }

# Solution
$solutionName = "sample.solution.x86.x64"
$solutionFolder = "$rootFolder\src\$solutionName"
$outputFolder = Join-Path $rootFolder "bin\$solutionName"
$nuspec = Join-Path $solutionFolder "$solutionName\$solutionName.nuspec"

# Platforms to build for
$platforms | ForEach-Object {
    $platform = $_

    # Build solution for current platform
    MyGet-Build-Solution -sln $solutionFolder\$solutionName.sln `
        -rootFolder $rootFolder `
        -outputFolder $outputFolder `
        -platforms $platforms `
        -targetFrameworks $targetFrameworks `
        -verbosity $verbosity `
        -config $config `
        -target $target `
        -version $packageVersion `
        -nuspec $nuspec

}

MyGet-Build-Success
