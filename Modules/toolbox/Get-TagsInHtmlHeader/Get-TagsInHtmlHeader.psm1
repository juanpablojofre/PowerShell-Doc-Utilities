function Get-TagsInHtmlHeader()
{
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [ValidateScript({$_.ToLowerInvariant().StartsWith("http")})]
            [string] $weburl
    )

    BEGIN {
        $initialWarningPreference = $WarningPreference
        $initialErrorActionPreference = $ErrorActionPreference
    }

    END {
        $r = $null;
        try {
            $WarningPreference = 'SilentlyContinue'
            $ErrorActionPreference = 'SilentlyContinue'
            ($r = Invoke-WebRequest -URI $weburl -MaximumRedirection 5 -WarningAction SilentlyContinue  -ErrorAction SilentlyContinue -errorvariable ignoreerror) 2>$null 1>$null
        } catch {
            ## Do nothing => SilentlyContinue
        } finally {
            $WarningPreference = $initialWarningPreference
            $ErrorActionPreference = $initialErrorActionPreference
        }

        if (($r.StatusCode -lt 200) -or ($r.StatusCode -ge 300)){
            $code = $r.StatusCode
            $status = $r.StatusDescription
            write-verbose "Web request to $weburl returned # $code : $status"
            return
        }

        [xml]$htmlresponse = $r.Content
        $headelement = $htmlresponse["html"]["head"]

        $headelement.ChildNodes.GetEnumerator() |
            Where-Object { $_.LocalName -eq "meta"} |
            ForEach-Object {
                [System.Xml.XmlNode]$node = $_
                $nodeAttName = $node.Attributes["name"].Value
                $nodeAttValue = $node.Attributes["content"].Value
                @{$nodeAttName = $nodeAttValue}
            }        
    }
}    