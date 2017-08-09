function Update-ToC(){
  [CmdletBinding()]
  param(
    [parameter(Mandatory=$true)] [ValidateScript({ Test-Path -LiteralPath $_ })] [string] $RootSourceFolder,
    [parameter(Mandatory=$true)] [ValidateScript({ Test-Path -LiteralPath $_ })] [string] $RootOutputFolder
  )

  BEGIN {
    $ToCFolders = @{ $RootSourceFolder = $RootOutputFolder } 
  }

  END {
    Get-ChildItem -Path $RootSourceFolder -Recurse |
        Where-Object { $_.PSIsContainer } |
        ForEach-Object {
          [string]$relativepath = Get-RelativePath -Directory $RootSourceFolder -FilePath $_.FullName
          $ToCFolders[($_.FullName)] = [System.IO.Path]::Combine($RootOutputFolder, $relativepath)
        }

    $ToCFolders.GetEnumerator() |
      ForEach-Object {
        [string]$TocRootFolder = $_.Key
        [string]$TocOutputFolder = $_.Value
            
        Write-Progress "Generating ToC for: $TocRootFolder"
        Write-DocumentsForTOC -RootFolder $TocRootFolder -TocOutputFolder $TocOutputFolder
      }
  }
}

