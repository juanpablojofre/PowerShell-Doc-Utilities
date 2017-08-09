<#
    .SYNOPSIS
        Find all documents that have no reference to themselves from other 
        existing documents.

    .DESCRIPTION
        Find all documents that have no reference to themselves from other 
        existing documents.
        All MD documents in given folder and  subfolders are verfied.

    .PARAMETER  DocumentsFolder
        The path to the folder (with subfulders) that contains all MD documents
        to validate.

    .OUTPUTS
        

    .EXAMPLE
        <script-repository>\Find-BrokenLinksInMDDocuments.ps1 "<repo-location>\scripting"
        
#>
function Get-OrphanMdDocuments () {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {Test-Path -Path $_ -PathType Container })]
        [string]$DocumentsFolder
        , [Parameter(Mandatory = $false)]
            [switch]$IncludeTOC
    )

    BEGIN {
        [string]$link
        [string]$text
        [string]$mdLinkPattern = "\[(?<text>[^\[\]]+?)\]\((?<link>[^\(\)]+(\([^\(\)]+\))?[^\(\)]+?)\)"

        $referenceFromDictionary = @{} ## the existing documents in the source folder
        $linksToDictionary = @{} ## The collection of links going out from document
        $externalReferences = @{}
    }

    END {
        get-childitem -Path $documentsfolder -Filter "*.md" -recurse |
            Where-Object { 
                (($_.Directory.FullName -notlike "*.ignore*") -and 
                (-not $_.PSIsContainer) -and 
                ($_.Name -ne "ToC.md")) -or
                ($IncludeTOC -and $Name -eq "ToC.md")
            } |
            ForEach-Object { $referenceFromDictionary.Add($_.FullName.ToLowerInvariant(), @{}); $_} |
            Select-String $mdLinkPattern -AllMatches |
            ForEach-Object { 
                    $currentDocument = $_.Path.ToString().ToLowerInvariant()
                    $currentFolder = [System.IO.Path]::GetFullPath([System.IO.Path]::GetDirectoryName($currentDocument))

                    if (-not $linksToDictionary.ContainsKey($currentDocument)) {
                        $linksToDictionary.Add($currentDocument, @{})
                    }

                    $_.Matches |
                        ForEach-Object {
                            $link = $_.Groups["link"].Value.ToLowerInvariant()
                            if((-not $link.StartsWith("http")) -and 
                                    (-not $link.StartsWith("#")))  {
                                $resolvedLink = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($currentFolder, $link))
                                $linksToDictionary[$currentDocument][$resolvedLink] += 1
                            } 
                        } 
            }


        $linksToDictionary.GetEnumerator() |
            ForEach-Object { 
                $currentDocument = $_.Key
                $links = $_.Value

                $links.Keys | ForEach-Object {
                    if ($referenceFromDictionary.ContainsKey($_)) {
                        $referenceFromDictionary[$_][$currentDocument] += 1
                    }
                    else {
                        if (-not $externalReferences.ContainsKey($_)) {
                            $externalReferences.Add($_, @{})
                        }

                        $externalReferences[$_][$currentDocument] += 1
                    }
                }
            }

        $referenceFromDictionary.GetEnumerator().ForEach({ 
            if($_.Value.Count -eq 0){ $_.Key }}) 
    }    
}


