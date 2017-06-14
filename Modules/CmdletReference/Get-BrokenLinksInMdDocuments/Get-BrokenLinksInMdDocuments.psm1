<#

    .SYNOPSIS
        Test all MD references and report broken ones in a [TAB] separated list.

    .DESCRIPTION
        The command checks all inline links to see if those links
        have a valid reference. All MD documents in given folder and
        subfolders are verfied.

        References are checked for: 
        -   local files 
        -   URIs. 

    .PARAMETER  DocumentsFolder
        The path to the folder (with subfulders) that contains all MD documents to validate.

    .PARAMETER  BrokenLinkReportPrefix
        The file prefix for all reports.

    .PARAMETER  fixBrokenLinks
        A switch to enable fixing broken links.

    .OUTPUTS
        

    .EXAMPLE
        <script-repository>\Find-BrokenLinksInMDDocuments.ps1 "<repo-location>\scripting"
        
        
#>
function Get-BrokenLinksInMdDocuments() {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory = $true)] 
        [ValidateScript( { Test-Path -LiteralPath $_ -PathType Container })] 
        [string]$DocumentsFolder,
        [parameter(Mandatory = $true)] 
        [ValidateNotNullOrEmpty()]
        [string]$BrokenLinkReportPrefix,
        [parameter(Mandatory = $false)] 
        [switch]$fixBrokenLinks,
        [parameter(Mandatory = $false)] 
        [string]$staticRoot
    )

    BEGIN {
        [string]$initialWarningPreference = $WarningPreference
        [string]$initialErrorActionPreference = $ErrorActionPreference
        [string]$mdLinkPattern = "\[([^\[\]]+?)\]\(([^\(\)]+(\([^\(\)]+\))?[^\(\)]+?)\)"
        $linksDictionary = @{}
        $uniqueLinksDictionary = @{}
        $brokenlinks = @() ## an array of hashtable items
    }

    END {
        ## Generate dictionary of assets
        Get-ChildItem -Path $documentsfolder -recurse |
            Where-Object { $_.Directory.FullName -notlike "*.ignore*" -and (-not $_.PSIsContainer)} |
            ForEach-Object { 
            $name = $_.Name.ToLowerInvariant();
            if (-not $linksDictionary.ContainsKey($name)) {
                $linksDictionary.Add($name, @())
            }

            $linksDictionary[$name] += $_.FullName.ToLowerInvariant()
        }

        [int]$assetCount = $linksDictionary.Count
        [int]$assetReferenceCount = 0

        $linksDictionary.Values | 
            ForEach-Object { 
            $assetReferenceCount += $_.Length 
        }

        [double]$duplicateNameRatio = [double]$assetReferenceCount / [double]$assetCount

        Write-Verbose "Assets: $assetCount, duplicated names ratio (1.0 means no duplicates): $duplicateNameRatio"

        $linkreferences = get-childitem -Path $documentsfolder -Filter "*.md" -recurse |
            Where-Object { $_.Directory.FullName -notlike "*.ignore*" } |
            Select-String -Pattern $mdLinkPattern -AllMatches |
            ForEach-Object { 
            $currentPath = $_.Path;
            $currentLineNumber = $_.linenumber 
            $_.Matches |
                ForEach-Object { 
                $match = $_.Groups[0].value
                $reference = $_.Groups[1].value
                $link = $_.Groups[2].value
                $nestedParentheses = [string]::Empty
                if ($_.Groups.Length -eq 4) {
                    $nestedParentheses = $_.Groups[3].value
                }

                if (-not ( $reference -eq "int" -or 
                        $reference -eq "long" -or 
                        $reference -eq "string" -or 
                        $reference -eq "char" -or 
                        $reference -eq "bool" -or 
                        $reference -eq "byte" -or 
                        $reference -eq "double" -or 
                        $reference -eq "decimal" -or 
                        $reference -eq "single" -or 
                        $reference -eq "array" -or 
                        $reference -eq "xml" -or 
                        $reference -eq "hashtable" )) {
                    @{
                        match             = $match;
                        reference         = $reference;
                        link              = $link;
                        path              = $currentPath;
                        linenumber        = $currentLineNumber;
                        nestedParentheses = $nestedParentheses 
                    } 
                }
            }
        }

        $linksDictionary.GetEnumerator() |
            Where-Object { $_.Value.Length -eq 1} |
            ForEach-Object { $uniqueLinksDictionary.Add($_.Key, $_.Value[0]) }

        [int]$linkreferencesCount = $linkreferences.Count
        [int]$uniqueLinksDictionaryCount = $uniqueLinksDictionary.Count

        Write-Verbose "Linked references: $linkreferencesCount"
        Write-Verbose "Unique links: $uniqueLinksDictionaryCount"

        $referencesProcessed = 0;
        foreach ( $lr in $linkreferences) {
            ## Report progress 
            $referencesProcessed++
            
            $msg = "Processing reference {0,5} of {1,6} total. broken links found {2,5} --> [{3} | {4}]" -f $referencesProcessed, $linkreferences.count, $brokenlinks.count, ($lr["path"]), ($lr["link"]); 
            write-progress $msg

            ## Split on internal anchor
            $linksplit = $lr["link"] -split "#"; 

            if ((-not $linksplit[0]) -and ($linksplit.count -eq 2) ) {
                ## Checking in-doc reference or bookmarks 
                $anchor = $linksplit[1]
                $anchorPatternMatch = "<a\s+name=`"$anchor`"\s*(>.*<)*/a>"
                $anchorfound = Get-Content -Path $lr["path"] | Select-String $anchorPatternMatch -AllMatches
                if ( ! $anchorfound) {
                    $brokenlinks += $lr;
                }

                continue;
            }

            ## Test if Web URI
            [string]$testUri = $lr["link"].ToString()
            if ($testUri.ToLowerInvariant().StartsWith("http")) {
                ## Reset escaped characters
                $testUri = Get-UnEscapedText $testUri
                $testUri = [System.Net.WebUtility]::HtmlDecode($testUri)

                $r = $null;
                try {
                    $WarningPreference = 'SilentlyContinue'
                    $ErrorActionPreference = 'SilentlyContinue'
                    ($r = Invoke-WebRequest -URI $testUri -MaximumRedirection 5 -WarningAction SilentlyContinue  -ErrorAction SilentlyContinue -errorvariable ignoreerror) 2>$null 1>$null
                } catch {
                    ## Do nothing => SilentlyContinue
                } finally {
                    $WarningPreference = $initialWarningPreference
                    $ErrorActionPreference = $initialErrorActionPreference
                }

                if (($r.StatusCode -ge 200) -and ($r.StatusCode -le 299)) { 
                    continue 
                }
                elseif (($r.StatusCode -ge 300) -and ($r.StatusCode -le 399)) { 
                    ## Redirections in excess of -MaximumRedirection are logged out and treated as a broken link
                    $document = $lr["path"]
                    $redirmsg = $("Redirection found, code# " + $($r.StatusCode) + " for $testUri in $document")
                    Write-Warning $redirmsg
                }

                $brokenlinks += $lr;
                continue;
            }

            ## Test to see if it is pointing to a local file
            $documentFolder = [System.IO.Path]::GetDirectoryName($lr["path"])
            $currentPath = $linksplit[0].Replace("/", "\")
            $currentPath = Join-Path -Path $documentFolder -ChildPath $currentPath

            try {
                $WarningPreference = 'SilentlyContinue'
                $ErrorActionPreference = 'SilentlyContinue'

                if ( Test-Path $currentPath) {
                    ## Check if it carries an internal reference or bookmark
                    if ($linksplit.count -eq 2) {
                        $anchor = $linksplit[1]
                        $anchorPatternMatch = "<a\s+name=`"$anchor`"\s*(>.*<)*/a>"
                        $anchorfound = Get-Content -Path $currentPath | Select-String $anchorPatternMatch 
                        if ( ! $anchorfound) {
                            $brokenlinks += $lr;
                        }
                    } 

                    continue;
                }
            } catch {
                ## Do nothing => SilentlyContinue
                Write-Verbose $_
                Write-Verbose "Current path: $currentPath"
            } finally {
                $WarningPreference = $initialWarningPreference
                $ErrorActionPreference = $initialErrorActionPreference
            }

            $brokenlinks += $lr;
        }

        $msg = "Processed reference {0,5} of {1,6} total. Broken links found {2,5} " -f $referencesProcessed, $linkreferences.count, $brokenlinks.count; 
        Write-Verbose $msg

        $documentBrokenLinks = @{}

        $brokenLinksReport = @()
        $brokenlinks | 
            ForEach-Object { 
            $documentDirectory = [System.IO.Path]::GetDirectoryName($_["path"])
            [string]$currentLink = $_["link"]
            $isUniqueName = $false
            [string]$uniqueName = ""
            [string]$relativePath = ""

            [string]$nameInBrokenLink = ""
            if (-not ($currentLink.StartsWith("#") -or $currentLink.ToLowerInvariant().StartsWith("http"))) {
                $isUniqueName = $false
                try {
                    $cleanLink = (($currentLink).Split("#"))[0]
                    $nameInBrokenLink = ([System.IO.Path]::GetFileName($cleanLink)); 
                    $isUniqueName = $uniqueLinksDictionary.ContainsKey( $nameInBrokenLink )
                } catch {
                    Write-Warning "Error was $_"
                    Write-Warning "Current link: $currentLink"
                    Write-Warning "Clean link  : $cleanLink"
                    $line = $_.InvocationInfo.ScriptLineNumber
                    Write-Warning "Error was in Line $line"
                }
                
                if ($isUniqueName) {
                    $uniqueName = $uniqueLinksDictionary[$nameInBrokenLink]
                    if (-not [string]::IsNullOrWhiteSpace($staticRoot)) {
                        [string]$descendingPath = $uniqueName.Substring($DocumentsFolder.Length)
                        while ($descendingPath.StartsWith([System.IO.Path]::DirectorySeparatorChar) -or $descendingPath.StartsWith([System.IO.Path]::AltDirectorySeparatorChar)) {
                            $descendingPath = $descendingPath.Substring(1);
                        }

                        $relativePath = [System.IO.Path]::Combine($staticRoot, $descendingPath).Replace([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
                    }
                    else {
                        $relativePath = Get-RelativePath -Directory $documentDirectory -FilePath $uniqueName -UseWebPathSeparator
                    }

                    if (-not $documentBrokenLinks.ContainsKey($_["path"])) {
                        $documentBrokenLinks.Add($_["path"], @{})
                    }

                    $documentBrokenLinks[$_["path"]][$cleanLink] = $relativePath;
                }
            }

            $line = $("{0}`t{1}`t{2}`t{3}`t{4}`t{5}`t{6}`t{7}`t{8}" -f $_["path"], $_["linenumber"], $_["match"], $_["link"], $nameInBrokenLink, $isUniqueName, $uniqueName, $relativePath, $fixBrokenLinks )            
            $brokenLinksReport += $line
            Write-Progress ("Broken link reported: " + $line)
        } 

        [int]$fixedDocumentCount = 0
        if ($fixBrokenLinks -and $documentBrokenLinks.Count -gt 0) {
            $documentBrokenLinks.GetEnumerator() |
                ForEach-Object { 
                $DocumentWithBrokenLinks = $_.Key; 
                $brokenLinksInDocument = $_.Value
                $currentContent = [System.IO.File]::ReadAllText($DocumentWithBrokenLinks)
                [int]$fixedLinkCount = 0
                $brokenLinksInDocument.GetEnumerator() |
                    ForEach-Object {
                    $fixedLinkCount++
                    $brokenLink = $_.Key
                    $fixedLink = $_.Value
                    $currentContent = $currentContent.Replace($brokenLink, $fixedLink)
                }
                [System.IO.File]::WriteAllText($DocumentWithBrokenLinks, $currentContent)
                $msg = "Fixed document $DocumentWithBrokenLinks; links fixed: $fixedLinkCount"
                write-verbose $msg
                $fixedDocumentCount++
            }
        }

        if (-not [string]::IsNullOrWhiteSpace($BrokenLinkReportPrefix)) {
            $BrokenLinkReportPrefix = $BrokenLinkReportPrefix.Trim()
        }
        else {
            $BrokenLinkReportPrefix = [string]::Empty
        }

        $linkreferences | ForEach-Object { Write-Output $("{0}`t{1}`t{2}`t{3}" -f $_["path"], $_["linenumber"], $_["link"], $_["nestedParentheses"])} > $("$BrokenLinkReportPrefix-LinkedReferences {0}.tsv" -f [DateTime]::Now.ToString("yyyy-MM-dd HHmm") )
        $brokenLinksReport > $("$BrokenLinkReportPrefix-Broken Links Report {0}.tsv" -f [DateTime]::Now.ToString("yyyy-MM-dd HHmm") )
        $documentBrokenLinks.GetEnumerator() |`
            ForEach-Object { 
            $DocumentWithBrokenLinks = $_.Key; 
            $_.Value.GetEnumerator() |`
                ForEach-Object {
                $brokenLink = $_.Key
                $fixedLink = $_.Value
                Write-Output "$DocumentWithBrokenLinks`t$brokenLink`t$fixedLink"
            }
        } > $("$BrokenLinkReportPrefix-Document Broken Links Fix {0}.tsv" -f [DateTime]::Now.ToString("yyyy-MM-dd HHmm") )

        Write-Verbose "Assets: $assetCount, duplicated names ratio (1.0 means no duplicates): $duplicateNameRatio"
        Write-Verbose "Linked references: $linkreferencesCount"
        Write-Verbose "Unique links: $uniqueLinksDictionaryCount"
        $msg = "Processing reference {0,5} of {1,6} total. broken links found {2,5} " -f $referencesProcessed, $linkreferences.count, $brokenlinks.count; 
        Write-Verbose $msg
        Write-Verbose "Documents fixed: $fixedDocumentCount"
    }


}