function Get-EmptyTopics () {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {Test-Path -Path $_ -PathType Container })]
        [string]$DocumentsFolder
    )
    
    BEGIN {
        [int]$totalEmptyTopics = 0
    }

    END{
        Get-ChildItem -path $DocumentsFolder -Filter "*.md" -Recurse |
            Where-Object { (-not $_.PSIsContainer) -and ($_.FullName -notlike "*ignore*") -and ($_.Length -eq 0)} |
            ForEach-Object { $totalEmptyTopics++; $_.FullName }

        Write-Verbose "Total empty topics: $totalEmptyTopics"
    }
}
