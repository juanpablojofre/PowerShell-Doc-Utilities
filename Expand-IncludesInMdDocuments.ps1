<#

    .SYNOPSIS
        Replaces all 'INCLUDE' references with with the content value.

    .DESCRIPTION
        The command replaces all INCLUDE references, in all MD documents (recursively),
        with the content value.

    .PARAMETER  documentsfolder
        The path to the folder (with subfolders) that contains all MD documents to review and replace for tokens.

    .OUTPUTS
        A list of INCLUDE references that are broken; in a list of [TAB] separated values, in the form of: 
            <occurrence>'t<document-path>`t<token>`t<broken-reference>

    .EXAMPLE
        <script-repository>\FindReplace-TokensInMdDocuments.ps1 "<repo-location>\scripting"


        
        
#>
[CmdletBinding()]
Param(
  [string]$documentsfolder = "C:\tmp\WindowsServerDocs"
)

$tokensFound  = @()
$iteration = 1

do {
    $tokensFound  = get-childitem -Path $documentsfolder -Filter "*.md" -recurse |`
        Select-String "\[!INCLUDE\s*\[.+?\]\s*\((?<link>.+?)\)\]" -AllMatches |`
        ForEach-Object { 
            $document=($_.Path);
            $_.matches |`
                ForEach-Object {
                    $link =  $_.groups[0].value;
                    $documentFolder = [System.IO.Path]::GetDirectoryName($document);
                    $relativePath = $_.groups["link"].value.Replace("/","\")
                    $includeFile = Join-Path -Path $documentFolder -ChildPath $relativePath
                    @{
                        Document=$document; 
                        IncludeField=$link; 
                        IncludeFile = $includeFile 
                    }
                }
            } |`
        where-object { (Test-Path $_["IncludeFile"]) } |`
        ForEach-Object { 
            $includeContent = get-content -Path ($_["IncludeFile"]);  
            $include = ($_["IncludeField"]);
            $document = ($_["Document"]);
            $content = [System.IO.File]::ReadAllLines($document) 
            $newcontent = $content | ForEach-Object { $_.Replace($include,$includeContent) }
            [System.IO.File]::WriteAllLines($document,$newcontent)
            $_
        }
} while ( $tokensFound.Length -gt 0)


$brokenTokens = get-childitem -Path $documentsfolder -Filter "*.md" -recurse |`
    Select-String "\[!INCLUDE\s*\[.+?\]\s*\((.+?)\)\]" -AllMatches |`
    ForEach-Object { 
        $document=($_.Path);
        $_.matches | % { @{document=$document; token=$_.groups[0].value; tokenFile = $(Join-Path -Path $(([System.IO.Path]::GetDirectoryName($document))) -ChildPath $($_.groups[1].value)) }}} 

$brokenTokenCount = 0
$brokenTokens | % { ++$brokenTokenCount; write-output $("[{0,6:N0}]`t{1,-40}`t{2,-20}`t{3}" -f $brokenTokenCount, $_["document"], $_["token"], $_["tokenFile"] )}
