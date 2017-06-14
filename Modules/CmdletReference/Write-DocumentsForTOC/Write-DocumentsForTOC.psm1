function Write-DocumentsForTOC () {
    [CmdletBinding()]
    Param(
        [parameter (Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { Test-Path -LiteralPath $_ -PathType Container })] 
        [string]$RootFolder 
        , [parameter (Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$TocOutputFolder 
        , [parameter (Mandatory = $false)]
        [ValidateSet("UTF8BOM", "UTF8NOBOM", 
            "ASCII", "UTF7",
            "UTF16BigEndian", "UTF16LittleEndian", "Unicode",
            "UTF32BigEndian", "UTF32LittleEndian")]
        [string] $encode = "UTF8NOBOM"
    )

    BEGIN {
        [string[]]$ToCLines = @()
        $childrenFolders = @()
        [string[]]$toc = @()
    }

    END {
        $TocRootFolder = [System.IO.Path]::GetFullPath($RootFolder)
        [string]$foldername = [System.IO.Path]::GetFileName($TocRootFolder)
        [string]$roottopic = [string]::Empty
        if ([System.IO.File]::Exists([System.IO.Path]::Combine($TocRootFolder, "$foldername.md"))) {
            $roottopic = "$foldername.md"
        }        

        $ToCLines += "#  [$foldername]($roottopic)"

        ## Get Folders in ToC
        $toc += Get-ChildItem -Path $TocRootFolder -Recurse |
            Where-Object { $_.PSIsContainer -and ($_.FullName -notlike "*ignore*") } |
            Sort-Object -Property FullName |
            ForEach-Object { $_.FullName }


        ## Get MD documents in ToC
        $toc += Get-ChildItem -Path $TocRootFolder -Filter "*.md" -Recurse |
            Where-Object { ($_.FullName -notlike "*ignore*") -and ($_.Name -ne "toc.md")} | 
            Sort-Object -Property FullName |
            ForEach-Object { $_.FullName }

        ## Prepare Toc
        $ToC |
            Sort-Object |
            ForEach-Object { 
            [string]$fullName = $_
            [string]$relativePath = $fullName.Substring($TocRootFolder.Length)
            if ($relativePath.StartsWith("\")) {
                $relativePath = $relativePath.Substring(1)
            }

            [int]$levelDepth = $relativePath.Split("\").Length

            if ($levelDepth -le 3) {
                $header = [string]::new('#', ($levelDepth + 1))                

                $nameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($fullName)

                if ([System.IO.Directory]::Exists($fullName)) {
                    $nameWithoutExtension = [System.IO.Path]::GetFileName($fullName)

                    if ([System.IO.File]::Exists([System.IO.Path]::Combine($fullName, ($nameWithoutExtension + ".md")))) {
                        $relativePath = [System.IO.Path]::Combine($relativePath, ($nameWithoutExtension + ".md"))
                    }
                    elseif ([System.IO.File]::Exists([System.IO.Path]::Combine($fullName, "readme.md"))) {
                        $relativePath = [System.IO.Path]::Combine($relativePath, "readme.md")
                    }
                    else {
                        $relativePath = [string]::Empty
                    }
                }

                $relativePath = $relativePath.Replace("\", "/").ToLowerInvariant()

                $ToCLines += "$header  [$nameWithoutExtension]($relativePath)" 
            }
        }   

        If (-not [System.IO.Directory]::Exists($TocOutputFolder)) {
            [System.IO.Directory]::CreateDirectory($TocOutputFolder)
        }

        [System.IO.File]::WriteAllLines((Join-Path -Path $TocOutputFolder -ChildPath "ToC.md") , $ToCLines, (Get-EncodingFromLabel -encode $encode))        
    }
}
