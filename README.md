# MyGet

A complete build suite for creating NuGet packages for miscellaneous CI build environments (think [MyGet](http://www.myget.org)). How does it work? Simply include the  ```myget.include.ps1``` script in your ```build.ps1``` on MyGet and use the provided functions.

Note these scripts will also work without a CI server, for example on your local computer.

# Getting started

Checkout the [examples](https://github.com/peters/myget/tree/master/examples).

If you want ```myget.include.ps1``` to work on you local computer you need to have [msysgit](https://code.google.com/p/msysgit/downloads/list) installed.

You might want to add `.buildtools` to your .gitignore.

# Run unit tests
```
.\powershelltests.ps1
```

# Build all examples

```
.\examples\build.all.samples.ps1
```

# Update myget.include.ps1

```
.\myget.include.ps1 -updateSelf 1
```

# Available functions
The ```myget.include.ps1``` script can be included by your ```build.ps1``` script to make use of the following functions:

## Build agent communication
* ```MyGet-Write-Diagnostic``` - writes a diagnostic message to the standard output
* ```MyGet-Build-Success``` - report build success
* ```MyGet-Die``` - report build failure

## Utility functions
* ```MyGet-Create-Folder``` - create a new folder
* ```MyGet-Build-Clean``` - recursive clean a folder
* ```MyGet-Grep``` -grep-like function
* ```MyGet-Normalize-Path``` normalize a file system path
* ```MyGet-Normalize-Paths``` normalize an array of file system paths
* ```MyGet-EnvironmentVariable``` returns value of an environment variable
* ```MyGet-Set-EnvironmentVariable``` create / overwrite an existing environment variable value

* ```MyGet-BuildRunner``` - returns the current build runner (empty if not run within MyGet Build Services)
* ```MyGet-Package-Version``` - returns the package version under build (empty if not run within MyGet Build Services)
* ```MyGet-NunitExe-Path``` - path to the NUnit test runner 
* ```MyGet-XunitExe-Path``` - path to the XUnit test runner
* ```MyGet-TargetFramework-To-Clr``` Target framework version to clr (e.g v2.0 -> net20)
* ```MyGet-TargetFramework-To-Clr``` Clr to target framework version (e.g net20 -> v2.0)
* ```MyGet-AssemblyInfo``` Read miscellaneous information from a binary (e.g TargetFramework, Processor architecture ++)
* ```MyGet-AssemblyInfo-Set``` Set AssemblyInfo.cs version (Assembly, AssemblyFileVersion, AssemblyInformationalVersion)
* ```MyGet-AssemblyInfo-Set``` Set AssemblyInfo.cs version (Assembly, AssemblyFileVersion, AssemblyInformationalVersion)
# ```MyGet-HipChatRoomMessage``` Send messages to a hipchat room.

## Nuget utility functions
* ```MyGet-NugetExe-Path``` - path to NuGet 
* ```MyGet-NuGet-Get-PackagesPath``` returns value of ```repositorypath``` attribute in ```nuget.config``` for a given project folder

## Build steps
* ```MyGet-Build-Bootstrap``` - starts a build (including NuGet package restore)
* ```MyGet-Build-Solution``` - starts a build of a solution file
* ```MyGet-Build-Project``` - starts a build of a project file
* ```MyGet-Build-Nupkg``` - creates a NuGet package based on a specified .nuspec file. The .nuspec can contain [additional replacement tokens](https://github.com/peters/myget#nuspec-substitutions)

## Test runners
* ```MyGet-TestRunner-Nunit``` - invoke NUnit
* ```MyGet-TestRunner-Xunit``` - invoke XUnit

## [BuildTools](https://github.com/myget/BuildTools)
* ```MyGet-CurlExe-Path``` - path to Curl

## [Squirrel](https://github.com/Squirrel/Squirrel.Windows)
* ```MyGet-Squirrel-New-Release``` - creates a new squirrel release

## [Curl](http://curl.haxx.se/docs/manpage.html)
* ```MyGet-Curl-Upload-File``` - upload files using either scp or sftp (private/public key required)

# NuSpec substitutions

** = **Provided by MyGet**

<table border="0" cellpadding="3" cellspacing="0" width="90%">
    <tr>
        <th align="left" width="190">
            Variable
        </th>
        <th align="left">
            Description
        </th>
    </tr>
    <tr>
        <td>$outputfolder$ **</td>
        <td>
            bin\$version$\$platform$\$configuration$ -> bin\(x86|x64|AnyCpu)\1.0.0\(v2.0|v3.5|v4.0|v4.5|v4.5.1)
        </td>
    </tr>
    <tr>
        <td>$platform$ **</td>
        <td>x86|x64|AnyCpu</td>
    </tr>
    <tr>
        <td>$nuspecfolder$ **</td>
        <td>Folder where nuspec resides in a project</td>
    </tr>
    <tr>
        <td>$configuration$ **</td>
        <td>Debug|Release (You decide this value)</td>
    </tr>
    <tr>
        <td>$id$</td>
        <td>The Assembly name</td>
    </tr>
    <tr>
        <td>$version$</td>
        <td>The assembly version as specified in the assembly’s AssemblyVersionAttribute. If the assembly’s AssemblyInformationalVersionAttribute is specified, that one is used instead.</td>
    </tr>
    <tr>
        <td>$author$</td>
        <td>The company as specified in the AssemblyCompanyAttribute.</td>
    </tr>
    <tr>
        <td>$description$</td>
        <td>The company as specified in the AssemblyCompanyAttribute.</td>
    </tr>
</tr>
</table>

# Script parameters

<table border="0" cellpadding="3" cellspacing="0" width="90%">
    <tr>
        <th align="left" width="190">
            Parameter
        </th>
        <th align="left">
            Description
        </th>
    </tr>
    <tr>
        <td>-packageVersion</td>
        <td>
            Package version to build. If building using a CI server, $env:PackageVersion is used instead.
        </td>
    </tr>
    <tr>
        <td>-config</td>
        <td>
            Debug, Release (Or custom build configuration name)
        </td>
    </tr>
    <tr>
        <td>-platforms</td>
        <td>
            x86, x64, AnyCpu 
        </td>
    </tr>
    <tr>
        <td>-targetFrameworks</td>
        <td>
            v2.0, v3.5, v4.0, v4.5, v4.5.1
        </td>
    </tr>
    <tr>
        <td>-target</td>
        <td>
            Build, Rebuild
        </td>
    </tr>
    <tr>
        <td>-verbosity (MSBuild)</td>
        <td>
            Quiet, Minimal, Normal, Detailed, Diagnostic
        </td>
    </tr>
    <tr>
        <td>-clean</td>
        <td>
            Set clean to 0 if you wish to avoid gardening of all bin,obj,build folders
        </td>
    </tr>
</table>

# License

The MIT License (MIT)

Copyright (c) 2013 Peter Rekdal Sunde

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
