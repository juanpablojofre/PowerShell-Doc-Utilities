<# 

#>
function Generate-PSCoreNewMDsFromMAML()
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
            $module = [System.IO.Path]::GetDirectoryName($mamlfile).SubString($PSCoreMamlSourceFolder.Length+1)
            $module = [System.IO.Path]::GetDirectoryName($module)
            Write-Verbose "... working on module: $module"

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
                New-MarkdownHelp -Force -MamlFile $mamlfile -OutputFolder $OutputFolder -ModuleName $module -FwLink $FwLink -HelpVersion $HelpVersion -ModuleGuid $ModuleGuid -WithModulePage:$WithModulePage 
            }
            catch{
                Write-Error "Unable to create new markdown files for:"
                Write-Error "    Module     : $module"
                Write-Error "    Source     : $mamlfile"
                Write-Error "    Destination: $OutputFolder"
                Write-Error $_.Exception.Message
                Write-Error $_.Exception.HResult
                Write-Error $_.Exception.TargetSite
                return;
            }
        }
}