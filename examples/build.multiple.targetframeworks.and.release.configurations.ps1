# This is a thirdparty build file originating from:
# https://github.com/peters/assemblyinfo/blob/develop/myget.ps1

# Getting it to work
# 1) git clone https://github.com/peters/assemblyinfo.git
# 2) .\myget.ps1 -packageVersion 0.0.1

param(
    [string[]]$projects = @(
        "src\assemblyinfo\assemblyinfo.csproj"
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
$rootFolder = Split-Path -parent $script:MyInvocation.MyCommand.Path
. $rootFolder\myget.include.ps1

# MyGet
$packageVersion = MyGet-Package-Version $packageVersion

# Solution
$solutionName = "assemblyinfo"
$solutionFolder = Join-Path $rootFolder "src\$solutionName"
$outputFolder = Join-Path $rootFolder "bin\$solutionName"

# Clean
if($clean) { MyGet-Build-Clean $rootFolder }

# Download prerequisites 
if(-not (Test-Path $rootFolder\external\cecil\*)) {
    . (MyGet-NugetExe-Path) restore $project -NonInteractive
    git submodule update --init --recursive
}

# Platforms to build for
$platforms | ForEach-Object {
    $platform = $_

    # Projects to build
    $projects | ForEach-Object {
        
        $project = $_
        $buildOutputFolder = Join-Path $outputFolder "$packageVersion\$platform"

        $targetFrameworks | ForEach-Object {
            $tf = $_

            $MSBuildProperties = @()

            # Mono.Cecil
            switch -Exact ($tf) {
                v2.0 {
                    $config = "net_2_0_Release"
                    $MSBuildProperties += '/p:DefineConstants="READ_ONLY"'
                }
                v3.5 {
                    $config = "net_3_5_Release"
                    $MSBuildProperties += '/p:DefineConstants="READ_ONLY;NET_3_5"'
                }
                default {
                    $config = "net_4_0_Release"
                    $MSBuildProperties += '/p:DefineConstants="READ_ONLY;NET_4_0"'
                }
            }

            # Build project
            MyGet-Build-Project -rootFolder $rootFolder `
                -outputFolder $outputFolder `
                -project $project `
                -config $config `
                -target $target `
                -targetFramework $tf `
                -platform $platform `
                -verbosity $verbosity `
                -version $packageVersion `
                -MSBuildCustomProperties ($MSBuildProperties -join " ")

        }
        
        # Build .nupkg
        MyGet-Build-Nupkg -rootFolder $rootFolder `
            -outputFolder $buildOutputFolder `
            -project $project `
            -config $config `
            -version $packageVersion `
            -platform $platform

    }
}