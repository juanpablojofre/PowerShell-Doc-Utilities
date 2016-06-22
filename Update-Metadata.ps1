<#
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
    $oldMetadata = @{}    if([System.IO.File]::Exists($DocumentPath)){        $content = [System.IO.File]::ReadAllLines($DocumentPath);        if($Title){            $newMetadata["title"] = $Title        }        else{            $newMetadata["title"] = [System.IO.Path]::GetFileNameWithoutExtension($DocumentPath).Replace("-"," ")        }        ## Skipping empty lines at the beginning of the file        [int]$i = 0;        while([Regex]::IsMatch($content[$i], $emptyLinePattern)){ $i++ }        ## Checking for Metadata block        [int]$beginBlock = -1        [int]$endBlock = -1        $endOfBlock = $false        $incompleteMetadataBlock = $false        $oldMetadata = @{}        if([Regex]::IsMatch($content[$i], $beginEndMatadataBlockPattern)){            $beginBlock = $i            $i++            while(-not $endOfBlock){                [bool]$isMetadataPatternMatch = [Regex]::IsMatch($content[$i], $metadataContentPattern)                [bool]$isEmptyMetadataPatternMatch = [Regex]::IsMatch($content[$i], $emptyMetadataContentPattern)                                 while($isMetadataPatternMatch -or $isEmptyMetadataPatternMatch){                    [string]$line = $content[$i]                    if($isEmptyMetadataPatternMatch){                        [int]$next = $i + 1                        if([Regex]::IsMatch($content[$next], $splitLineMetadataContentPattern)){                            $splitLine = $content[$next].Split("-")                            $line = $content[$i] + $splitLine[1]                            $i = $next                        }                    }                    [string[]]$pvp = @()                    $pvp = $line.Split(":")                    [string]$property = $pvp[0].Trim().ToLowerInvariant()                    [string]$value = $pvp[1].Trim()                    if($pvp.Length -gt 2){                        $value = $content[$i].Substring($content[$i].IndexOf(":") + 2).Trim()                    }                    if(($value -ne "na") -and (-not [string]::IsNullOrWhiteSpace($value))) {                        $oldMetadata[$property] = $value                    }                    $i++                     $isMetadataPatternMatch = [Regex]::IsMatch($content[$i], $metadataContentPattern)                    $isEmptyMetadataPatternMatch = [Regex]::IsMatch($content[$i], $emptyMetadataContentPattern)                }                if([Regex]::IsMatch($content[$i], $emptyLinePattern)){                    $i++                    continue                }                if([Regex]::IsMatch($content[$i], $beginEndMatadataBlockPattern)){                    $endOfBlock = $true                    $endBlock = $i                    $i++                    continue                }                $incompleteMetadataBlock = $true                Write-Warning "Incomplete Metadata in: $DocumentPath"                break;            }        }        ## Reset top of file if incomplete block        if($incompleteMetadataBlock){             $i = $beginBlock         }        $metadataBlock = @()        $metadataBlock += "---"        $newMetadata.GetEnumerator() |`            ForEach-Object { $metadataBlock += $_.Key + ":  " + $_.Value }        if(-not $incompleteMetadataBlock){             $oldMetadata.GetEnumerator() |`                Where-Object { -not $newMetadata.ContainsKey($_.Key) } |`                ForEach-Object { $metadataBlock += $_.Key + ":  " + $_.Value }        }        $metadataBlock += "---"        $metadataBlock += ""        $newContent = @()        $newContent += $metadataBlock        $lastLine = $content.Length - 1        $i..$lastLine | ForEach-Object { $newContent += $content[$_] }        if(-not [string]::IsNullOrWhiteSpace($content[$lastLIne])) { $newContent += [String]::Empty }        [System.IO.File]::WriteAllLines($DocumentPath, $newContent)    }
    else{
        Write-Error "Document '$DocumentPath' does not exist!"
    }
}
