
function Update-Metadata()
{
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
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [ValidateScript( { Test-Path -LiteralPath $_ -PathType Leaf })] 
            [string] $DocumentPath
        ,[parameter(Mandatory=$true)] 
            [ValidateNotNullOrEmpty()]
            [hashtable] $NewMetadata 
        , [parameter(Mandatory=$false)] 
            [string[]] $MetadataTagsToRemove 
        , [ValidateSet("UTF8BOM", "UTF8NOBOM", 
            "ASCII", "UTF7",
            "UTF16BigEndian", "UTF16LittleEndian", "Unicode",
            "UTF32BigEndian", "UTF32LittleEndian")]
        [string] $encode = "UTF8NOBOM"
        
    )

    BEGIN {
        [string]$emptyLinePattern = '^\s*$'
        [string]$beginEndMatadataBlockPattern = '^---\s*$'
        [string]$metadataContentPattern ='^(?<tag>[^:]+):(?<value>.*)$'
        [string]$splitLineMetadataContentPattern = "^\s+-[^-].*$"

        [string]$currenTag = [string]::Empty

        # A place where to store the existing metadata in the document
        $oldMetadata = @{}

        # A hash set to store tags to remove
        $tagsToRemove = @{}

        # Regex options: case insensitive
        [System.Text.RegularExpressions.RegexOptions]$ciRgxOptions = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    }

    END {
        $MetadataTagsToRemove |
            ForEach-Object {
                $tagsToRemove[$_.Trim()] += 1
            }

        [string[]]$content = [System.IO.File]::ReadAllLines($DocumentPath);

        ## Skipping empty lines at the beginning of the file
        [int]$i = 0;
        [int]$totalLines = $content.Length
        while($i -lt $totalLines -and [Regex]::IsMatch($content[$i], $emptyLinePattern,$ciRgxOptions)){ $i++ }

        ## Checking for Metadata block
        [int]$beginBlock = -1
        [int]$endBlock = -1
        $endOfBlock = $false
        $incompleteMetadataBlock = $false

        $oldMetadata = @{}

        if([Regex]::IsMatch($content[$i], $beginEndMatadataBlockPattern,$ciRgxOptions)){
            $beginBlock = $i
            $i++

            do {
                # Current line matches Metadata pattern
                $metadataTagMatch = [Regex]::Match($content[$i], $metadataContentPattern,$ciRgxOptions)
                if($metadataTagMatch.Success) {
                    $lastlineempty = $false
                    [string]$currenTag = $metadataTagMatch.Groups["tag"]
                    [string]$value = $metadataTagMatch.Groups["value"].Value
                    $oldMetadata[$currenTag] = $value
                    $i++
                    continue
                }

                # Current line matches end of metadata block
                if([Regex]::IsMatch($content[$i], $beginEndMatadataBlockPattern,$ciRgxOptions)) {
                    $endOfBlock = $true
                    $endBlock = $i
                    $i++
                    continue
                }

                # Current line matches continuation --> append current line to current tag value
                $continuationLineMatch = [Regex]::Match($content[$i], $splitLineMetadataContentPattern,$ciRgxOptions)
                if(($continuationLineMatch.Success) -and -not $lastlineempty) {
                    $oldMetadata[$currenTag] = $oldMetadata[$currenTag] + [Environment]::NewLine + $continuationLineMatch.Groups["0"].Value
                    $i++
                    continue
                }

                # Current line matches empty line --> skip line
                if([Regex]::IsMatch($content[$i], $emptyMetadataContentPattern,$ciRgxOptions)) {
                    $lastlineempty = $true
                    $i++
                    continue
                }

                # Current line is an unknown pattern
                $incompleteMetadataBlock = $true
                Write-Warning "Incomplete Metadata in: $DocumentPath"
                break;
            } while(-not $endOfBlock)
        }

        ## Let's start new document
        $newContent = @()

        ## Reset top of file if incomplete block
        if($incompleteMetadataBlock){ 
            $i = $beginBlock 
        }
        else {
            $metadataBlock = @()
            $metadataBlock += "---"

            $newMetadata.GetEnumerator() |
                ForEach-Object { 
                    $metadataBlock += $_.Key + ":  " + $_.Value.Trim() 
                }

            $oldMetadata.GetEnumerator() |
                Where-Object { 
                    -not $newMetadata[$_.Key] -and 
                    -not $tagsToRemove[$_.Key] -and
                    -not [string]::IsNullOrWhiteSpace($_.Value) -and
                    -not (($_.Value.Trim()) -eq "na") -and 
                    -not (($_.Value.Trim()) -eq "n/a")} |
                ForEach-Object { 
                    $metadataBlock += $_.Key + ":  " + $_.Value.Trim() 
                }

            $metadataBlock += "---"
            $metadataBlock += ""

            ## skipping extra empty lines
            while($i -lt $totalLines -and [Regex]::IsMatch($content[$i], $emptyLinePattern,$ciRgxOptions)){ $i++ }            
        }

        $newContent += $metadataBlock
        $lastLine = $content.Length - 1
        $newContent += $content[$i..$lastLine]

        if(-not [string]::IsNullOrWhiteSpace($content[$lastLIne])) { $newContent += [String]::Empty }

        [System.IO.File]::WriteAllLines($DocumentPath, $newContent, (Get-EncodingFromLabel -encode $encode))
    }
}
