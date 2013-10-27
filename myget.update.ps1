$rootFolder = Split-Path $MyInvocation.MyCommand.Path
$buildTools = Join-Path $rootFolder ".buildtools"
$mygetIncludePs1 = "myget.include.ps1"

. $rootFolder\$mygetIncludePs1

MyGet-Write-Diagnostic "Updating build tools"

Set-Location $buildTools
git pull origin master
Set-Location $rootFolder

MyGet-Write-Diagnostic "Updating $mygetIncludePs1"

Invoke-WebRequest "https://raw.github.com/peters/myget/master/$mygetIncludePs1" `
-OutFile $mygetIncludePs1 -Verbose
