# MIT LICENSE

# You can always find an updated version @ https://raw.github.com/peters/myget/master/myget.include.ps1

# Thanks to https://github.com/Squirrel/Squirrel.Windows 

# Prerequisites (You should add .buildtools to your .(git|hg)ignore)
$buildRunnerToolsFolder = Split-Path $MyInvocation.MyCommand.Path
$buildRunnerToolsFolder = Join-Path $buildRunnerToolsFolder ".buildtools"

# Miscellaneous

function MyGet-AssemblyInfo {
  # https://github.com/peters/assemblyinfo/blob/develop/getassemblyinfo.ps1

  # Sample output:
  # 
  # ProcessorArchitecture : AnyCpu
  # PEFormat              : PE32
  # Filename              : D:\sample.solution.mixedplatforms\1.0.0\x86\Release\v4.5\sample.solution.mixedplatforms.x86.exe
  # ModuleKind            : Console
  # ModuleAttributes      : {ILOnly, Required32Bit}
  # MinorRuntimeVersion   : 5
  # MajorRuntimeVersion   : 2
  # ModuleCharacteristics : {HighEntropyVA, DynamicBase, NoSEH, NXCompat...}
  # TargetFramework       : NET45

  param(
        [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string] $filename
  )

    if(-not (Test-Path -Path $filename)) {
        Write-Error "Could not find file: $filename"
        exit 1
    }

    function AssemblyInfo {
        param(
            [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
            [uint32] $peFormat = $null,
            [parameter(Position = 1, Mandatory = $false, ValueFromPipeline = $true)]
            [uint32] $attributes = $null,
            [parameter(Position = 2, Mandatory = $false, ValueFromPipeline = $true)]
            [uint32] $machine = $null,
            [parameter(Position = 3, Mandatory = $false, ValueFromPipeline = $true)]
            [uint16] $characteristics = $null,
            [parameter(Position = 4, Mandatory = $false, ValueFromPipeline = $true)]
            [object] $optionalHeaders = $null,
            [parameter(Position = 5, Mandatory = $false, ValueFromPipeline = $true)]
            [uint32] $majorRuntimeVersion = $null,
            [parameter(Position = 6, Mandatory = $false, ValueFromPipeline = $true)]
            [uint32] $minorRuntimeVersion = $null,
            [parameter(Position = 7, Mandatory = $false, ValueFromPipeline = $true)]
            [string] $targetFramework = $null
        )

        $assemblyInfo = @{}

        # Major/minor
        $assemblyInfo.Filename = $filename
        $assemblyInfo.MajorRuntimeVersion = $majorRuntimeVersion
        $assemblyInfo.MinorRuntimeVersion = $minorRuntimeVersion
        $assemblyInfo.TargetFramework = $targetFramework
        $assemblyInfo.ModuleKind = GetModuleKind -characteristics $characteristics -subSystem $optionalHeaders.SubSystem
        $assemblyInfo.ModuleCharacteristics = GetModuleCharacteristics -characteristics $characteristics
        $assemblyInfo.ModuleAttributes = GetModuleAttributes -attributes $attributes

        ## PeFormat
        if($peFormat -eq 0x20b) { 
            $assemblyInfo.PEFormat = "PE32Plus" 
        } elseif($peFormat -eq 0x10b) { 
            $assemblyInfo.PEFormat = "PE32" 
        }

        ## ProcessorArchitecture
        $assemblyInfo.ProcessorArchitecture = "Unknown"

        switch -Exact ($machine) {
            0x014c {
                $assemblyInfo.ProcessorArchitecture = "x86"
                if($assemblyInfo.ModuleAttributes -contains "ILOnly") {
                    $assemblyInfo.ProcessorArchitecture = "AnyCpu"
                }
            }
            0x8664 {
                $assemblyInfo.ProcessorArchitecture = "x64" 
            }
            0x0200 {
                $assemblyInfo.ProcessorArchitecture = "IA64"
            }
            0x01c4 {
                $assemblyInfo.ProcessorArchitecture = "ARMv7" 
            }
            default {
                if($assemblyInfo.PEFormat -eq "PE32PLUS") {
                    $assemblyInfo.ProcessorArchitecture = "x64"
                } elseif($assemblyInfo.PEFormat -eq "PE32") {
                    $assemblyInfo.ProcessorArchitecture = "x86"
                }
            }
        }

        return New-Object -TypeName PSObject -Property $assemblyInfo
    }

    function GetModuleKind {
        param(
            [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
            [uint32] $characteristics,
            [parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true)]
            [uint32] $subSystem
        )

        # ImageCharacteristics.Dll
        if($characteristics -eq ($characteristics -bor 0x2000)) {
            return "Dll"
        }

        # SubSystem.WindowsGui || SubSystem.WindowsCeGui
        if($subSystem -eq 0x2 -or $subSystem -eq 0x9) {
            return "WinExe"
        }

        return "Console"
    }

    function GetModuleCharacteristics {
        param(
            [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
            [uint16] $characteristics
        )

        $moduleCharacteristics = @()

        if($characteristics -eq ($characteristics -bor 0x0020)) {
            $moduleCharacteristics += "HighEntropyVA"
        }

        if($characteristics -eq ($characteristics -bor 0x0040)) {
           $moduleCharacteristics += "DynamicBase"
        }

        if($characteristics -eq ($characteristics -bor 0x0400)) {
            $moduleCharacteristics += "NoSEH"
        }

        if($characteristics -eq ($characteristics -bor 0x0100)) {
           $moduleCharacteristics += "NXCompat"
        }

        if($characteristics -eq ($characteristics -bor 0x1000)) {
            $moduleCharacteristics += "AppContainer"
        }

        if($characteristics -eq ($characteristics -bor 0x8000)) {
            $moduleCharacteristics += "TerminalServerAware"
        }

        return $moduleCharacteristics
    }

    function GetModuleAttributes {
        param(
            [parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
            [uint32] $attributes = $null
        )

        $moduleAttributes = @()

        if($attributes -eq ($attributes -bor 0x1)) {
            $moduleAttributes += "ILOnly"
        }

        if($attributes -eq ($attributes -bor 0x2)) {
            $moduleAttributes += "Required32Bit"
        }

        if($attributes -eq ($attributes -bor 0x8)) {
            $moduleAttributes += "StrongNameSigned"
        }

        if($attributes -eq ($attributes -bor 0x00020000)) {
            $moduleAttributes += "Preferred32Bit"
        }

        return $moduleAttributes

    }

    function Advance {
        param(
            [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
            [System.IO.Stream] $stream,
            [parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true)]
            [int] $count
        )

        $stream.Seek($count, [System.IO.SeekOrigin]::Current) | Out-Null
    }

    # https://github.com/jbevain/cecil/blob/master/Mono.Cecil.PE/ImageReader.cs#L238
    function ReadZeroTerminatedString {
        param(
            [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
            [System.IO.BinaryReader] $binaryReader,
            [parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true)]
            [int] $length
        )

        $read = 0
        $buffer = New-Object char[] $length
        $bytes = $binaryReader.ReadBytes($length)
        while($read -lt $length) {
            $current = $bytes[$read]
            if($current -eq 0) {
                break
            }        
            
            $buffer[$read++] = $current
        }

        return New-Object string ($buffer, 0, $read)
    }
    
    # https://github.com/jbevain/cecil/blob/master/Mono.Cecil.PE/Image.cs#L98
    # https://github.com/jbevain/cecil/blob/master/Mono.Cecil.PE/Image.cs#L107
    # https://github.com/jbevain/cecil/blob/master/Mono.Cecil.PE/Image.cs#L124
    function ResolveVirtualAddress {
        param(
            [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
            [uint32] $rva,
            [parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true)]
            [object[]] $sections
        )

        $section = $null

        $sections | ForEach-Object {
            if($rva -ge $_.VirtualAddress -and $rva -lt $_.VirtualAddress + $_.SizeOfRawData) {
                $section = $_
                return
            }
        }

        if($section -eq $null) {
            Write-Error "Unable to resolve virtual address for rva address: " $rva
            exit 1
        }

        return [System.Convert]::ToUInt32($rva + $section.PointerToRawData - $section.VirtualAddress)
    }

    # # https://github.com/jbevain/cecil/blob/master/Mono.Cecil.PE/Image.cs#L53
    function MoveTo {
        param(
            [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
            [System.IO.Stream] $stream,
            [parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true)]
            [object] $dataDirectory,
            [parameter(Position = 2, Mandatory = $true, ValueFromPipeline = $true)]
            [object] $sections
        )

        $stream.Position = ResolveVirtualAddress -rva ([uint32] $dataDirectory.VirtualAddress) -sections $sections
     }

    # https://github.com/jbevain/cecil/blob/master/Mono.Cecil.PE/BinaryStreamReader.cs#L46
    function ReadDataDirectory {
        param(
            [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
            [System.IO.BinaryReader] $binaryReader
        )

        $dataDirectory = @{}
        $dataDirectory.VirtualAddress = $binaryReader.ReadUInt32()
        $dataDirectory.VirtualSize = $binaryReader.ReadUInt32() 
        $dataDirectory.IsZero = $dataDirectory.VirtualAddress -eq 0 -and $dataDirectory.VirtualSize -eq 0

        return New-Object -TypeName PSObject -Property $dataDirectory
    }

    # https://github.com/jbevain/cecil/blob/master/Mono.Cecil.PE/ImageReader.cs#L140
    function ReadOptionalHeaders {
        param(
           [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
           [System.IO.BinaryReader] $binaryReader,
           [parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true)]
           [System.IO.Stream] $stream,
           [parameter(Position = 2, Mandatory = $true, ValueFromPipeline = $true)]
           [uint16] $peFormat
        )

        $optionalHeaders = @{}
        $optionalHeaders.PEFormat = $peFormat
        $optionalHeaders.SubSystem = $null
        $optionalHeaders.SubSystemMajor = $null
        $optionalHeaders.SubSystemMinor = $null
        $optionalHeaders.Characteristics = $null
        $optionalHeaders.CLIHeader = $null
        $optionalHeaders.Debug = $null

        # https://github.com/jbevain/cecil/blob/master/Mono.Cecil.PE/ImageReader.cs#L136
        Advance -stream $stream -count 44

        # SubSysMajor 2
        # SubSystemMinor 2
        $optionalHeaders.SubSystemMajor = $binaryReader.ReadUInt16()
        $optionalHeaders.SubSystemMinor = $binaryReader.ReadUInt16()

        Advance -stream $stream -count 18

        # SubSystem 2
        $optionalHeaders.SubSystem = $binaryReader.ReadUInt16()

        # DLLFlags
        $optionalHeaders.Characteristics = $binaryReader.ReadUInt16()

        # https://github.com/jbevain/cecil/blob/master/Mono.Cecil.PE/ImageReader.cs#L197
        if($peFormat -eq 0x20b) { 
            Advance -stream $stream -count 88  
        } else { 
            Advance -stream $stream -count 72 
        }
        # Debug 8
        $optionalHeaders.Debug = ReadDataDirectory -binaryReader $binaryReader

        # https://github.com/jbevain/cecil/blob/master/Mono.Cecil.PE/ImageReader.cs#L209
        Advance -stream $stream -count 56 

        # CLIHeader
        $optionalHeaders.CLIHeader = ReadDataDirectory -binaryReader $binaryReader

        # Reserved 8
        Advance -stream $stream -count 8 

        return New-Object -TypeName PSObject -Property $optionalHeaders
    }

    # https://github.com/jbevain/cecil/blob/master/Mono.Cecil.PE/BinaryStreamReader.cs#L48
    function ReadSections {
        param(
            [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
            [System.IO.BinaryReader] $binaryReader,
            [parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true)]
            [System.IO.Stream] $stream,
            [parameter(Position = 2, Mandatory = $true, ValueFromPipeline = $true)]
            [uint16] $count
        )

        # https://github.com/jbevain/cecil/blob/master/Mono.Cecil.PE/ImageReader.cs#L289
        function ReadSection {
            param(
                [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
                [System.IO.Stream] $stream,
                [parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true)]
                [object] $section
            )
            
            # Save current position
            $position = $stream.Position

            # Move to pointer
            $stream.Position = $section.PointerToRawData

            # Reader pointer value
            $length = [System.Convert]::ToInt32($section.SizeOfRawData)
            $data = New-Object byte[] $length
            $offset = 0
            $read = 0

            while (($read = $stream.Read($data, $offset, $length - $offset)) -gt 0) {
                $offset += $read
            }

            $section.Data = $data

            # Restore old position
            $stream.Position = $position

            return $section

        }

        $sections = New-Object object[] $count

        for($i = 0; $i -lt $count; $i++) {

            $section = @{}

            # Name
            $section.Name = ReadZeroTerminatedString -binaryReader $reader -length 8

            # Data
            $section.Data = $null

            # VirtualSize 4
            Advance -stream $stream -count 4

            # VirtualAddress        4
            $section.VirtualAddress = $binaryReader.ReadUInt32()

            # SizeOfRawData        4
            $section.SizeOfRawData = $binaryReader.ReadUInt32()

            # PointerToRawData        4
            $section.PointerToRawData = $binaryReader.ReadUInt32()

            # PointerToRelocations                4
            # PointerToLineNumbers                4
            # NumberOfRelocations                2
            # NumberOfLineNumbers                2
            # Characteristics                        4
            Advance -stream $stream -count 16 

            # Read section data
            $section = (ReadSection -stream $stream -section $section)

            # Add section
            $sections[$i] = New-Object -TypeName PSObject -Property $section

        }

        return $sections

    }

    # https://github.com/jbevain/cecil/blob/master/Mono.Cecil.PE/ImageReader.cs#L307
    function ReadCLIHeader {
        param(
            [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
            [System.IO.BinaryReader] $binaryReader,
            [parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true)]
            [System.IO.Stream] $stream,
            [parameter(Position = 2, Mandatory = $true, ValueFromPipeline = $true)]
            [object] $dataDirectory,
            [parameter(Position = 3, Mandatory = $true, ValueFromPipeline = $true)]
            [object] $sections
        )

        MoveTo -stream $stream -dataDirectory $dataDirectory -sections $sections

        # 4 because of major/minor
        Advance -stream $stream -count 4

        $cliHeader = @{}
        $cliHeader.MajorRuntimeVersion = $binaryReader.ReadUInt16()
        $cliHeader.MinorRuntimeVersion = $binaryReader.ReadUInt16()
        $cliHeader.Metadata = ReadDataDirectory -binaryReader $binaryReader 
        $cliHeader.Attributes = $binaryReader.ReadUInt32()
        $cliHeader.EntryPointToken = $binaryReader.ReadUInt32()
        $cliHeader.Resources = ReadDataDirectory -binaryReader $binaryReader 
        $cliHeader.StrongName = ReadDataDirectory -binaryReader $binaryReader 
    
        return New-Object -TypeName PSObject -Property $cliHeader
    }

    # https://github.com/jbevain/cecil/blob/master/Mono.Cecil.PE/ImageReader.cs#L334
    function GetTargetFrameworkVersion {
        param(
            [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
            [System.IO.BinaryReader] $binaryReader,
            [parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true)]
            [System.IO.Stream] $stream,
            [parameter(Position = 2, Mandatory = $true, ValueFromPipeline = $true)]
            [object] $dataDirectory,
            [parameter(Position = 3, Mandatory = $true, ValueFromPipeline = $true)]
            [object] $sections,
            [parameter(Position = 4, Mandatory = $true, ValueFromPipeline = $true)]
            [object] $optionalHeaders   
       )


       $targetFramework = ""

       MoveTo -stream $stream -dataDirectory $dataDirectory -sections $sections

       if($binaryReader.ReadUInt32() -ne 0x424a5342) {
           Write-Error "BadImageFormat"
           exit 1
       }

       # 4 because of major/minor
       Advance -stream $stream -count 8

       # Read framework version
       $frameworkVersion = ReadZeroTerminatedString -binaryReader $binaryReader -length $binaryReader.ReadInt32()

       switch -Exact ($frameworkVersion[1]) {
            1 {
                if($frameworkVersion[3] -eq 0) { 
                    $targetFramework = "NET10" 
                } else { 
                    $targetFramework = "NET11"
                }
            }
            2 {
                $targetFramework = "NET20"
            }
            4 {
                if($optionalHeaders.SubSystemMinor -eq 0x6) {
                    $targetFramework = "NET45"
                } else {
                    $targetFramework = "NET40"
                }
            }
       }
        
       return $targetFramework
    }

    # Read assembly
    $stream = New-Object System.IO.FileStream($filename, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
    $reader = New-Object System.IO.BinaryReader($stream)
    $length = $stream.Length

    # Read PE format
    # ==============
    # The initial part here reads the PE format (not specific to .NET like cecil does)
    # because we are interested in determining generic PE metadata

    # Read pointer to PE header.
    $stream.Position = 0x3c
    $peHeaderPtr = $reader.ReadUInt32()
    if($peHeaderPtr -eq 0) {
        $peHeaderPtr = 0x80
    }

    # Ensure there is at least enough room for the following structures:
    #     24 byte PE Signature & Header
    #     28 byte Standard Fields         (24 bytes for PE32+)
    #    68 byte NT Fields               (88 bytes for PE32+)
    # >= 128 byte Data Dictionary Table
    if($peHeaderPtr > ($length - 256)) {
        Write-Error "Invalid PE header"
        exit 1
    }

    # Check the PE signature.  Should equal 'PE\0\0'.
    $stream.Position = $peHeaderPtr
    $peSignature = $reader.ReadUInt32()
    if ($peSignature -ne 0x00004550) {
        Write-Error "Invalid PE signature"
        exit 1
    }

    # Read PE header fields.
    $machine = $reader.ReadUInt16()
    $numberOfSections = $reader.ReadUInt16()

    Advance -stream $stream -count 14

    $characteristics = $reader.ReadUInt16()
    $peFormat = $reader.ReadUInt16()

    # Must be PE32 or PE32plus
    if ($peFormat -ne 0x10b -and $peFormat -ne 0x20b) {
        Write-Error "Invalid PE format. Must be either PE32 or PE32PLUS"
        exit 1
    }

    $optionalHeaders = ReadOptionalHeaders -binaryReader $reader -stream $stream -peFormat $peFormat
    if($optionalHeaders.CLIHeader.IsZero) {
        return AssemblyInfo -peFormat $peFormat -characteristics $characteristics -machine $machine
    }

    $sections = ReadSections -binaryReader $reader -stream $stream -count $numberOfSections

    $cliHeader = ReadCLIHeader -binaryReader $reader -stream $stream `
        -dataDirectory $optionalHeaders.CLIHeader -sections $sections

    $targetFramework = GetTargetFrameworkVersion -binaryReader $reader -stream $stream `
        -dataDirectory $cliHeader.Metadata -sections $sections -optionalHeaders $optionalHeaders

    $assemblyInfo = AssemblyInfo -peFormat $peFormat -attributes $cliHeader.Attributes -machine $machine -optionalHeaders $optionalHeaders `
            -characteristics $optionalHeaders.Characteristics -majorRuntimeVersion $cliHeader.MajorRuntimeVersion `
            -minorRuntimeVersion $cliHeader.MinorRuntimeVersion -targetFramework $targetFramework

    $reader.Dispose()
    $stream.Dispose()

    return $assemblyInfo
  
}

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
        [string]$packageVersion = ""
    )

    $semverRegex = "^([0-9]+)\.([0-9]+)\.([0-9]+)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+[0-9A-Za-z-]+)?$"

    $buildRunner = MyGet-BuildRunner
    if([String]::IsNullOrEmpty($buildRunner)) {
        if(-not ($packageVersion -match $semverRegex)) {
            Write-Error "Invalid package version input value"
        }
        return $packageVersion
    }

    $envPackageVersion = MyGet-EnvironmentVariable "PackageVersion"
    if([String]::IsNullOrEmpty($envPackageVersion)) {
        return $packageVersion
    }

    if(-not ($envPackageVersion -match $semverRegex)) {
        Write-Error "Invalid package version value recieved from BuildRunner"
    }

    return $envPackageVersion

}

function MyGet-CurlExe-Path {
    param(
        [ValidateSet("7.33.0", "latest")]
        [string] $version = "latest"
    )

    $curl = Join-Path $buildRunnerToolsFolder "tools\curl\$version\curl.exe"
    if (Test-Path $curl) {
        return $curl
    }

    MyGet-Die "Could not find curl executable: $curl"
}

function MyGet-NugetExe-Path {
    param(
        [ValidateSet("2.5", "2.6", "2.7", "latest")]
        [string] $version = "latest"
    )

    # Test environment variable
    if((MyGet-BuildRunner -eq "myget") -and (Test-Path env:nuget)) {
        return $env:nuget
    }

    $nuget = Join-Path $buildRunnerToolsFolder "tools\nuget\$version\nuget.exe"
    if (Test-Path $nuget) {
        return $nuget
    }

    MyGet-Die "Could not find nuget executable: $nuget"
}

function MyGet-NunitExe-Path {
    param(
        [ValidateSet("2.6.2", "2.6.3", "latest")]
        [string] $version = "latest"
    )

    $nunit = Join-Path $buildRunnerToolsFolder "tools\nunit\$version\nunit-console.exe"
    if (Test-Path $nunit) {
        return $nunit
    }
    MyGet-Die "Could not find nunit executable: $nunit"
}

function MyGet-XunitExe-Path {
    param(
        [ValidateSet("1.9.2", "latest")]
        [string] $version = "latest"
    )

    $xunit = Join-Path $buildRunnerToolsFolder "tools\xunit\$version\xunit.console.clr4.x86.exe"
    if (Test-Path $xunit) {
        return $xunit
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

function MyGet-Clr-To-TargetFramework {
    param(
        [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateSet("net20", "net35", "net40", "net45", "net451")]
        [string]$clr
    )

    $targetFramework = $null

    switch -Exact ($clr.ToLower()) {
        "net20" {
            $targetFramework = "v2.0"
        }
        "net35" {
            $targetFramework = "v3.5"
        } 
        "net40" {
            $targetFramework = "v4.0"
        }
        "net45" {
            $targetFramework = "v4.5"
        }
        "net451" {
            $targetFramework = "v4.5.1"
        }
    }

    return $targetFramework
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

    MyGet-Grep -folder $solutionFolder -recursive $true -pattern ".packages.config$" | ForEach-Object {
        . $nugetExe restore $_.FullName -NonInteractive -SolutionDirectory $solutionFolder
    }

}

function MyGet-Build-Nupkg {
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
        [string]$nugetProperties = $null,

        # http://docs.nuget.org/docs/reference/command-line-reference#Pack_Command
        [parameter(Position = 8, ValueFromPipeline = $true)]
        [string]$nugetPackOptions = $null,

        [parameter(Position = 9, ValueFromPipeline = $true)]
        [string]$nugetIncludeSymbols = $true

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
    
    if($nugetIncludeSymbols -eq $true) {
        . $nugetExe pack $nuspec -OutputDirectory $outputFolder -Symbols  -NonInteractive `
            -Properties "$nugetProperties" -Version $version "$nugetPackOptions"
    } else {
        . $nugetExe pack $nuspec -OutputDirectory $outputFolder -NonInteractive `
        -Properties "$nugetProperties" -Version $version "$nugetPackOptions"
    }
    
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
        
        [parameter(Position = 6, Mandatory = $false, ValueFromPipeline = $true)]
        [ValidateSet("v1.1", "v2.0", "v3.5", "v4.0", "v4.5", "v4.5.1")]
        [string[]]$targetFrameworks = @(),

        [parameter(Position = 7, Mandatory = $false, ValueFromPipeline = $true)]
        [ValidateSet("v1.1", "v2.0", "v3.5", "v4.0", "v4.5", "v4.5.1")]
        [string]$targetFramework = $null,

        [parameter(Position = 8, Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateSet("x86", "x64", "AnyCpu")]
        [string]$platform,

        [parameter(Position = 9, Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateSet("Quiet", "Minimal", "Normal", "Detailed", "Diagnostic")]
        [string]$verbosity = "Minimal",

        [parameter(Position = 10, ValueFromPipeline = $true)]
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

    if($targetFrameworks.Length -eq 0) {
        $targetFrameworks += $targetFramework
    }

    if($targetFrameworks.Length -eq 0) {
        MyGet-Die "Please provide a targetframework to build project for."
    }

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
        [string]$verbosity = "Minimal",
        
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
    # documentation: http://www.nunit.org/index.php?p=consoleCommandLine&r=2.6.3

    param(
        [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$rootFolder,
        [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$buildFolder,
        [parameter(Position = 1, Mandatory = $false, ValueFromPipeline = $true)]
        [string]$options = "/nologo",
        [parameter(Position = 2, Mandatory = $false, ValueFromPipeline = $true)]
        [string]$filter = "tests.*.dll$",
        [parameter(Position = 3, Mandatory = $false, ValueFromPipeline = $true)]
        [string]$minTargetFramework = "v2.0",
        [parameter(Position = 4, Mandatory = $false, ValueFromPipeline = $true)]
        [string]$version = "latest",
        [parameter(Position = 5, Mandatory = $false, ValueFromPipeline = $true)]
        [int16]$timeoutDuration = $([int16]::MaxValue)
    )

    $nunitExe = MyGet-NunitExe-Path
    $nunitExeX86 = Join-Path (Split-Path -Parent $nunitExe) "nunit-console-x86.exe"

    # Filter test projects that has a older runtime that this value
    $minTargetFramework = (MyGet-TargetFramework-To-Clr $minTargetFramework).Substring(3)

    # 4.5.1 -> 4.5
    if($minTargetFramework -eq "451") {
        $minTargetFramework = "45"
    }

    # AnyCpu, X64
    $net20 = @()
    $net40 = @()
    $net45 = @()

    # X86
    $net20X86 = @()
    $net40X86 = @()
    $net45X86 = @()

    # Find all test libraries based on specified filter
    Get-ChildItem $buildFolder -Recurse | Where-Object { $_.FullName -match $filter } | ForEach-Object {
        $fullPath = $_.FullName
        $assemblyInfo = MyGet-AssemblyInfo $fullPath
        # Only accept managed libraries
        if($assemblyInfo.ModuleAttributes -contains "ILOnly") {
            $targetFramework = $assemblyInfo.TargetFramework.Substring(3)
            if (-not ($targetFramework -ge $minTargetFramework)) {
                return
            }
            if($assemblyInfo.ProcessorArchitecture -eq "AnyCpu") {                
                if($targetFramework -eq "20") {
                    $net20X86 += $fullPath
                } elseif($targetFramework -eq "40") {
                    $net40X86 += $fullPath
                } else {
                    $net45X86 += $fullPath
                }
            } else {
                if($targetFramework -eq "20") {
                    $net20 += $fullPath
                } elseif($targetFramework -eq "40") {
                    $net40 += $fullPath
                } else {
                    $net45 += $fullPath
                }
            }            
        } else {
            Write-Output "Skipped test library $fullPath because it's not .NET assembly"
        }
      
    } 

    function TestSuite($nunit, $arguments) {
        
        $process = Start-Process -PassThru -NoNewWindow $nunit ($arguments | %{ "`"$_`"" })
        Wait-Process -InputObject $process -Timeout $timeoutDuration

        $exitCode = $process.ExitCode
        if($exitCode -ne 0) {
            MyGet-Die "Test suite failed" -exitCode $exitCode
        }

    }

    # AnyCpu, X64
    $minClrRuntime = $null
    if($net45 -ne 0) {
        $minClrRuntime = "net-4.5"
    } elseif($net40 -ne 0) {
        $minClrRuntime = "net-4.0"
    } elseif($net20 -ne 0) {
        $minClrRuntime = "net-2.0"
    }

    if($minClrRuntime -ne $null) {
         
        $arguments = @()
        $net20 | ForEach-Object { $arguments += $_ }
        $net40 | ForEach-Object { $arguments += $_ }
        $net45 | ForEach-Object { $arguments += $_ }

        $numProjects = $arguments.Length

        MyGet-Write-Diagnostic "nunit-console.exe: Running tests for $numProjects projects."   

        Write-Output ""
        Write-Output $arguments | Sort-Object -Property FullName
        Write-Output ""

        $xml = Join-Path $buildFolder "nunit-result.xml"
        $arguments += ($options -split " ")
        $arguments += "/framework=$minClrRuntime"
        $arguments += "/xml=$xml"

        TestSuite -nunit $nunitExe -arguments $arguments
    }

    # X86
    $minClrRuntimeX86 = $null
    if($net45X86 -ne 0) {
        $minClrRuntimeX86 = "net-4.5"
    } elseif($net40X86 -ne 0) {
        $minClrRuntimeX86 = "net-4.0"
    } elseif($net20X86 -ne 0) {
        $minClrRuntimeX86 = "net-2.0"
    }

    if($minClrRuntimeX86 -ne $null) {
         
        $arguments = @()
        $net20X86 | ForEach-Object { $arguments += $_ }
        $net40X86 | ForEach-Object { $arguments += $_ }
        $net45X86 | ForEach-Object { $arguments += $_ }

        $numProjects = $arguments.Length

        MyGet-Write-Diagnostic "nunit-console-x86.exe: Running tests for $numProjects projects."   

        Write-Output ""
        Write-Output $arguments | Sort-Object -Property FullName
        Write-Output ""

        $xml = Join-Path $buildFolder "nunit-result-x86.xml"
        $arguments += ($options -split " ")
        $arguments += "/framework=$minClrRuntimeX86"
        $arguments += "/xml=$xml"

        TestSuite -nunit $nunitExeX86 -arguments $arguments
    }

}

function MyGet-TestRunner-Xunit {
    param(
        [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$projects
    ) 
    
    # see: https://github.com/github/Shimmer/blob/bfda6f3e13ab962ad63d81c661d43208070593e8/script/Run-UnitTests.ps1#L5

    MyGet-Die "Not implemented. Please contribute a PR @ https://www.github/peters/myget"
}

# Squirrel

function MyGet-Squirrel-New-Release {
    param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$solutionFolder,
        [Parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$buildFolder
    )

    $packagesDir = Join-Path $solutionFolder "packages"
    
    $commandsPsm1 = MyGet-Grep -folder $packagesDir -recursive $true `
        -pattern "Shimmer.*commands.psm1$" | 
        Sort-Object FullName -Descending |
        Select-Object -first 1

    if(-not (Test-Path $commandsPsm1.FullName)) {
        MyGet-Die "Could not find any Squirrel nupkg's containing commands.psm1"
    }  
    
    MyGet-Write-Diagnostic "Squirrel: Creating new release"  

    Import-Module $commandsPsm1.FullName

    New-ReleaseForPackage -SolutionDir $solutionFolder -BuildDir $buildFolder

}

# Curl

function MyGet-Curl-Upload {
    # Example usage:

    # Curl-Upload -protocol scp -usernameAndHost "myusername@scp.example.org" -privateKey id_rsa -publicKey id_rsa.pub `
    # -filename myfilename.exe -remoteFilename /home/peters/myfilename.exe

    param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateSet("scp", "sftp")]
        [string]$protocol,
        [Parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$usernameAndHost,
        [Parameter(Position = 2, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$privateKey,
        [Parameter(Position = 3, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$publicKey,
        [Parameter(Position = 4, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$filename,
        [Parameter(Position = 5, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$remoteFilename
    )

    $curlExe = MyGet-CurlExe-Path

    # scp://username@scp.example.org:/home/peters/myfilename.exe
    $connectionString = $protocol
    $connectionString += "://"
    $connectionString += $usernameAndHost
    $connectionString += ":"
    $connectionString += $remoteFilename

   . $curlExe --insecure --progress-bar --upload-file $filename `
    --key $privateKey --pubkey $publicKey $connectionString

}

if(-not (Test-Path $buildRunnerToolsFolder)) {

    MyGet-Write-Diagnostic "Downloading prerequisites"

	git clone --depth=1 https://github.com/myget/BuildTools.git $buildRunnerToolsFolder

    $(Get-Item $buildRunnerToolsFolder).Attributes = "Hidden"

}
