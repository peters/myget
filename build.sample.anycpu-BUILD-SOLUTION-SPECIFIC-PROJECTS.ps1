param(
    [string[]]$projects = @(
        "src\sample.solution.anycpu\sample.solution.anycpu\sample.solution.anycpu.csproj"
        "src\sample.solution.anycpu\sample.solution.infrastructure.anycpu\sample.solution.infrastructure.anycpu.csproj"
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

# Build folders
$solutionName = "sample.solution.anycpu"
$solutionFolder = Join-Path $rootFolder "src\$solutionName"
$outputFolder = Join-Path $rootFolder "bin\$solutionName"

# Myget
$packageVersion = MyGet-Package-Version $packageVersion
$nugetExe = MyGet-NugetExe-Path

# Exclude projects
$excludeNupkgProjects = @(
    $projects[1]
)

# Bootstrap
if($clean) { MyGet-Build-Clean $rootFolder }

# Build projects
$platforms | ForEach-Object {
    $platform = $_

    # Build each project
    $projects | ForEach-Object {
       
        $project = $_
        $nugetOutputPath = Join-Path $outputFolder "$packageVersion\$platform\$config"

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
        if(-not ($excludeNupkgProjects -contains $project)) {
            MyGet-Build-Nupkg -rootFolder $rootFolder `
                -outputFolder $nugetOutputPath `
                -project $project `
                -config $config `
                -version $packageVersion `
                -platform $platform
        }

    }
}
MyGet-Build-Success