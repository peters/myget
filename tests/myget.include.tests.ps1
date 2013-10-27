$scriptsPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootFolder = Join-Path $scriptsPath ..

. $rootFolder\myget.include.ps1

# Bootstrap
$fixturesFolder = Join-Path $scriptsPath "fixtures"
$srcFolder = Join-Path $rootFolder "src"
$examplesFolder = Join-Path $rootFolder "examples"
$buildOutputFolder = Join-Path $rootFolder "bin"

# Helpers

function Create-Folder {
    param(
        [parameter(Position = 0, Mandatory = $true)]
        [string]$folder
    )

    New-Item -ItemType Directory -Path $folder
}

function Delete-Folder {
    param(
        [parameter(Position = 0, Mandatory = $true)]
        [string]$folder
    )

    Remove-Item $folder -Force -Recurse
}

# Test cases

Describe "Test helper methods" {
    It "Should set the BuildRunner environment variable" {
        MyGet-Set-EnvironmentVariable "BuildRunner" "test"

        MyGet-BuildRunner | Should Be "test"
    }

    It "Should clear a BuildRunner environment variable" {
        MyGet-Set-EnvironmentVariable "BuildRunner" ""

        MyGet-BuildRunner | Should BeNullOrEmpty
    }

    It "Should be able to create/delete a folder" {
        Create-Folder "tests" 
        Test-Path "tests" | Should Be $true

        Delete-Folder "tests" 
        Test-Path "tests" | Should Be $false
    }
}


Describe "Utilitites" {
    It "Should be able to create a folder" {
        
        MyGet-Create-Folder "tests"

        Test-Path "tests" | Should Be $true

    }

    It "Should not crash if creating a folder that already exists" {
        
        MyGet-Create-Folder "tests" 

        Delete-Folder "tests"

    }

    It "Should get environment variable" {
        MyGet-EnvironmentVariable "path" | Should not BeNullOrEmpty
    }

    It "Should set environment variable" {

        $name = "testvariable"
        $value = "hello world"

        MyGet-Set-EnvironmentVariable $name $value
        MYget-EnvironmentVariable $name | Should be $value
    }

    It "Should be able to normalize a path" {
        
        $testPath = "..\examples"

        MyGet-Normalize-Path $testPath | Select-String {
            $_.Length > $testPath.Length | Should Be $true
        }

    }

    It "Should be able to normalize multiple paths" {
        
        $testFolder = "..\examples"
        $testFolders = @(
            "myget.include.tests.ps1",
            "myget.include.tests.ps1",
            "myget.include.tests.ps1"
        )

        MyGet-Normalize-Paths $testFolder $testFolders | ForEach-Object {
            $_.Length > $testFolder.Length | Should Be $true
        }

    }

    It "Should transform targetframework to clr runtime" {

        MyGet-TargetFramework-To-Clr "v2.0" | Should Be "net20"
        MyGet-TargetFramework-To-Clr "v3.5" | Should Be "net35"
        MyGet-TargetFramework-To-Clr "v4.0" | Should Be "net40"
        MyGet-TargetFramework-To-Clr "v4.5" | Should Be "net45"
        MyGet-TargetFramework-To-Clr "v4.5.1" | Should Be "net451"

    }

    It "Should transform clr runtime to targetframework" {

        MyGet-Clr-To-TargetFramework "net20" | Should Be "v2.0"
        MyGet-Clr-To-TargetFramework "net35" | Should Be "v3.5"
        MyGet-Clr-To-TargetFramework "net40" | Should Be "v4.0"
        MyGet-Clr-To-TargetFramework "net45" | Should Be "v4.5"
        MyGet-Clr-To-TargetFramework "net451" | Should Be "v4.5.1"

    }

    It "Should be able to grep for a list of files" {
        
        $files = MyGet-Grep $rootFolder -pattern ".packages.config$"
        $files.Count | Should be 3

        $files = MyGet-Grep $rootFolder -recursive $false -pattern ".packages.config$"
        $files.Count | Should be 0
    }

    It "Should read assembly info" {
        $assemblyInfo = MyGet-AssemblyInfo (MyGet-NuGetExe-Path)

        $assemblyInfo.ProcessorArchitecture | Should Be "AnyCpu"
        $assemblyInfo.PEFormat | Should Be "PE32"
        $assemblyInfo.Filename | Should Match "nuget.exe$"
        $assemblyInfo.ModuleKind | Should Be "Console"
        $assemblyInfo.ModuleAttributes | Should Be @("ILOnly", "Required32Bit", "StrongNameSigned")
        $assemblyInfo.ModuleCharacteristics | Should Be @("DynamicBase", "NoSEH", "NXCompat", "TerminalServerAware")
        $assemblyInfo.TargetFramework | Should Be "NET40"
        $assemblyInfo.MajorRuntimeVersion | Should Be 2
        $assemblyInfo.MinorRuntimeVersion | Should Be 5

    }

}

Describe "Prerequisites" {
    Context "CI" {
        MyGet-Set-EnvironmentVariable "BuildRunner" "myget"

        It "Should return a valid value for env:BuildRunner" {
            MyGet-BuildRunner | Should Be "myget"
        }

        It "Should return a valid value for env:PackageVersion" {
            MyGet-Set-EnvironmentVariable PackageVersion "1.0.0-NINJA"
            MyGet-Package-Version "1.0.0-LOL01" | Should Be "1.0.0-NINJA"
        }

        It "Should throw if env:PackageVersion is invalid" {
            MyGet-Set-EnvironmentVariable PackageVersion ""
            {
                MyGet-Package-Version $null | Should Throw
                MyGet-Package-Version "" | Should Throw
                MyGet-Package-Version "1.0.0" | Should Throw
                MyGet-Package-Version | Should Not Throw
            }
        }

        It "Should return a valid value if env:PackageVersion is set but input PackageVersion is null" {            
            MyGet-Set-EnvironmentVariable PackageVersion "0.0.1-TEST1"
            MyGet-Package-Version $null | Should Be "0.0.1-TEST1"
        }

        It "Should return a valid path to nuget.exe" {
            $nuget = MyGet-NugetExe-Path 
            (Test-Path $nuget) | Should Be $true
            $nuget | Should Match "nuget.exe$" 
        }

        It "Should return a valid path to nunit-console.exe" {
            $nunit = MyGet-NunitExe-Path
            (Test-Path $nunit) | Should Be $true
            $nunit | Should Match "nunit-console.exe$"
        }

        It "Should return a valid path to xunit.console.clr4.x86.exe" {
            $xunit = MyGet-XunitExe-Path
            (Test-Path $xunit) | Should Be $true
            $xunit | Should Match "xunit.console.clr4.x86.exe$"
        }

        It "Should return a valid path to curl.exe" {
            $curl = MyGet-CurlExe-Path
            (Test-Path $curl) | Should Be $true
            $curl | Should Match "curl.exe$"
        }

    }

    Context "Local computer" {
        MyGet-Set-EnvironmentVariable "BuildRunner" ""

        It "Should return a valid value for env:BuildRunner" {
            MyGet-BuildRunner | Should BeNullOrEmpty
        }

        It "Should not use env:PackageVersion" {
            MyGet-Set-EnvironmentVariable PackageVersion ""
            MyGet-Package-Version "1.0.0-LOL" | Should Be "1.0.0-LOL"
        }

        It "Should throw if PackageVersion is invalid" {
            MyGet-Set-EnvironmentVariable PackageVersion ""
            {
                MyGet-Package-Version $null | Should Throw
                MyGet-Package-Version "" | Should Throw
            }
            MyGet-Package-Version "1.0.0" | Should Be "1.0.0"
        }

        It "Should return a valid path to nuget.exe" {
            $nuget = MyGet-NugetExe-Path 
            (Test-Path $nuget) | Should Be $true
            $nuget | Should Match "nuget.exe$" 
        }

        It "Should return a valid path to nunit-console.exe" {
            $nunit = MyGet-NunitExe-Path
            (Test-Path $nunit) | Should Be $true
            $nunit | Should Match "nunit-console.exe$"
        }

        It "Should return a valid path to xunit.console.clr4.x86.exe" {
            $xunit = MyGet-XunitExe-Path
            (Test-Path $xunit) | Should Be $true
            $xunit | Should Match "xunit.console.clr4.x86.exe$"
        }

        It "Should return a valid path to curl.exe" {
            $curl = MyGet-CurlExe-Path
            (Test-Path $curl) | Should Be $true
            $curl | Should Match "curl.exe$"
        }

    }
}

Describe "Nuget" {   
    It "Should read 'repositorypath' attribute from nuget.config'" {
        MyGet-NuGet-Get-PackagesPath $fixturesFolder\nuget.config | Should Be "C:\myteam\teampackages"
    }
}

Describe "Cleanup" {
    It "Should reset environment settings" {
        MyGet-Set-EnvironmentVariable "BuildRunner" ""
        MyGet-EnvironmentVariable "BuildRunner" | Should BeNullOrEmpty
        MyGet-Set-EnvironmentVariable "PackageVersion" ""
        MyGet-EnvironmentVariable "PackageVersion" | Should BeNullOrEmpty
    }
}