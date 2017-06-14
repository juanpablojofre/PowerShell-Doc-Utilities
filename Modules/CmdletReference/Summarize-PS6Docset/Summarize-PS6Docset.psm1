function Summarize-PS6Docset{
  [CmdletBinding()]
  param(
    [parameter(Mandatory=$true)] 
    [ValidateScript({Test-Path -LiteralPath $_ -PathType Container})]
    [String]
    $outputfolder
    , [parameter(Mandatory=$false)] 
    [ValidateNotNullOrEmpty()]
    [String]
    $statusfile = "PS6DocStatus.tsv"  
  )
  
  BEGIN {
  
  }
  
  PROCESS {
  
  }
  
  END {
    if ((-not $Global:ps6docset) -or (1 -gt $Global:ps6docset.Keys))
    {
      Write-Warning "Documentation information not available to summarize!"
      return
    }
  
    [string[]]$lines=@()
    
    $Global:ps6docset.Keys.GetEnumerator() |
    Sort-Object |
    ForEach-Object {
      $modulename = $_
      $Global:ps6docset[$modulename].Keys.GetEnumerator() |
        Sort-Object |
        ForEach-Object {
          $cmdletname = $_
          $docstatus = $Global:ps6docset[$modulename][$cmdletname]
          $status = "$modulename`t$cmdletname`t$docstatus"
          Write-Progress $status
          $lines += $status
        }
      }
  
      [System.IO.File]::WriteAllLines((Join-Path -Path $outputfolder -ChildPath $statusfile), $lines)
    }
}