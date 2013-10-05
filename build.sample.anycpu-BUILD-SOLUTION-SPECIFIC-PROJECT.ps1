param(
    [string[]]$projects = @(
        "src\sample.solution.anycpu\sample.solution.anycpu\sample.solution.anycpu.csproj"
    ),
    [string[]]$platforms = @(
        "AnyCpu"
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
$rootFolder = Split-Path -parent $script:MyInvocation.MyCommand.Definition
. $rootFolder\myget.include.ps1

# Myget
$packageVersion = MyGet-Package-Version $packageVersion

# Solution
$solutionName = "sample.solution.anycpu"
$solutionFolder = Join-Path $rootFolder "src\$solutionName"
$outputFolder = Join-Path $rootFolder "bin\$solutionName"

# Clean
if($clean) { MyGet-Build-Clean $rootFolder }

# Platforms to build for
$platforms | ForEach-Object {
    $platform = $_

    # Projects to build
    $projects | ForEach-Object {
        
        $project = $_
        $buildOutputFolder = Join-Path $outputFolder "$packageVersion\$platform\$config"

        # Build project
        MyGet-Build-Project -rootFolder $rootFolder `
            -outputFolder $outputFolder `
            -project $project `
            -config $config `
            -target $target `
            -targetFrameworks $targetFrameworks `
            -platform $platform `
            -version $packageVersion `
    
        # Build .nupkg
        MyGet-Build-Nupkg -rootFolder $rootFolder `
            -outputFolder $buildOutputFolder `
            -project $project `
            -config $config `
            -version $packageVersion `
            -platform $platform

    }
}

MyGet-Build-Success
