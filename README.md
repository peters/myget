# MyGet

A complete build suite for creating nuget packages for miscellaneous CI build environments (think MyGet).
As a an extra bonus these scripts will work without a CI serverlso. In short that means that you can use
these scripts locally.

# Awesome?

Check out the [tutorials]() over at MyGet.

# Standalone (wihout MyGet)

Script parameters
---
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
        <td>-verbosity (Msbuild)</td>
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

AnyCpu
---

Build all projects in solution.

```ps
.\build.sample.solution.anycpu.ps1 -packageVersion 1.0.0
```

X86/X64
---

Build all projects in solution for both x86/x64.

```ps
.\build.sample.solution.x86.x64.ps1 -packageVersion 1.0.0 -platforms @('x86','x64')
```

X86
---

Build all projects in solution for both x86 only.

```ps
.\build.sample.solution.x86.x64.ps1 -packageVersion 1.0.0 -platforms @('x86')
```

Build a single project in solution for x86 only.

```ps
.\build.sample.solution.x86.x64.ps1 -packageVersion 1.0.0 -platforms @('x86')
```

X64
---

Build all projects in solution for both x64 only.

```ps
.\build.sample.solution.x86.x64.ps1 -packageVersion 1.0.0 -platforms @('x64')
```

Build all projects in solution for both x64 only.

```ps
.\build.sample.solution.x86.x64.ps1 -packageVersion 1.0.0 -platforms @('x64')
```

Build.ps1 (Solution)
---

```ps

```

Build.ps1 (Single project)
---
```ps


```

MyGet build properties (packages.conf)
============================
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
        <td>$bin$</td>
        <td>
            bin\$version$\$platform$\$configuration$ -> bin\(x86|x64|AnyCpu)\1.0.0\(v2.0|v3.5|v4.0|v4.5|v4.5.1)
        </td>
    </tr>
	  <tr>
        <td>$platform$</td>
        <td>x86|x64|AnyCpu</td>
    </tr>
	  <tr>
        <td>$configuration$</td>
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
