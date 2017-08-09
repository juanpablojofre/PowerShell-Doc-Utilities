USING MODULE CommonClasses

function Get-MDReferencesFromDocument() {
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)] 
            [ValidateNotNullOrEmpty()]
            [ValidateScript({ Test-Path -Path $_ -PathType leaf } )]
            [string] $DocumentPath,
        [ValidateSet("UTF8BOM", "UTF8NOBOM", 
            "ASCII", "UTF7",
            "UTF16BigEndian", "UTF16LittleEndian", "Unicode",
            "UTF32BigEndian", "UTF32LittleEndian")]
            [string] $encode = "UTF8NOBOM"
    )

    BEGIN {
        [string]$mdLinkPattern = "\[(?<text>[^\[\]]+?)\]\((?<link>[^\(\)]*(\([^\(\)]+\))?[^\(\)]*?)\)"
        [int]$LineNumber = 0
    }

    PROCESS {
        Select-String -Pattern $mdLinkPattern -Path $DocumentPath -AllMatches |
            ForEach-Object {
                $LineNumber = $_.LineNumber
                $_.Matches |
                    ForEach-Object {
                        if($_.Groups["text"].Value -notmatch "^(int|long|string|char|bool|byte|double|decimal|single|array|xml|hashtable)$"){
                            [MDReference]::new(
                                $DocumentPath, 
                                $LineNumber, 
                                $_.Groups["text"].Value, 
                                $_.Groups["link"].Value, 
                                $_.Groups[0].Value, 
                                [MDReferenceStatus]::NotTested)
                        }
                    }
            }
    }
}