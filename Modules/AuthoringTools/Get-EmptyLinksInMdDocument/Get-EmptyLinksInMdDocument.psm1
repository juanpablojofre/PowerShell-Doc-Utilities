<#

    .SYNOPSIS
        Test all MD references and report empty ones in a [TAB] separated list.

    .DESCRIPTION
        The command checks all inline links to see if those links are empty

    .PARAMETER  Docspath
        The path to the document ot inspect for empty markdown links

    .PARAMETER  ResolveEmpty
        A switch to resolve empty links to documents under 'CommonRoot'.

    .PARAMETER  CommonRoot
        The path to the folder (with subfolders) that contains all MD documents 
        that make this document set.

    .PARAMETER  encode
        The encode used to read and write the document.

    .OUTPUTS
        

    .EXAMPLE
        
#>
function Get-EmptyLinksInMdDocument() {
    [CmdletBinding()]
    Param (
        [parameter(
            Mandatory=$true,
            ValueFromPipeline=$true
        )] 
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Path -Path $_ -PathType leaf } )]
        [string[]] $Docspath,
        [switch]$ResolveEmpty,
        [parameter(Mandatory=$false)] 
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Path -Path $_ -PathType Container } )]
        [string[]] $CommonRoot,
        [ValidateSet("UTF8BOM", "UTF8NOBOM", 
            "ASCII", "UTF7",
            "UTF16BigEndian", "UTF16LittleEndian", "Unicode",
            "UTF32BigEndian", "UTF32LittleEndian")]
        [string] $encode = "UTF8NOBOM"
        
    )

    BEGIN {
        [string]$mdEmptyLinkPattern = "\[([^\[\]]+?)\]\(\s*\)"
        $Topics = @{}

        if ($ResolveEmpty) {
            Get-ChildItem -Path $CommonRoot -Filter "*.md" -Recurse |
                ForEach-Object {
                    $topicpath = $_.FullName
                    $topicname = [system.io.path]::GetFileNameWithoutExtension($topicpath).ToLowerInvariant()
                    if(-not $Topics.ContainsKey($topicname)){
                        $Topics.Add($topicname,@())
                    }

                    $Topics[$topicname] += $topicpath
                }
        }
    }

    PROCESS {
        Select-String -Pattern $mdEmptyLinkPattern -AllMatches -Path $Docspath |
            ForEach-Object {
                $current = $_
                if ($ResolveEmpty) {
                    $documentpath = $_.Path
                    [System.Collections.Generic.Dictionary[string,string]]$fixes = [System.Collections.Generic.Dictionary[string,string]]::new()
                    $_.Matches |
                        ForEach-Object {
                            $match = $_.Groups[0].Value
                            $textreference = $_.Groups[1].Value
                            $referencefilename = $textreference.ToLowerInvariant().Replace(' ', '-')
                            if ($Topics[$referencefilename].Count -eq 1 ) {
                                $documentfolder = [System.IO.Path]::GetDirectoryName($documentpath)
                                $link = Get-RelativePath -Directory $documentfolder -FilePath ($Topics[$referencefilename][0])

                                Write-Progress "$match --> [$textreference]($link)"
                                $fixes[$match] = "[$textreference]($link)"
                            }
                        }

                    if($fixes.Count -gt 0){
                        Write-Verbose "Updating $documentpath"
                        [string]$content = [System.IO.File]::ReadAllText($documentpath, (Get-EncodingFromLabel -encode $encode))
                        $fixes.Keys.ForEach({$content = $content.Replace($_,$fixes[$_])})
                        [System.IO.File]::WriteAllText($documentpath, $content, (Get-EncodingFromLabel -encode $encode))
                    }
                }
                else {
                    $current
                }
            }
    }
}