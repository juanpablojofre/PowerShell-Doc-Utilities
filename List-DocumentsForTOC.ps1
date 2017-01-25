Get-ChildItem -Path "C:\GIT\PowerShell-Docs\scripting\setup" -Filter "*.md" |
    Where-Object { (-not $_.PSIsContainer) -and ($_.FullName -notlike "*ignore*")} |
    ForEach-Object { 
        $nameWithoutExtension = $_.BaseName.Replace("-", " ")
        $name = $_.Name
        Write-Output "-  [$nameWithoutExtension]($name)" } |
    Sort |
    Add-Content -Encoding Ascii -Path "C:\GIT\PowerShell-Docs\scripting\setup\setup-reference.md"
 
