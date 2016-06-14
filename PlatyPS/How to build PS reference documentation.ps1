## Required to find the right build tool
Set-Alias -Name msbuild  -Value C:\Windows\Microsoft.NET\Framework64\v4.0.30319\MSBuild.exe


## before moving into PlatyPS, make sure repo is up-to-date
cd C:\git\platyPS

.\build.ps1

## Let's check we have loaded PlatPS command set
Get-Command -Module PLATYPS

## Optional
# Update-Help -Module <the module> -Force

## Generate MD from the dll and existing MAML
## - Use -WithMoulePage to generate landing page
## - Use -Version generate landing page for specific version
## - Use -FWLink to point to download of help location (Tarta knows the proper link)
## New-MarkdownHelp -Module storage -Path «maml folder» -OutputFolder C:\tmp\storage\md -WithModulePage -Locale "en-us" -HelpVersion "5.0.0.0" -FwLink "foo.microsoft.com"

## build MAML
New-ExternalHelp -MarkdownFolder "C:\tmp\storage\MD" -OutputPath "C:\tmp\storage\maml" 

## CAB the MAML
New-ExternalHelpCab -CmdletContentFolder "C:\tmp\storage\maml" -OutputPath "C:\tmp\storage\cab" -ModuleMdPageFullPath "C:\tmp\storage\MD\storage.md"

