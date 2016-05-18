<#
    .SYNOPSIS
    Moves all MD topics from a single location to their final destination, based on an input file.

    .DESCRIPTION
    Moves all MD topics from a single location to their final destination, based on an input file.

    .PARAMETER SourceFolder
    The full path for the topics folder

    .PARAMETER DestinationRootFolder
    The full path for the destination root folder

    .PARAMETER FileStructureData
    The full path to a file of a tab separated list of nodes and topic titles.

    .REMARKS
    Topics are moved on the best match effort from topic title to file name.
    The logic assumes that file name should be match for title words in teh same order
#>

## .INCLUDE
. "C:\GIT\juanpablo.jofre@bitbucket.org\powershell\PowerShell-Docs\DocumentManagement\Move-MDDocument.ps1"

function Move-MDDocuments(){
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true)] [string] $SourceFolder,
        [parameter(Mandatory=$true)] [string] $DestinationRootFolder,
        [parameter(Mandatory=$true)] [string] $FileStructureData
    )

    if(-not (Test-Path -Path $FileStructureData)){
        Write-Error "File does not exist: $FileStructureData"
        Return
    }

    if(-not (Test-Path -Path $SourceFolder)){
        Write-Error "Topics source folder does not exist: $SourceFolder"
        Return
    }

    if(-not (Test-Path -Path $DestinationRootFolder)){

        try
        {
            md $DestinationRootFolder
        }
        catch [System.IO.IOException]
        {
            Write-Error "Unable to create folder: $DestinationRootFolder"
            Return
        }
        catch
        {
            Write-Error "Destination root folder does not exist: $DestinationRootFolder"
            Write-Error "An error occurred that could not be resolved. $_"
            Return
        }
    }


    $TopicFolder = @{}
    Get-ChildItem -Path $SourceFolder -Filter "*.md" |`
        ForEach-Object { 
            $filename = $_.BaseName
            $fullpath = $_.FullName
            $TopicFolder.Add($filename,$fullpath)
        }


    $NodeTopicInfo = [System.IO.File]::ReadAllLines($FileStructureData)

    $NodeTopicInfo |`
    ForEach-Object {
        $info = $_.Split("`t")
        $node = $info[0]
        $topic = $info[1]
        if(-not [string]::IsNullOrWhiteSpace($topic)){
            Move-MDDocument -TopicFolder $TopicFolder -TopicNode $node -TopicTitle $topic -NodeRoot $DestinationRootFolder
        }
    }
}

