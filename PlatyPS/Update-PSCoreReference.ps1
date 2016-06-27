## Install-Module platyPS -Scope CurrentUser -Force
Import-Module platyPS

. C:\GIT\juanpablo.jofre@bitbucket.org\powershell\PlatyPS\Generate-PSCoreNewMDsFromModuleMAML.ps1
foreach($version in @("v5.0")){
    [string]$source = "C:\tmp\psreferencemamls\" + $version
    [string]$destination = "C:\PSCoreReference\" + $version
    [string]$helpversion = $version.Substring(1)
    [string]$executionDate = [datetime]::Now.ToString(".yyyy-MM-dd HHmm")
    [string]$logfile = "C:\PSCoreReference\" + $version + $executionDate + ".log"
    [string]$errorfile = "C:\PSCoreReference\" + $version + $executionDate + ".errors.log"

    Generate-PSCoreNewMDsFromModuleMAML `
        -PSCoreMamlSourceFolder $source `
        -PSCoreMDDestinationFolder $destination `
        -HelpVersion $helpversion `
        -WithModulePage -Force -Verbose 1>$logfile 2>$errorfile
}