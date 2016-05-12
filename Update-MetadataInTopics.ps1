$mdDocumentsFolder = "C:\GIT\PowerShell-Docs\scripting"

$emptyLinePattern = '^\s*$'
$beginEndMatadataBlockPattern = '^---\s*$'
$metadataContentPattern ='^[A-Za-z._]+\s*:[^:]*$'

$newMetadata = @{
"title" = "" 
"description" = "" 
"keywords" = "powershell,cmdlet" 
"author" = "jpjofre" 
"manager" = "dongill" 
"ms.date" = [DateTime]::Now.ToString("yyyy-MM-dd")
"ms.topic" = "article"
"ms.prod" = "powershell"
}

$oldMetadata = @{}
Get-ChildItem -Path $mdDocumentsFolder -Filter "*.md" -Recurse |`
    Where-Object { 
        (-not $_.PSIsContainer) -and 
        ($_.FullName -notlike "*.ignore*") -and 
        ($_.FullName -ne "TOC.md") } |`
    ForEach-Object {         $currentDocument = $_.FullName        $newMetadata["title"] = $_.BaseName.Replace("-"," ")        $content = [System.IO.File]::ReadAllLines($currentDocument); ##::ReadAllText( $currentDocument );         ## Skipping empty lines at the beginning of the file        [int]$i = 0;        while([Regex]::IsMatch($content[$i], $emptyLinePattern)){ $i++ }        ## Checking for Metadata block        [int]$beginBlock = -1        [int]$endBlock = -1        $endOfBlock = $false        $incompleteMetadataBlock = $false        $oldMetadata = @{}        if([Regex]::IsMatch($content[$i], $beginEndMatadataBlockPattern)){            $beginBlock = $i            $i++            while(-not $endOfBlock){                while([Regex]::IsMatch($content[$i], $metadataContentPattern)){                    $pvp = $content[$i].Split(":")                    [string]$property = $pvp[0].Trim().ToLowerInvariant()                    [string]$value = $pvp[1].Trim()                    if(($value -ne "na") -and (-not [string]::IsNullOrWhiteSpace($value))) {                        $oldMetadata[$property] = $value                    }                    $i++                 }                if([Regex]::IsMatch($content[$i], $emptyLinePattern)){                    $i++                    continue                }                if([Regex]::IsMatch($content[$i], $beginEndMatadataBlockPattern)){                    $endOfBlock = $true                    $endBlock = $i                    $i++                    continue                }                $incompleteMetadataBlock = $true                break;            }        }        ## Reset top of file if incomplete block        if($incompleteMetadataBlock){             $i = $beginBlock         }        $metadataBlock = @()        $metadataBlock += "---"        $newMetadata.GetEnumerator() |`            ForEach-Object { $metadataBlock += $_.Key + ":  " + $_.Value }        if(-not $incompleteMetadataBlock){             $oldMetadata.GetEnumerator() |`                Where-Object { -not $newMetadata.ContainsKey($_.Key) } |`                ForEach-Object { $metadataBlock += $_.Key + ":  " + $_.Value }        }        $metadataBlock += "---"        $metadataBlock += ""        $newContent = @()        $newContent += $metadataBlock        $lastLine = $content.Length - 1        $i..$lastLine | ForEach-Object { $newContent += $content[$_] }        if(-not [string]::IsNullOrWhiteSpace($content[$lastLIne])) { $newContent += [String]::Empty }        [System.IO.File]::WriteAllLines($currentDocument, $newContent)    } 