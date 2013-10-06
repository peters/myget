# You can always find an updated version @ https://raw.github.com/peters/myget/master/myget.include.ps1

# Miscellaneous

function MyGet-Write-Diagnostic {
    param(
        [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$message
    )

    Write-Host
    Write-Host $message -ForegroundColor Green
    Write-Host
}

function MyGet-Die {
    param(
        [parameter(Position = 0, ValueFromPipeline = $true)]
        [string]$message,

        [parameter(Position = 1, ValueFromPipeline = $true)]
        [object[]]$output,

        [parameter(Position = 2, ValueFromPipeline = $true)]
        [int]$exitCode = 1
    )

    if ($output) {
		Write-Output $output
		$message += ". See output above."
	}

	Write-Error "$message exitCode: $exitCode"
	exit $exitCode

}

function MyGet-Create-Folder {
    param(
        [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$folder
    )
     
    if(-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder
    }
    
}

function MyGet-Grep {
    param(
        [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$folder,

        [parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$pattern,

        [parameter(Position = 2, ValueFromPipeline = $true)]
        [bool]$recursive = $true
    )

    if($recursive) {
        return Get-ChildItem $folder -Recurse | Where-Object { $_.FullName -match $pattern } 
    }

    return Get-ChildItem $folder | Where-Object { $_.FullName -match $pattern } 
}

function MyGet-EnvironmentVariable {
    param(
        [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$name
    )

    return [Environment]::GetEnvironmentVariable($name)
}

function MyGet-Set-EnvironmentVariable {
    param(
        [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$name,
        [parameter(Position = 1, ValueFromPipeline = $true)]
        [string]$value
    )

    [Environment]::SetEnvironmentVariable($name, $value)
}

function MyGet-BuildRunner {
    
    $buildRunner = MyGet-EnvironmentVariable "BuildRunner"

    if([String]::IsNullOrEmpty($buildRunner)) {
        return ""
    }

    return $buildRunner.tolower()

}

function MyGet-Package-Version {
    param(
        [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [ValidatePattern("^([0-9]+)\.([0-9]+)\.([0-9]+)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+[0-9A-Za-z-]+)?$")]
        [string]$packageVersion
    )

    $buildRunner = MyGet-BuildRunner
    if([String]::IsNullOrEmpty($buildRunner)) {
        return $packageVersion
    }

    $envPackageVersion = MyGet-EnvironmentVariable "PackageVersion"
    if([String]::IsNullOrEmpty($envPackageVersion)) {
        return $packageVersion
    }

    return $envPackageVersion

}

function MyGet-NugetExe-Path {
    
    if (Test-Path env:myget) {
        return Join-Path (Get-Content env:myget) "nuget\nuget.exe"
    } elseif(Test-Path env:nuget) { 
        return Get-Content env:nuget 
    }
    
    MyGet-Die "Could not find nuget executable"
}

function MyGet-NunitExe-Path {
    
    if (Test-Path env:myget) {
        return Join-Path (Get-Content env:myget) "nunit\nunit-console.exe"
    } elseif(Test-Path env:nunit) { 
        return Get-Content env:nunit 
    }

    MyGet-Die "Could not find nunit executable"

}

function MyGet-XunitExe-Path {

    if (Test-Path env:myget) {
        return Join-Path (Get-Content env:myget) "xunit\xunit.console.clr4.x86.exe"
    } elseif(Test-Path env:xunit) { 
        return Get-Content env:xunit 
    }

    MyGet-Die "Could not find xunit executable"

}

function MyGet-Normalize-Path {
    param(
        [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$path
    )

    return [System.IO.Path]::GetFullPath($path)
}


function MyGet-Normalize-Paths {
    param(
        [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$basePath,

        [parameter(Position = 1, ValueFromPipeline = $true)]
        [string[]]$paths = @()
    )

    if($paths -isnot [System.Array]) {
        return @()
    }

    $i = 0
    $paths | ForEach-Object {
        $paths[$i] = [System.IO.Path]::Combine($basePath, $paths[$i])
        $i++;
    }

}

function MyGet-TargetFramework-To-Clr {
    param(
        [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateSet("v2.0", "v3.5", "v4.0", "v4.5", "v4.5.1")]
        [string]$targetFramework
    )

    $clr = $null

    switch -Exact ($targetFramework.ToLower()) {
        "v2.0" {
            $clr = "net20"
        }
        "v3.5" {
            $clr = "net35"
        } 
        "v4.0" {
            $clr = "net40"
        }
        "v4.5" {
            $clr = "net45"
        }
        "v4.5.1" {
            $clr = "net451"
        }
    }

    return $clr
}

# Build

function MyGet-Build-Success {

    MyGet-Write-Diagnostic "Build: Success"

    exit 0

}

function MyGet-Build-Clean {
	param(
        [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
	    [string]$rootFolder,
        [parameter(Position = 1, ValueFromPipeline=$true)]
        [string]$folders = "bin,obj"
    )

    MyGet-Write-Diagnostic "Build: Clean"

    Get-ChildItem $rootFolder -Include $folders -Recurse | ForEach-Object {
       Remove-Item $_.fullname -Force -Recurse 
    }

}

function MyGet-Build-Bootstrap {
    param(
        [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$project
    )

    MyGet-Write-Diagnostic "Build: Bootstrap"

    $solutionFolder = [System.IO.Path]::GetDirectoryName($project)
    $nugetExe = MyGet-NugetExe-Path

    . $nugetExe config -Set Verbosity=quiet

    if($project -match ".sln$") {
        . $nugetExe restore $project -NonInteractive
    }

    MyGet-Grep $rootFolder -recursive $true -pattern ".packages.config$" | ForEach-Object {
        . $nugetExe restore $_.FullName -NonInteractive -SolutionDirectory $solutionFolder
    }

}

function MyGet-Build-Nupkg {
    # http://docs.nuget.org/docs/reference/command-line-reference#Pack_Command

    param(
        [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$rootFolder,

        [parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$outputFolder,

        [parameter(Position = 2, Mandatory = $true, ValueFromPipeline = $true)]
        [ValidatePattern(".(sln|csproj)$")]
        [string]$project,

        [parameter(Position = 3, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$config,
        
        [parameter(Position = 4, Mandatory = $true, ValueFromPipeline = $true)]
        [ValidatePattern("^([0-9]+)\.([0-9]+)\.([0-9]+)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+[0-9A-Za-z-]+)?$")]
        [string]$version,

        [parameter(Position = 5, Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateSet("x86", "x64", "AnyCpu")]
        [string]$platform,

        [parameter(Position = 6, ValueFromPipeline = $true)]
        [string]$nuspec = $null,

        [parameter(Position = 7, ValueFromPipeline = $true)]
        [string]$nugetProperties = $null
    )
    
    if(-not (Test-Path $project)) {
        MyGet-Die "Could not find project: $project"
    }

    if($nuspec -eq "" -or (-not (Test-Path $nuspec))) {
        $nuspec = [System.IO.Path]::Combine($rootFolder, $project) -ireplace ".(sln|csproj)$", ".nuspec"
    }

    if(-not (Test-Path $nuspec)) {
        MyGet-Die "Could not find nuspec: $nuspec"
    }

    $rootFolder = MyGet-Normalize-Path $rootFolder
    $outputFolder = MyGet-Normalize-Path $outputFolder
    $nuspec = MyGet-Normalize-Path $nuspec
	
    $projectName = [System.IO.Path]::GetFileName($project) -ireplace ".(sln|csproj)$", ""

    # Nuget
    $nugetCurrentFolder = [System.IO.Path]::GetDirectoryName($nuspec)
    $nugetExe = MyGet-NugetExe-Path
    $nugetProperties = @(
        "Configuration=$config",
        "Platform=$platform",
        "OutputFolder=$outputFolder",
        "NuspecFolder=$nugetCurrentFolder",
        "$nugetProperties"
    ) -join ";"

    MyGet-Write-Diagnostic "Nupkg: $projectName ($platform / $config)"
    
    . $nugetExe pack $nuspec -OutputDirectory $outputFolder -Symbols -NonInteractive `
        -Properties "$nugetProperties" -Version $version
    
    if($LASTEXITCODE -ne 0) {
        MyGet-Die "Build failed: $projectName" -exitCode $LASTEXITCODE
    }
    
    # Support multiple build runners
    switch -Exact (MyGet-BuildRunner) {
        "myget" {
                
            $mygetBuildFolder = Join-Path $rootFolder "Build"

            MyGet-Create-Folder $mygetBuildFolder

            MyGet-Grep $outputFolder -recursive $false -pattern ".nupkg$" | ForEach-Object {
                $filename = $_.Name
                $fullpath = $_.FullName
		
		        cp $fullpath $mygetBuildFolder\$filename
            }

        }
    }

}

function MyGet-Build-Project {
    param(
        [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$rootFolder,

        [parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$outputFolder,

        [parameter(Position = 2, Mandatory = $true, ValueFromPipeline = $true)]
        [ValidatePattern(".(sln|csproj)$")]
        [string]$project,

        [parameter(Position = 3, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$config,

        [parameter(Position = 4, Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateSet("rebuild", "build")]
        [string]$target,

        [parameter(Position = 5, Mandatory = $true, ValueFromPipeline = $true)]
        [ValidatePattern("^([0-9]+)\.([0-9]+)\.([0-9]+)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+[0-9A-Za-z-]+)?$")]
        [string]$version,
        
        [parameter(Position = 6, Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateSet("v1.1", "v2.0", "v3.5", "v4.0", "v4.5", "v4.5.1")]
        [string[]]$targetFrameworks,

        [parameter(Position = 7, Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateSet("x86", "x64", "AnyCpu")]
        [string]$platform,

        [parameter(Position = 8, Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateSet("Quiet", "Minimal", "Normal", "Detailed", "Diagnostic")]
        [string]$verbosity = "Minimal",

        [parameter(Position = 9, ValueFromPipeline = $true)]
        [string]$MSBuildCustomProperties = $null
    )

    $projectOutputPath = Join-Path $outputFolder "$version\$platform\$config"
    $projectPath = [System.IO.Path]::Combine($rootFolder, $project)
    $projectName = [System.IO.Path]::GetFileName($projectPath) -ireplace ".(sln|csproj)$", ""

    MyGet-Create-Folder $outputFolder

    if(-Not (Test-Path $projectPath)) {
        MyGet-Die "Could not find project: $projectPath"
    }

    MyGet-Build-Bootstrap $projectPath

    $targetFrameworks | ForEach-Object {
        
        $targetFramework = $_
        $buildOutputFolder = Join-Path $projectOutputPath "$targetFramework"

        MyGet-Create-Folder $buildOutputFolder

        MyGet-Write-Diagnostic "Build: $projectName ($platform / $config - $targetFramework)"

        # By default copy build output to final output path
        $msbuildOutputFilename = Join-Path $buildOutputFolder "msbuild.log"
        switch -Exact (MyGet-BuildRunner) {
            "myget" {
                
                # Otherwise copy to root folder so that we can see the
                # actual build failure in MyGet web interface
                $msbuildOutputFilename = Join-Path $rootFolder "msbuild.log"

            }
        }

        # YOLO
        $msbuildPlatform = $platform
        if($msbuildPlatform -eq "AnyCpu") {
            $msbuildPlatform = "Any CPU"
        }

        # http://msdn.microsoft.com/en-us/library/vstudio/ms164311.aspx
        & "$(Get-Content env:windir)\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe" `
            $projectPath `
            /target:$target `
            /property:Configuration=$config `
            /property:OutputPath=$buildOutputFolder `
            /property:TargetFrameworkVersion=$targetFramework `
            /property:Platform=$msbuildPlatform `
            /maxcpucount `
            /verbosity:$verbosity `
            /fileLogger `
            /fileLoggerParameters:LogFile=$msbuildOutputFilename `
            /nodeReuse:false `
            /nologo `
            $MSBuildCustomProperties `
        
        if($LASTEXITCODE -ne 0) {
            MyGet-Die "Build failed: $projectName ($Config - $targetFramework)" -exitCode $LASTEXITCODE
        }

    }

}

function MyGet-Build-Solution {
    param(
        [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [ValidatePattern(".sln$")]
        [string]$sln,

        [parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$rootFolder,

        [parameter(Position = 2, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$outputFolder,

        [parameter(Position = 3, Mandatory = $true, ValueFromPipeline = $true)]
        [ValidatePattern("^([0-9]+)\.([0-9]+)\.([0-9]+)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+[0-9A-Za-z-]+)?$")]
        [string]$version,

        [parameter(Position = 4, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$config,

        [parameter(Position = 5, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$target,

        [parameter(Position = 6, ValueFromPipeline = $true)]
        [string[]]$projects = @(),

        [parameter(Position = 7, Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$targetFrameworks,

        [parameter(Position = 8, Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$platforms,

        [parameter(Position = 9, ValueFromPipeline = $true)]
        [string]$verbosity = "quiet",
        
        [parameter(Position = 10, ValueFromPipeline = $true)]
        [string[]]$excludeNupkgProjects = @(),

        [parameter(Position = 11, ValueFromPipeline = $true)]
        [string]$nuspec = $null,

        [parameter(Position = 12, ValueFromPipeline = $true)]
        [string]$MSBuildCustomProperties = $null
    )

    if(-not (Test-Path $sln)) {
        MyGet-Die "Could not find solution: $sln"
    }

    $excludeNupkgProjects = MyGet-Normalize-Paths $rootFolder $excludeNupkgProjects
    $projectName = [System.IO.Path]::GetFileName($sln) -ireplace ".sln$", ""

    # Building a solution
    if($projects.Count -eq 0) {
        $projects = @($sln)
    # Building projects within a solution
    } else {
        $projects = MyGet-Normalize-Paths $rootFolder $projects
    }

    $projects | ForEach-Object {

        $project = $_

        $platforms | ForEach-Object {

            $platform = $_
            $finalBuildOutputFolder = Join-Path $outputFolder "$version\$platform\$config"
        
            MyGet-Build-Project -rootFolder $rootFolder -project $project -outputFolder $outputFolder `
                -target $target -config $config -targetFrameworks $targetFrameworks `
                -version $version -platform $platform -verbosity $verbosity `
                -MSBuildCustomProperties $MSBuildCustomProperties
    
            if(-not ($excludeNupkgProjects -contains $project)) {
                MyGet-Build-Nupkg -rootFolder $rootFolder -project $project -nuspec $nuspec -outputFolder $finalBuildOutputFolder `
                    -config $config -version $version -platform $platform
            }

        }
        
    }
}

# Nuget 

function MyGet-NuGet-Get-PackagesPath {
    # https://github.com/github/Shimmer/blob/master/src/CreateReleasePackage/tools/utilities.psm1#L199
    param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$folder
    )

    $cfg = Get-ChildItem -Path $folder -Filter nuget.config | Select-Object -first 1
    if($cfg) {
        [xml]$config = Get-Content $cfg.FullName
        $path = $config.configuration.config.add | ?{ $_.key -eq "repositorypath" } | select value
        # Found nuget.config but it don't has repositorypath attribute
        if($path) {
            return $path.value.Replace("$", $folder)
        }
    }

    $parent = Split-Path $folder

    if(-not $parent) {
        return $null
    }

    return MyGet-NuGet-PackagesPath($parent)
}

# Test runners

function MyGet-TestRunner-Nunit {
    param(
        [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$projects
    )

    MyGet-Write-Diagnostic "Running unit tests for: $csproj"
    
    $outputPath = [System.IO.Path]::GetTempFileName()
    $consoleRunner = MyGet-NunitExe-Path

    $args = $csproj
    [object[]] $output = "$consoleRunner " + ($args -join " ")
    $process = Start-Process -PassThru -NoNewWindow -RedirectStandardOutput $outputPath $consoleRunner ($args | %{ "`"$_`"" })

    Wait-Process -InputObject $process -Timeout $timeoutDuration -ErrorAction SilentlyContinue
    if ($process.HasExited) {
        $output += Get-Content $outputPath
        $exitCode = $process.ExitCode
    } else {
        $output += "Tests timed out. Backtrace:"
        $output += Get-DotNetStack $process.Id
        $exitCode = 9999
    }

    Stop-Process -InputObject $process
    Remove-Item $outputPath

    Write-Host $output

    if(-not ($exitCode -eq 0)) {
        MyGet-Die "Test failure. Exit code: $exitCode"
    }

    Write-Host "Test success."

}

function MyGet-TestRunner-Xunit {
    param(
        [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$projects
    ) 
    
    MyGet-Die "Not implemented. Please contribute a PR @ https://www.github/peters/myget"
}