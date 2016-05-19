<#
    .SYNOPSIS
    Move markdown documents from topic source folder to defined destination.

    .DESCRIPTION
    Move markdown document from topic source to defined destination and update metadata.

    .PARAMETER TopicFolder
    The topic source folder.

    .PARAMETER NewMetadata
    A hastable paramater holding all metadata pairs to update the document.

    .PARAMETER Title
    <optional> The document's title; in case the file name isn't accurate enough
#>

function Move-MDDocument(){
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true)] [hashtable] $TopicFolder,
        [parameter(Mandatory=$true)] [string] $TopicTitle,
        [parameter(Mandatory=$true)] [string] $TopicNode,
        [parameter(Mandatory=$true)] [string] $NodeRoot
    )

    $topicCount = $TopicFolder.Count
    $timestamp = [DateTime]::Now.ToString("yyyy-MM-dd HHmmss")
    Write-Verbose "[$timestamp] Total topics: $topiccount. Moving document with title '$TopicTitle' to '$NodeRoot / $TopicNode'"

    $filenamePattern = ([System.Text.RegularExpressions.Regex]::Replace($TopicTitle,"[^A-Za-z0-9]",".")).ToLowerInvariant()
    $filenamePattern = ([System.Text.RegularExpressions.Regex]::Replace($filenamePattern,"\.+?","[^A-Za-z0-9]+?")).ToLowerInvariant()
    $filenamePattern = "^" + $filenamePattern + "$"

    $candidates = @()
    $TopicFolder.Keys |`        Where-Object { [System.Text.RegularExpressions.Regex]::IsMatch($_, $filenamePattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase) } |`
        ForEach-Object { $candidates += $_ }

    if($candidates.Length -ne 1){
        if($candidates.Length -eq 0){
            Write-Warning "No file found for: $TopicTitle"
        }
        else{
            Write-Warning "Multiple matched found for: $TopicTitle"
        }

        return
    }

    $destination = Join-Path -Path $NodeRoot -ChildPath $TopicNode
    if(-not $(Test-Path -Path $destination)){
        $TopicNode = $TopicNode.Replace("/", "\") 
        $nodeFolders = $TopicNode.Split("\") 
        $destination = $NodeRoot
        for([int]$i = 0; $i -lt $nodeFolders.Length; $i++){
            $destination = Join-Path -Path $destination -ChildPath $nodeFolders[$i]
            if(-not $(Test-Path -Path $destination)){
                try{
                    md $destination > $null
                }
                catch{
                    Write-Error "Could not create folder $destination. System exception: $_"
                }
            }
        }
    }

    $document = $TopicFolder[$candidates[0]]

    if(Test-Path -Path $document){
        Move-Item -Path $document -Destination $destination > $null
    }
    else{
        Write-Error "Duplicate request on '$TopicTitle' to move: $document"
    }
}