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

    .PARAMETER MetadataTagsToRemove
    A list of paramaters to be removed from the existing metadata.

#>

function Update-MetadataInTopics()
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true)] 
            [ValidateScript( { Test-Path -LiteralPath $_ -PathType Container })] 
            [string] $mdDocumentsFolder
        , [parameter(Mandatory=$true)] 
            [hashtable] $NewMetadata
        , [parameter(Mandatory=$false)] 
            [string[]] $MetadataTagsToRemove
        , [ValidateSet("UTF8BOM", "UTF8NOBOM", 
            "ASCII", "UTF7",
            "UTF16BigEndian", "UTF16LittleEndian", "Unicode",
            "UTF32BigEndian", "UTF32LittleEndian")]
        [string] $encode = "UTF8NOBOM"
    )

    END {
        Get-ChildItem -Path $mdDocumentsFolder -Filter "*.md" -Recurse |
            Where-Object { 
                (-not $_.PSIsContainer) -and 
                ($_.FullName -notlike "*.ignore*") -and 
                ($_.Name -ne "TOC.md") } |        
            ForEach-Object { 
                $DocumentPath = $_.FullName
                Write-Progress $DocumentPath

                Update-Metadata -DocumentPath $DocumentPath -NewMetadata $NewMetadata -MetadataTagsToRemove $MetadataTagsToRemove -encode $encode
            } 
    }
}

