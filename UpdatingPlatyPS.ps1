## Required to find the right build tool
Set-Alias -Name msbuild  -Value C:\Windows\Microsoft.NET\Framework64\v4.0.30319\MSBuild.exe


## change location to repo folder
cd C:\git\platyPS

.\build.ps1

## Let's check we have loaded PlatPS command set
Get-Command -Module PLATYPS

## copy PlatyPS module to a location that will be loaded automatically
If (Test-Path "$home\Documents\WindowsPowerShell\Modules\platyPS"){
    Remove-Item -Path "$home\Documents\WindowsPowerShell\Modules\platyPS\*" -Recurse
}

Copy-Item -Path ".\out\platyPS" -Destination "$home\Documents\WindowsPowerShell\Modules" -Force -Recurse

