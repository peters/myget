param(
    [string]$packageVersion = "1.0.0",
    [string[]]$configurations = @("Debug", "Release")
)

# Initialization
$rootFolder = Split-Path -parent $script:MyInvocation.MyCommand.Definition

# Build for multiple configurations
$configurations | ForEach-Object {
    $config = $_

    # AnyCpu
    . $rootFolder\build.sample.anycpu-BUILD-SOLUTION.ps1 -packageVersion $packageVersion -config $config
    . $rootFolder\build.sample.anycpu-BUILD-SOLUTION-SPECIFIC-PROJECT.ps1 -packageVersion $packageVersion -config $config
    . $rootFolder\build.sample.anycpu-BUILD-SOLUTION-SPECIFIC-PROJECTS.ps1 -packageVersion $packageVersion -config $config

    # x86/x64
    . $rootFolder\build.sample.x86.x64-BUILD-SOLUTION.ps1 -packageVersion $packageVersion -config $config

}
