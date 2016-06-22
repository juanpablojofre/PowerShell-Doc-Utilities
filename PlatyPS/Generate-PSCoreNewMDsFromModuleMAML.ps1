<# 

#>
function Generate-PSCoreNewMDsFromModuleMAML()
{
    [CmdletBinding()]
    Param(
      [string]$PSCoreMamlSourceFolder ,
      [string]$PSCoreMDDestinationFolder,
      [string]$FwLink,
      [string]$HelpVersion,
      [string]$ModuleGuid,
      [switch]$WithModulePage,
      [switch]$Force
    )

    if([string]::IsNullOrWhiteSpace($FwLink)){
        $FwLink = "n/a"
    }

    if([string]::IsNullOrWhiteSpace($HelpVersion)){
        $HelpVersion = "0.0.0.0"
    }

    if([string]::IsNullOrWhiteSpace($ModuleGuid)){
        $ModuleGuid = [GUID]::Empty
    }

    if(-not [System.IO.Path]::IsPathRooted($PSCoreMamlSourceFolder)){
        Write-Warning "[Early function exit] PS Core MAML source folder is not a full or rooted path."
        return;
    }

    if(-not [System.IO.Path]::IsPathRooted($PSCoreMDDestinationFolder)){
        Write-Warning "[Early function exit] PS Core MD destination folder is not a full or rooted path."
        return;
    }


    if(-not [System.IO.Directory]::Exists($PSCoreMamlSourceFolder)){
        Write-Warning "[Early function exit] PS Core MAML source folder: $PSCoreMamlSourceFolder doesn't exit."
        return;
    }

    if(-not [System.IO.Directory]::Exists($PSCoreMDDestinationFolder)){
        if(-not $Force){
            Write-Warning "[Early function exit] PS Core MD destination folder: $PSCoreMDDestinationFolder doesn't exit. -Force not requested."
            return;
        }

        [string]$destinationPath = [string]::Empty
        try{
            $destinationPath = [System.IO.Path]::GetPathRoot($PSCoreMDDestinationFolder)
            [string[]]$destinationFoldersFromRoot = [System.IO.Path]::GetFullPath($PSCoreMDDestinationFolder).SubString([System.IO.Path]::GetPathRoot($PSCoreMDDestinationFolder).Length).Split([System.IO.Path]::DirectorySeparatorChar)
            foreach($folder in $destinationFoldersFromRoot){
                $destinationPath = Join-Path -Path $destinationPath -ChildPath $folder
                if(-not [System.IO.Directory]::Exists($destinationPath)){
                    new-item -itemtype directory -Path $destinationPath  
                }
            }            
        }
        catch{
            Write-Error "Unable to create requested destination folder: $destinationPath"
            Write-Error $_.Exception.Message
            Write-Error $_.Exception.HResult
            Write-Error $_.Exception.TargetSite
            return;
        }
    }


    $mamlfiles = Get-ChildItem -Path $PSCoreMamlSourceFolder -Filter "PSITPro*.xml" -Recurse |`
        Where-Object { -not $_.PSIsContainer } |`
        ForEach-Object { $_.FullName }

    [int]$i = 1 
    $mamlfiles | ForEach-Object { Write-Verbose "[$i] $_"; $i++; }

    $mamlfiles |`
        ForEach-Object {
            [string]$mamlfile = $_
            $folder = [System.IO.Path]::GetDirectoryName($mamlfile).SubString($PSCoreMamlSourceFolder.Length+1)
            $folder = [System.IO.Path]::GetDirectoryName($folder)
            $module = $folder

            [string]$OutputFolder = [string]::Empty
            try{
                $OutputFolder =  Join-Path -Path $PSCoreMDDestinationFolder -ChildPath $module
                if(-not $(Test-Path -Path $OutputFolder)){
                    New-Item $OutputFolder -ItemType Directory
                }
            }
            catch{
                Write-Error "Unable to create requested destination folder: $OutputFolder"
                Write-Error $_.Exception.Message
                Write-Error $_.Exception.HResult
                Write-Error $_.Exception.TargetSite
                return;
            }


            Write-Verbose "Starting to create new markdown files for:"
            Write-Verbose "    Module     : $module"
            Write-Verbose "    Source     : $mamlfile"
            Write-Verbose "    Destination: $OutputFolder"

            try{
                New-MarkdownHelp -MamlFile $mamlfile `
                    -OutputFolder $OutputFolder `
                    -ModuleName $module `
                    -FwLink $FwLink `
                    -HelpVersion $HelpVersion `
                    -ModuleGuid $ModuleGuid `
                    -WithModulePage:$WithModulePage `
                    -ConvertNotesToList -ConvertDoubleDashLists -Force
            }
            catch{
                $errmsg =  "Unable to create new markdown files for:`n`r" + `
                            "    Module     : $module `n`r" + `
                            "    Source     : $mamlfile `n`r" + `
                            "    Destination: $OutputFolder `n`r" + `
                            $_.Exception.Message + "`n`r" + `
                            $_.Exception.HResult + "`n`r" + `
                            $_.Exception.TargetSite
                Write-Error $errmsg;
            }

            try{
                Set-Location $OutputFolder
                if($module -notlike "Microsoft.PowerShell.Core"){
                    Import-Module $module
                }

                Update-MarkdownHelp  -Path $OutputFolder 
                Update-MarkdownHelpModule -Path $OutputFolder 
            }
            catch{
                $errmsg =  "Unable to update markdown files for:`n`r" + `
                            "    Module     : $module `n`r" + `
                            "    Source     : $mamlfile `n`r" + `
                            "    Destination: $OutputFolder `n`r" + `
                            $_.Exception.Message + "`n`r" + `
                            $_.Exception.HResult + "`n`r" + `
                            $_.Exception.TargetSite
                Write-Error $errmsg;
            }
            
        }
}