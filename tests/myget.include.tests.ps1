$scriptsPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootFolder = Join-Path $scriptsPath ..

. $rootFolder\myget.include.ps1

# Bootstrap
$fixturesFolder = Join-Path $scriptsPath "fixtures"
$srcFolder = Join-Path $rootFolder "src"
$examplesFolder = Join-Path $rootFolder "examples"

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

    It "Should transform targetframework to clr targetframework value" {

        MyGet-TargetFramework-To-Clr "v2.0" | Should Be "net20"
        MyGet-TargetFramework-To-Clr "v3.5" | Should Be "net35"
        MyGet-TargetFramework-To-Clr "v4.0" | Should Be "net40"
        MyGet-TargetFramework-To-Clr "v4.5" | Should Be "net45"
        MyGet-TargetFramework-To-Clr "v4.5.1" | Should Be "net451"

    }

    It "Should be able to grep for a list of files" {
        
        $files = MyGet-Grep $rootFolder -pattern ".packages.config$"
        $files.Count | Should be 5

        $files = MyGet-Grep $rootFolder -recursive $false -pattern ".packages.config$"
        $files.Count | Should be 0
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

        It "Should return a valid value if env:PackageVersion is empty" {            
            MyGet-Set-EnvironmentVariable PackageVersion ""
            MyGet-Package-Version "0.0.1-TEST" | Should Be "0.0.1-TEST"
        }

        It "Should throw if packageversion is invalid" {
            MyGet-Set-EnvironmentVariable PackageVersion "abc"
            {    
                MyGet-Package-Version "1.0.0" | Should Throw
            }
        }

        It "Should return a valid path to nuget.exe" {
            MyGet-NugetExe-Path | Select-String {
                Test-Path $_ | Should Be $true
                Should Match "nuget.exe$" 
            } 
        }

        It "Should return a valid path to nunit-console.exe" {
            MyGet-NunitExe-Path | Select-String { 
                Test-Path $_ | Should Be $true
                Should Match "nunit-console.exe$"
            }
        }

        It "Should return a valid path to xunit.console.clr4.x86.exe" {
            MyGet-XunitExe-Path| Select-String { 
                Test-Path $_ | Should Be $true
                Should Match "xunit.console.clr4.x86.exe$"
            }
        }

    }

    Context "Local computer" {
        MyGet-Set-EnvironmentVariable "BuildRunner" ""

        It "Should return a valid value for env:BuildRunner" {
            MyGet-BuildRunner | Should BeNullOrEmpty
        }

        It "Should return a valid value for env:PackageVersion" {
            MyGet-Set-EnvironmentVariable PackageVersion ""
            MyGet-Package-Version "1.0.0-LOL" | Should Be "1.0.0-LOL"
        }

        It "Should throw if packageversion is invalid" {
            MyGet-Set-EnvironmentVariable PackageVersion ""
            {
                MyGet-Package-Version "abc" | Should Throw
            }
        }

        It "Should return a valid path to nuget.exe" {
            MyGet-NugetExe-Path | Select-String {
                Test-Path $_ | Should Be $true
                Should Match "nuget.exe$" 
            } 
        }

        It "Should return a valid path to nunit-console.exe" {
            MyGet-NunitExe-Path | Select-String { 
                Test-Path $_ | Should Be $true
                Should Match "nunit-console.exe$"
            }
        }

        It "Should return a valid path to xunit.console.clr4.x86.exe" {
            MyGet-XunitExe-Path| Select-String { 
                Test-Path $_ | Should Be $true
                Should Match "xunit.console.clr4.x86.exe$"
            }
        }

    }
}

Describe "Nuget" {   
    It "Should read 'repositorypath' attribute from nuget.config'" {
        MyGet-NuGet-Get-PackagesPath $fixturesFolder\nuget.config | Should Be "C:\myteam\teampackages"
    }
}

Describe "Build" {
    #Context "Test Runners" {
        #It "Should run nunit test suite" {
            # TODO: Please contribute a PR @ https://www.github/peters/myget 
        #}

        #It "Should run xunit test suite" {
            # TODO: Please contribute a PR @ https://www.github/peters/myget
        #}
    #}
}