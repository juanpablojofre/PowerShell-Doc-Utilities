function Test-HttpUrl() {
        [CmdletBinding()]
    Param(
        [parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()]
            [string]$url,
        [parameter(Mandatory = $false)]
            [int]$MaximumRedirection = 5,
        [parameter(Mandatory = $false)]
            [switch]$GetUserCredentials
            
    )

    BEGIN {
        [string]$initialWarningPreference = $WarningPreference
        [string]$initialErrorActionPreference = $ErrorActionPreference
        $secpasswd = ConvertTo-SecureString "PlainTextPassword" -AsPlainText -Force
        [System.Management.Automation.PSCredential]$sessioncredentials = [System.Management.Automation.PSCredential]::new("anonymous", $secpasswd)
    }

    END {
        ## Revert escaped characters in text
        [string]$weblink = Get-UnEscapedText $url

        $r = $null;
        try {
            $WarningPreference = 'SilentlyContinue'
            $ErrorActionPreference = 'SilentlyContinue'
            if ($GetUserCredentials) {
                $sessioncredentials = Get-Credential
            }

            ## -UseBasicParsing
            ($r = Invoke-WebRequest -URI $weblink -MaximumRedirection $MaximumRedirection -Credential $sessioncredentials -DisableKeepAlive  -WarningAction SilentlyContinue  -ErrorAction SilentlyContinue -errorvariable ignoreerror) 2>$null 1>$null
        }
        catch {
            ## Do nothing => SilentlyContinue
        }
        finally {
            $WarningPreference = $initialWarningPreference
            $ErrorActionPreference = $initialErrorActionPreference
            $r
        }
    }
}