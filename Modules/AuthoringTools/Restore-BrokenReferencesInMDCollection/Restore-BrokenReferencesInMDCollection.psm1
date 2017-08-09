USING MODULE CommonClasses
function Restore-BrokenReferencesInMDCollection () {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory = $true, ValueFromPipeline=$true)] 
            [MDReference[]]$References,
        [Parameter(Mandatory = $true, ParameterSetName="CollectionFolder")]
            [ValidateNotNullOrEmpty()]
            [ValidateScript( {Test-Path -Path $_ -PathType Container })]
            [string]$CollectionFolder,
        [Parameter(Mandatory = $true, ParameterSetName="AssetList")]
            [ValidateNotNullOrEmpty()]
            [hashtable]$AssetList,
        [parameter(Mandatory=$false)] [switch]$UseTextForEmptyLinks,
        [parameter(Mandatory=$false)] 
            [ValidateSet("UTF8BOM", "UTF8NOBOM", 
                "ASCII", "UTF7",
                "UTF16BigEndian", "UTF16LittleEndian", "Unicode",
                "UTF32BigEndian", "UTF32LittleEndian")]
            [string] $encode = "UTF8NOBOM"
    )

    BEGIN {
        [MDReference[]]$BrokenReferences = @()
        if ($PSCmdlet.ParameterSetName -eq "CollectionFolder") {
            $AssetList = Get-AssetList -AssetFolder $CollectionFolder
        }

        $MDHeadingsCache = @{}
    }

    PROCESS {
        $References | 
            Where-Object { $_.ReferenceStatus -eq [MDReferenceStatus]::Failed -and ($_.Link -notlike "http*" )} |
            ForEach-Object { $BrokenReferences += $_ }
    } 

    END {
        $BrokenReferences | Group-Object -Property DocumentPath |
            ForEach-Object {
                [string]$DocumentPath = $_.Name
                [string]$Content = [System.IO.File]::ReadAllText($DocumentPath , (Get-EncodingFromLabel -encode $encode))
                [bool]$ContentUpdated = $false
                $_.Group |  ForEach-Object {
                    [MDReference]$reference = $_
                    [string]$externallink = $reference.GetExternalLink().Replace('/','\')

                    if ([string]::IsNullOrWhiteSpace($reference.Link) -and $UseTextForEmptyLinks) {
                        $externallink = $reference.Text.Trim().Replace(' ', '-') + ".md"
                    }

                    ## Test external link
                    if (-not [string]::IsNullOrWhiteSpace($externallink)) {
                        try {
                            $linkname = [System.IO.Path]::GetFileName($externallink)
                        }
                        catch  {
                            $linkname = $_.Exception.Message
                        }

                        if ($AssetList[$linkname].Count -eq 1) {
                            [string]$DocumentFolder = [System.IO.Path]::GetDirectoryName($DocumentPath)
                            [string]$fulllink = $AssetList[$linkname][0]
                            [string]$internallink = $reference.GetInternalLink()
                            [bool]$internalexists = $false

                            ## Test internal link
                            if([string]::IsNullOrWhiteSpace($internallink)){
                                $internalexists = $true                     
                            }else{

                                if(-not $MDHeadingsCache.ContainsKey($fulllink)) {
                                    $MDHeadingsCache.Add($fulllink, (Get-MDHeadingReferences -DocumentPath $fulllink))
                                }

                                $internalexists = $MDHeadingsCache[$fulllink].ContainsKey($internallink)                     
                            }

                            if ($internalexists) {
                                [string]$OriginalLink = $reference.OriginalReference
                                $reference.Link = (Get-RelativePath -Directory $DocumentFolder -FilePath $fulllink).Replace('\','/')
                                [string]$NewLink = $reference.GetNewReference()
                                $Content = $Content.Replace($OriginalLink,$NewLink)
                                $reference.ReferenceStatus = [MDReferenceStatus]::Restored
                                $ContentUpdated = $true
                            }
                        }
                    }

                    $reference
                }

                if ($ContentUpdated) {
                    [System.IO.File]::WriteAllText($DocumentPath, $Content, (Get-EncodingFromLabel -encode $encode))
                    Write-Warning "Document updated: $DocumentPath"
                }

            }
    }
}