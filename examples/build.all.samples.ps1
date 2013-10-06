param(
    [string]$packageVersion = "1.0.0",
    [string[]]$configurations = @("Debug", "Release")
)

# Initialization
$examplesFolder = Split-Path -parent $script:MyInvocation.MyCommand.Path

# Build for multiple configurations
$configurations | ForEach-Object {
    $config = $_
	
	# Run powershell unit tests for myget.include.ps1
	git submodule update --init --recursive
	#. $examplesFolder\powershelltests.ps1

    # AnyCpu
    . $examplesFolder\build.sample.anycpu-BUILD-SOLUTION.ps1 -packageVersion $packageVersion -config $config
    . $examplesFolder\build.sample.anycpu-BUILD-SOLUTION-SPECIFIC-PROJECT.ps1 -packageVersion $packageVersion -config $config
    . $examplesFolder\build.sample.anycpu-BUILD-SOLUTION-SPECIFIC-PROJECTS.ps1 -packageVersion $packageVersion -config $config

    # x86/x64
    . $examplesFolder\build.sample.x86.x64-BUILD-SOLUTION.ps1 -packageVersion $packageVersion -config $config

}
