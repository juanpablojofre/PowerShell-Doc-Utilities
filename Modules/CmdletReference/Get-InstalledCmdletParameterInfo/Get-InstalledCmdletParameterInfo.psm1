function Get-InstalledCmdletParameterInfo {
  [CmdletBinding()]
  Param (
    [parameter(Mandatory=$true)] 
    [ValidateScript({Test-Path -LiteralPath $_ -PathType Container})]
    [String] $outputfolder,    
    [parameter(Mandatory=$false)] 
    [ValidateNotNull()]
    [String[]] $modulelist = @("*")    
  )

  if(-not $modulelist -or ($modulelist.Length -eq 0)) {
    $modulelist = @("*")
  }

  [string[]]$CmdletReference = @()
  [string[]]$CmdletParamSetReference = @()
  [string[]]$CmdletParameterReference = @()


  [string]$osversion = Get-OSVersion
  [string]$filenamesuffix = $osversion + "-" + [datetime]::Now.ToString("yyMMdd-HHmmss") + ".txt"
  [string]$CmdletReferenceFilename = (Join-Path -Path $outputfolder -ChildPath "CmdletReference-") + $filenamesuffix
  [string]$CmdletParamSetReferenceFilename = (Join-Path -Path $outputfolder -ChildPath "CmdletParamSetReference-") + $filenamesuffix
  [string]$CmdletParameterReferenceFilename = (Join-Path -Path $outputfolder -ChildPath "CmdletParameterReference-") + $filenamesuffix


  Get-Command -Module $modulelist |
  Sort-Object -Property ModuleName,Source,Name |
  ForEach-Object { 
    [string]$cmdletname = $_.Name.ToLowerInvariant()
    [string]$cmdletmodule = $_.ModuleName.ToLowerInvariant()
    [string]$cmdlettype = $_.CommandType.ToString().ToLowerInvariant()
    [string]$cmdletoutputtype = [string]::Empty

    Write-Progress "working on $cmdletmodule.$cmdletname"
  
    ##
    ## Prepare CmdletReference data
    ##
    if($_.OutputType) {
      if($_.OutputType.Count -gt 0){
        $cmdletoutputtype = [string]::Join("|", ($_.OutputType | ForEach-Object { $_.Name } | Sort-Object))
      }
      else {
        $cmdletoutputtype = $_.OutputType.Name
      }
    }

    [string]$cmdletdisplayname = $_.Name
    [string]$cmdletmoduledisplayname = $_.ModuleName

    $CmdletReference += ([string]::Join("`t", @($osversion, $cmdletmodule, $cmdletname, $cmdlettype, $cmdletoutputtype, $cmdletdisplayname, $cmdletmoduledisplayname)))  
  
    ##
    ## Prepare CmdletParamSetReference data   
    ##      
    if($_.ParameterSets) {
      $_.ParameterSets | Sort-Object -Property Name |
        ForEach-Object {
          [string]$parametersetname = $_.Name.ToLowerInvariant()
          [bool]$isdefaultparameterset = $_.IsDefault
      
          [string]$parametersetdisplayname = $_.Name
            
          $_.Parameters |
          ForEach-Object {
            [string]$parametername = $_.Name.ToLowerInvariant()
            [string]$parameterdisplayname = $_.Name
            $CmdletParamSetReference += [string]::Join("`t", @($osversion, $cmdletmodule, $cmdletname, $parametersetname, $isdefaultparameterset, $parametername, $parametersetdisplayname, $parameterdisplayname))
          }
        }    
    }

    ##
    ## Prepare CmdletParameterReference data  
    ##      
    if($_.Parameters) {
      $paramsdictionary = $_.Parameters
      $paramsdictionary.Keys |
      Sort-Object |
      ForEach-Object {
        [string]$parametername = $_.ToLowerInvariant()
        [string]$parameterdisplayname = $_
        $parameter = $paramsdictionary[$parameterdisplayname]
        [string]$parametertypename = $parameter.ParameterType.FullName
        [string]$paramsetlist = [string]::Join("|", ($parameter.ParameterSets.Keys | Sort-Object)) 
        $CmdletParameterReference += [string]::Join("`t", @($osversion, $cmdletmodule, $cmdletname, $parametername, $parametertypename, $paramsetlist, $parameterdisplayname))
      }
    }
  }

  [System.IO.File]::WriteAllLines($CmdletReferenceFilename, $CmdletReference, [System.Text.UnicodeEncoding]::ASCII)
  [System.IO.File]::WriteAllLines($CmdletParamSetReferenceFilename, $CmdletParamSetReference, [System.Text.UnicodeEncoding]::ASCII)
  [System.IO.File]::WriteAllLines($CmdletParameterReferenceFilename, $CmdletParameterReference, [System.Text.UnicodeEncoding]::ASCII)
}



