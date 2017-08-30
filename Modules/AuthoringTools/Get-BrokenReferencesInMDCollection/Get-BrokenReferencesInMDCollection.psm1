USING MODULE CommonClasses

function Get-BrokenReferencesInMDCollection () {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory = $true)] 
        [ValidateScript( { Test-Path -LiteralPath $_ -PathType Container })] 
        [string]$CollectionFolder
    )

    BEGIN{
        $Assets = Get-AssetList -AssetFolder $CollectionFolder
    }

    END {
        $Assets.Keys.Where({ $_ -like "*.md"}) |
            ForEach-Object { $Assets[$_]} |
            ForEach-Object { 
                Write-Progress ($_)
                Get-MDReferencesFromDocument -DocumentPath $_ | 
                    Test-MDReference -AssetList $Assets -OnlyFailed 
            }
    }
}