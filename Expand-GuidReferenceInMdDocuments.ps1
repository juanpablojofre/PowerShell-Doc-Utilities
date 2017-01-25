<#

    .SYNOPSIS

    .DESCRIPTION

    .PARAMETER  DocumentsFolder
        The path to the folder (with subfolders) that contains all MD documents to process.

    .PARAMETER  BrokenLinkReportPrefix
        The file prefix for all reports.

    .PARAMETER  Recurse
        A switch to enable recursive folder search.

    .OUTPUTS
        

    .EXAMPLE
        
        
#>
function Expand-GuidReferenceInMdDocuments()
{
    [CmdletBinding()]
    Param(
      [string]$DocumentsFolder ,
      [switch]$Recurse
    )

    $guidReferencePattern = "\[([A-Za-z0-9_-]+)\]\(([0-9A-Za-z]{8}(-[0-9A-Za-z]{4}){3}-[0-9A-Za-z]{12})\)"

    Get-ChildItem -Path $documentsfolder -Filter "*.md" -recurse:$Recurse |
        Where-Object { $_.Directory.FullName -notlike "*.ignore*" -and (-not $_.PSIsContainer)} |
        ForEach-Object { 
            [string]$fileName = $_.FullName
            [string]$content = [System.IO.File]::ReadAllText($fileName)
            $match = [System.Text.RegularExpressions.Regex]::Match($content, $guidReferencePattern)
            while($match.Success){
                [string]$guidReference = $match.Groups[0].Value
                [string]$expandedGuid = $guidReference.Replace($match.Groups[2].Value, $match.Groups[1].Value + ".md")
                Write-Progress "[$fileName] $guidReference ==> $expandedGuid"
                $content = $content.Replace($guidReference, $expandedGuid)
                $match = [System.Text.RegularExpressions.Regex]::Match($content, $guidReferencePattern)
            } 

            [System.IO.File]::WriteAllText($fileName, $content)
        }        
}
