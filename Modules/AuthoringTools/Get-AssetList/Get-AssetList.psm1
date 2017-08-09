function Get-AssetList() {
    [CmdletBinding(DefaultParameterSetName="default")]
    Param(
        [parameter(Mandatory = $true, ParameterSetName="default" )] 
            [parameter(Mandatory = $true, ParameterSetName="UniqueReferences" )] 
            [parameter(Mandatory = $true, ParameterSetName="MultipleReferences" )] 
            [ValidateScript( { Test-Path -LiteralPath $_ -PathType Container })] 
            [string]$AssetFolder,
        [parameter(Mandatory = $false, ParameterSetName="UniqueReferences" )][switch]$OnlyUniqueReferences,
        [parameter(Mandatory = $false, ParameterSetName="MultipleReferences" )][switch]$MultipleReferences
    )

    BEGIN{
        $Assets = @{}
        $MultipleReferencedAssets = @{}
    }

    END{
        Get-ChildItem -Path $AssetFolder -recurse |
            Where-Object { $_.FullName -notlike "*.ignore*" -and (-not $_.PSIsContainer)} |
            ForEach-Object { 
                $name = $_.Name.ToLowerInvariant();
                $path = $_.FullName
                if (-not $Assets.ContainsKey($name)) {
                    $Assets.Add($name, @())
                }

                $Assets[$name] += $path

                if ($Assets[$name].Length -gt 1) {
                    $MultipleReferencedAssets[$name] = $Assets[$name].Length
                }
            }   

            if ($OnlyUniqueReferences) {
                $null = $MultipleReferencedAssets.Keys.ForEach({$Assets.Remove($_)})
            } elseif ($MultipleReferences) {
                $null = ($Assets.Keys).Where({-not $MultipleReferences.ContainsKey($_)}).ForEach({$Assets.Remove($_)})                    
            } 

            $Assets
    }
}