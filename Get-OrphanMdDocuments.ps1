<#

    .SYNOPSIS
        Find all documents that have no reference to themselves from other existing documents.

    .DESCRIPTION
        Find all documents that have no reference to themselves from other existing documents.
        All MD documents in given folder and  subfolders are verfied.

    .PARAMETER  DocumentsFolder
        The path to the folder (with subfulders) that contains all MD documents to validate.


    .OUTPUTS
        

    .EXAMPLE
        <script-repository>\Find-BrokenLinksInMDDocuments.ps1 "<repo-location>\scripting"
        
        
#>
[CmdletBinding()]
Param(
  [string]$DocumentsFolder = "C:\Git\PowerShell-Docs\scripting"
)

<#
    .NOTES
    -   Requires access to Get-Relativepath

    .TODO
    -   Add option exclude patterns
#>

. "C:\GIT\bitbucket.juanpablojofre\powershell\PowerShell-Docs\DocumentManagement\Get-Relativepath.ps1"
$initialWarningPreference = $WarningPreference
$initialErrorActionPreference = $ErrorActionPreference

$mdLinkPattern = "\[([^\[\]]+?)\]\(([^\(\)]+(\([^\(\)]+\))?[^\(\)]+?)\)"

$referenceFromDictionary = @{}
$linksToDictionary = @{}

$externalReferences = @{}

get-childitem -Path $documentsfolder -Filter "*.md" -recurse |`
    Where-Object { $_.Directory.FullName -notlike "*.ignore*" -and (-not $_.PSIsContainer) } |`
    ForEach-Object { $referenceFromDictionary.Add($_.FullName.ToLowerInvariant(), @{}); $_} |`
    Select-String $mdLinkPattern -AllMatches |`
    ForEach-Object { 
        $currentDocument = $_.Path.ToString().ToLowerInvariant()
        $currentFolder = [System.IO.Path]::GetDirectoryName($currentDocument)
        $_.Matches |`
            ForEach-Object { 
            $_.Captures |`
                Where-Object { (-not $_.Groups[2].value.StartsWith("http")) -and (-not $_.Groups[2].value.StartsWith("#"))  } |`
                ForEach-Object {
                    $currentLink = $_.Groups[2].value.ToLowerInvariant()

                    if(-not $linksToDictionary.ContainsKey($currentDocument)) { 
                        $linksToDictionary.Add($currentDocument, @{})
                    }


                    $resolvedLink = [System.IO.Path]::Combine($currentFolder, $currentLink)
                    $resolvedLink = [System.IO.Path]::GetFullPath($resolvedLink).ToLowerInvariant()

                    if([System.IO.File]::Exists($resolvedLink))
                    {
                        $linksToDictionary[$currentDocument][$resolvedLink] += 1
                    }
                } 
            } 
    }
    
$linksToDictionary.GetEnumerator() |`
    ForEach-Object { 
        $currentDocument = $_.Key
        $links = $_.Value

        $links.Keys |` 
            ForEach-Object {
                if($referenceFromDictionary.ContainsKey($_)){
                    $referenceFromDictionary[$_][$currentDocument]+=1
                }
                else{
                    if(-not $externalReferences.ContainsKey($_)){
                        $externalReferences.Add($_, @{})
                    }

                    $externalReferences[$_][$currentDocument] += 1
                }
            }
    }

<#
$linksToDictionary.GetEnumerator() |`
    ForEach-Object { 
        $source = $_.Key; 
        $linksto = $_.Value
        Write-Output "==========================================================="
        Write-Output "***     $source"
        Write-Output "   "
        $linksto.GetEnumerator() |`
            ForEach-Object { 
                $ref = $_.Key
                $count = $_.Value
                Write-Output "$ref --> $count" 
            }
        }
#>

$referenceFromDictionary.GetEnumerator() |`
    ForEach-Object { 
        $source = $_.Key; 
        $linksfrom = $_.Value
        if($linksfrom.Count -eq 0){
            Write-Output "$source"
        }
    }

