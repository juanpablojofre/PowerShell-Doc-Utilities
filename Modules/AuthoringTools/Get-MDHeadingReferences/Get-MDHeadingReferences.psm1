function Get-MDHeadingReferences(){
        [CmdletBinding(DefaultParameterSetName="Name")]
    Param(
        [parameter(Mandatory = $true, ValueFromPipeline=$true, ParameterSetName="Name" )] 
            [ValidateScript( { Test-Path -Path $_ -PathType Leaf })] 
            [string]$DocumentPath
        , [parameter(ValueFromPipeline=$false,ParameterSetName="Content")] 
            [ValidateNotNullOrEmpty()]
            [string] $Content
        , [ValidateSet("UTF8BOM", "UTF8NOBOM", 
            "ASCII", "UTF7",
            "UTF16BigEndian", "UTF16LittleEndian", "Unicode",
            "UTF32BigEndian", "UTF32LittleEndian")]
        [string] $encode = "UTF8NOBOM"
)

    BEGIN{
        [string]$HeadingPattern = '^#+\s+(?<heading>.+?)\s*$'
        [string]$HeadingText = [string]::Empty
        [string]$HeadingSuffix = [string]::Empty
        [string[]]$lines = @()
        $HeadingRegex = [System.Text.RegularExpressions.Regex]::new($HeadingPattern)
        $headings = @{}
        $references = @{}
        if(-not [string]::IsNullOrWhiteSpace($DocumentPath)){
            $lines = [System.IO.File]::ReadLines($DocumentPath, (Get-EncodingFromLabel -encode $encode))
        }
        else {
                $lines = $Content.Split([System.Environment]::NewLine)
        }
    }

    END{
        $lines.ForEach({
            $HeadingMatch = $HeadingRegex.Match($_)
            if ($HeadingMatch.Success) {
                $HeadingText = ($HeadingMatch.Groups['heading'].Value.Trim().ToLowerInvariant() -replace '[^a-z0-9 _-]','').Replace(' ','-')
                $headings[$HeadingText] += 1
                if($headings[$HeadingText] -gt 1){
                    $HeadingText = $HeadingText + "-" + ($headings[$HeadingText]-1)
                }

                $references[ $HeadingText ] += 1
            }
        })

        $references
    }
}