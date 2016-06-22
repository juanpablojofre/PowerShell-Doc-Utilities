﻿<#
    .SYNOPSIS
    Updates or creates the metadata section, at the top of the document, for 
    SkyEye analytics.

    .DESCRIPTION
    Updates or creates the metadata section, at the top of the document, for 
    SkyEye analytics.

    Existing metadata, not matched in new metadata, is kept

    .PARAMETER DocumentPath
    The document's full path, with name and extension.

    .PARAMETER NewMetadata
    A hastable paramater holding all metadata pairs to update the document.

    .PARAMETER Title
    <optional> The document's title; in case the file name isn't accurate enough

#>

function Update-Metadata()
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true,ValueFromPipeline=$true)] [string[]] $DocumentPath,
        [parameter(Mandatory=$true)] [hashtable] $NewMetadata,
        [parameter()] [string] $Title
    )

    $emptyLinePattern = '^\s*$'
    $beginEndMatadataBlockPattern = '^---\s*$'
    $metadataContentPattern ='^[A-Za-z._]+\s*:\s.*$'
    $emptyMetadataContentPattern ='^[A-Za-z._]+\s*:\s*$'
    $splitLineMetadataContentPattern = "^\s*-\s+.+$"

    # A place where to store the existing metadata in the document
    $oldMetadata = @{}
    else{
        Write-Error "Document '$DocumentPath' does not exist!"
    }
}