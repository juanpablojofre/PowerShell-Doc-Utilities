$CurrentVerbosePreference = $VerbosePreference
$VerbosePreference = "Continue"
[int]$totalEmptyTopics = 0
Get-ChildItem -path "C:\GIT\PowerShell-Docs\scripting" -Filter "*.md" -Recurse |`
    Where-Object { (-not $_.PSIsContainer) -and ($_.Length -eq 0) -and ($_.FullName -notlike "*ignore*")} |`    ForEach-Object { $totalEmptyTopics++; $_.FullName }Write-Verbose "Total empty topics: $totalEmptyTopics"$VerbosePreference = $CurrentVerbosePreference
