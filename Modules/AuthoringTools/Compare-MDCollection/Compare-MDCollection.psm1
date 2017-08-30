enum MDComparisonStatus {
    OnlyLeft
    OnlyRight
    Equal
    Different
}

class ComparedMDTopic{
    [string]$DocumentRelativePath
    [MDComparisonStatus]$ComparisonStatus
    ComparedMDTopic([string]$path, [MDComparisonStatus] $status){
        $this.DocumentRelativePath = $path
        $this.ComparisonStatus = $status
    }
}

function Compare-MDCollection(){
    [CmdletBinding()]
    Param(
        [parameter(Mandatory = $true)] 
            [ValidateScript( { Test-Path -Path $_ -PathType container })] 
            [string]$LeftFolderPath,
        [parameter(Mandatory = $true)] 
            [ValidateScript( { Test-Path -Path $_ -PathType container })] 
            [string]$RightFolderPath
    )

    BEGIN {
        $Documents = @{}
        $LeftFolderPath = $LeftFolderPath.Trim();
        $RightFolderPath = $RightFolderPath.Trim();
        if(-not $LeftFolderPath.EndsWith('\')) { $LeftFolderPath = $LeftFolderPath + '\' }
        if(-not $RightFolderPath.EndsWith('\')) { $RightFolderPath = $RightFolderPath + '\' }
    }

    END{
        (Get-ChildItem -Path $LeftFolderPath -Filter "*.md" -Recurse).foreach{ $Documents.Add($_.FullName.Substring($LeftFolderPath.Length), [MDComparisonStatus]::OnlyLeft) }

        Get-ChildItem -Path $RightFolderPath -Filter "*.md" -Recurse |
            ForEach-Object {
                $relativePath = $_.FullName.Substring($RightFolderPath.Length)
                if($Documents.ContainsKey($relativePath)){
                    $leftHash = (Get-FileHash -Path (Join-Path $LeftFolderPath -ChildPath $relativePath) -Algorithm MD5).Hash
                    $rightHash = (Get-FileHash -Path (Join-Path $RightFolderPath -ChildPath $relativePath) -Algorithm MD5).Hash
                    if($leftHash -eq $rightHash){
                        $Documents[$relativePath] = [MDComparisonStatus]::Equal
                    }
                    else{
                        $Documents[$relativePath] = [MDComparisonStatus]::Different
                    }
                }
                else {
                    $Documents.Add($relativePath, [MDComparisonStatus]::OnlyRight)
                }
            }

        $Documents.Keys| Sort-Object | ForEach-Object{ [ComparedMDTopic]::new($_, $Documents[$_]) }
    }
}