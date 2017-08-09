function Build-CmdletReferenceInfo{
  [CmdletBinding()]
  param(
    [parameter(Mandatory=$true)] 
    [ValidateScript({Test-Path -LiteralPath $_ -PathType Container})]      
    [String]$datafolder
  )

  $cmdletReferenceData = Get-ChildItem -Path $datafolder -Filter "CmdletReference-*.txt"
  $paramSetReferenceData = Get-ChildItem -Path $datafolder -Filter "CmdletParamSetReference-*.txt"
  $parameterReferenceData = Get-ChildItem -Path $datafolder -Filter "CmdletParameterReference-*.txt"

  $Global:ModuleCmdletDict = @{}
  $Global:ModuleNameDict = @{}
  [System.Collections.Hashtable]$Global:OsVersions = [System.Collections.Hashtable]::new()

  $cmdletReferenceData |
  ForEach-Object {
    [string[]]$lines = [System.IO.File]::ReadAllLines($_.FullName)
    $lines |
    ForEach-Object {
      ## $osversion, $cmdletmodule, $cmdletname, $cmdlettype, $cmdletoutputtype, $cmdletdisplayname, $cmdletmoduledisplayname
      [string]$line = $_
      [string[]]$columns = $line.Split("`t")
        
      $osversion = $columns[0]
      $cmdletmodule = $columns[1]
      $cmdletname = $columns[2]
      $cmdlettype = $columns[3]
      $cmdletoutputtype = $columns[4]
      $cmdletdisplayname = $columns[5]
      $cmdletmoduledisplayname = $columns[6]
        
      ## Add OS versions
      if(-not $Global:OsVersions.ContainsKey($osversion)) {
        $Global:OsVersions.Add($osversion, $true)
      }
      
      ## Setup Module Name info
      if(-not $Global:ModuleNameDict.ContainsKey($cmdletmodule)) {
        $Global:ModuleNameDict.Add($cmdletmodule, @{})
        $Global:ModuleNameDict[$cmdletmodule].Add("DisplayName", $cmdletmoduledisplayname)
        $Global:ModuleNameDict[$cmdletmodule].Add("Availability", @{})
      }
        
      $Global:ModuleNameDict[$cmdletmodule]["Availability"][$osversion] = $true
        
      ## Setup Cmdlet reference info
      if(-not $Global:ModuleCmdletDict.ContainsKey($cmdletmodule)) {
        $Global:ModuleCmdletDict.Add($cmdletmodule, @{})
      }
        
      if(-not $Global:ModuleCmdletDict[$cmdletmodule].ContainsKey($cmdletname)) {
        $Global:ModuleCmdletDict[$cmdletmodule].Add($cmdletname, @{})
        $Global:ModuleCmdletDict[$cmdletmodule][$cmdletname].Add("Availability", @{})
        $Global:ModuleCmdletDict[$cmdletmodule][$cmdletname].Add("ParamSets", @{})
        $Global:ModuleCmdletDict[$cmdletmodule][$cmdletname].Add("Parameters", @{})
        $Global:ModuleCmdletDict[$cmdletmodule][$cmdletname].Add("OutputType", @{})
        $Global:ModuleCmdletDict[$cmdletmodule][$cmdletname].Add("CmdletType", @{})
      }
        
      $Global:ModuleCmdletDict[$cmdletmodule][$cmdletname]["Availability"][$osversion] = $cmdletdisplayname
      $Global:ModuleCmdletDict[$cmdletmodule][$cmdletname]["OutputType"][$osversion] = $cmdletoutputtype
      $Global:ModuleCmdletDict[$cmdletmodule][$cmdletname]["CmdletType"][$osversion] = $cmdlettype              
    }
  }
  
  $paramSetReferenceData |
  ForEach-Object {
    [string[]]$lines = [System.IO.File]::ReadAllLines($_.FullName)
    $lines |
    ForEach-Object {
      ## $osversion, $cmdletmodule, $cmdletname, $parametersetname, $isdefaultparameterset, $parametername, $parametersetdisplayname, $parameterdisplayname
      [string]$line = $_
      [string[]]$columns = $line.Split("`t")
        
      $osversion = $columns[0]
      $cmdletmodule = $columns[1]
      $cmdletname = $columns[2]
      $parametersetname = $columns[3]
      $isdefaultparameterset = $columns[4]
      $parametername = $columns[5]
      $parametersetdisplayname = $columns[6]
      $parameterdisplayname = $columns[7]
      
      ## Add OS versions
      if(-not $Global:OsVersions.ContainsKey($osversion)) {
        $Global:OsVersions.Add($osversion, $true)
      }
            
      if(-not $Global:ModuleCmdletDict[$cmdletmodule][$cmdletname]["ParamSets"].ContainsKey($parametersetname)) {
        $Global:ModuleCmdletDict[$cmdletmodule][$cmdletname]["ParamSets"].Add($parametersetname, @{})              
      }
      
      if(-not $Global:ModuleCmdletDict[$cmdletmodule][$cmdletname]["ParamSets"][$parametersetname].ContainsKey($osversion)) {
        $Global:ModuleCmdletDict[$cmdletmodule][$cmdletname]["ParamSets"][$parametersetname].Add($osversion, @{})   
        $Global:ModuleCmdletDict[$cmdletmodule][$cmdletname]["ParamSets"][$parametersetname][$osversion].Add("DisplayName", $parametersetdisplayname)
        $Global:ModuleCmdletDict[$cmdletmodule][$cmdletname]["ParamSets"][$parametersetname][$osversion].Add("IsDefaultParamSet", $isdefaultparameterset)
        $Global:ModuleCmdletDict[$cmdletmodule][$cmdletname]["ParamSets"][$parametersetname][$osversion].Add("ParamList", @())
        $Global:ModuleCmdletDict[$cmdletmodule][$cmdletname]["ParamSets"][$parametersetname][$osversion].Add("ParamListHash", [string]::Empty)
      }
      
      $Global:ModuleCmdletDict[$cmdletmodule][$cmdletname]["ParamSets"][$parametersetname][$osversion]["ParamList"] += $parametername                        
    }
  }
  
  $parameterReferenceData |
  ForEach-Object {
    [string[]]$lines = [System.IO.File]::ReadAllLines($_.FullName)
    $lines |
    ForEach-Object {
      ## $osversion, $cmdletmodule, $cmdletname, $parametername, $parametertypename, $paramsetlist, $parameterdisplayname
      [string]$line = $_
      [string[]]$columns = $line.Split("`t")
      
      $osversion = $columns[0]
      $cmdletmodule = $columns[1]
      $cmdletname = $columns[2]
      $parametername = $columns[3]
      $parametertypename = $columns[4]
      $paramsetlist = $columns[5]
      $parameterdisplayname = $columns[6] 
      
      ## Add OS versions
      if(-not $Global:OsVersions.ContainsKey($osversion)) {
        $Global:OsVersions.Add($osversion, $true)
      }
            
      if(-not $Global:ModuleCmdletDict[$cmdletmodule][$cmdletname]["Parameters"].ContainsKey($parametername)) {
        $Global:ModuleCmdletDict[$cmdletmodule][$cmdletname]["Parameters"].Add($parametername, @{})              
      }
      
      if(-not $Global:ModuleCmdletDict[$cmdletmodule][$cmdletname]["Parameters"][$parametername].ContainsKey($osversion)) {
        $Global:ModuleCmdletDict[$cmdletmodule][$cmdletname]["Parameters"][$parametername].Add($osversion, @{})
      }
      
      $Global:ModuleCmdletDict[$cmdletmodule][$cmdletname]["Parameters"][$parametername][$osversion].Add("ParameterDisplayName", $parameterdisplayname)
      $Global:ModuleCmdletDict[$cmdletmodule][$cmdletname]["Parameters"][$parametername][$osversion].Add("ParameterTypeName", $parametertypename)
      $Global:ModuleCmdletDict[$cmdletmodule][$cmdletname]["Parameters"][$parametername][$osversion].Add("ParamSetList", $paramsetlist)
    }
  }
}
  
