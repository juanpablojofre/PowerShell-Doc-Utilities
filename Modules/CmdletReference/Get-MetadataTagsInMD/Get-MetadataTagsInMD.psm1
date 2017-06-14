function Get-MetadataTagsInMD () {
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [ValidateScript( { Test-Path -LiteralPath $_ -PathType Leaf })] 
            [string] $DocumentPath
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

        # Regex options: case insensitive
        [System.Text.RegularExpressions.RegexOptions]$ciRgxOptions = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    }

    END {
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

        if ($beginBlock -eq -1 -or -not $endOfBlock) {
            Write-Warning "No metadata block found in $DocumentPath"
            @{}
            return
        }

        $oldMetadata
    }
}