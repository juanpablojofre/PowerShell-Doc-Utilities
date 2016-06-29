<#
    .SYNOPSIS
    Updates or creates the metadata sections, at the top of the document, for 
    SkyEye analytics.

    .DESCRIPTION
    Updates or creates the metadata sections, at the top of the document, for 
    SkyEye analytics.

    Existing metadata, not matched in new metadata, is preserved

    .PARAMETER mdDocumentsFolder
    The document's full path, with name and extension.

    .PARAMETER NewMetadata
    A hastable paramater holding all metadata pairs to update the document.

#>

function Update-MetadataInTopics()
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true)] [string] $mdDocumentsFolder,
        [parameter(Mandatory=$false)] [hashtable] $NewMetadata
    )


    if(-not $newMetadata){
        $newMetadata = @{
        "title" = "" 
        "description" = "" 
        "keywords" = "powershell,cmdlet" 
        "author" = "jpjofre" 
        "manager" = "dongill" 
        "ms.date" = [DateTime]::Now.ToString("yyyy-MM-dd")
        "ms.topic" = "article"
        "ms.prod" = "powershell"
        "ms.technology" = "powershell"
        }
    }

    Get-ChildItem -Path $mdDocumentsFolder -Filter "*.md" -Recurse |`
        Where-Object { 
            (-not $_.PSIsContainer) -and 
            ($_.FullName -notlike "*.ignore*") -and 
            ($_.FullName -ne "TOC.md") } |`
        ForEach-Object {             $title = $_.BaseName.Replace("-"," ")            Update-Metadata -DocumentPath $_.FullName -NewMetadata $newMetadata -Title $title        } 
}

