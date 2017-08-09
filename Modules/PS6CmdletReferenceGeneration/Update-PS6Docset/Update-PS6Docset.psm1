function Update-PS6Docset {
  [CmdletBinding()]
  param(
    [parameter(Mandatory=$true)] 
      [ValidateScript({
          Test-Path -LiteralPath $_ -PathType Container
      })]
      [String]
      $datafolder,
    [parameter(Mandatory=$true)] 
      [ValidateScript({Test-Path -LiteralPath $_ -PathType Container})]
      [String]
      $docs51folder,  
    [parameter(Mandatory=$true)] 
      [ValidateScript({Test-Path -LiteralPath $_ -PathType Container})]
      [String]
      $docs6folder,  
    [parameter(Mandatory=$true)] 
      [ValidateScript({Test-Path -LiteralPath $_ -PathType Container})]
      [String]
      $platylogfolder  
    )
  
  if (-not (Get-Module -ListAvailable -Name PlatyPS)) {
    Install-Module -Name platyPS -Scope CurrentUser
  }
  
  Import-Module platyPS  
  
  Build-CmdletReferenceInfo -datafolder $datafolder
  
  ## Common variables
  [string]$modulename = [string]::Empty
  [string]$moduledisplayname = [string]::Empty
  [string]$modulefolder = [string]::Empty
    
  [string]$cmdletname = [string]::Empty
  [string]$cmdletdisplayname = [string]::Empty
  
  ## constant values
  [datetime]$now = [datetime]::Now
  [string]$logsubfoldername = $now.ToString("yyy-MM-dd_HHmmss")
  
  ## Global Variables
  $Global:ps6docset = @{}
  
  
  ## Validate Modules folder structure is correct or viable
  $Global:ModuleNameDict.GetEnumerator() |
    ForEach-Object {
      $modulefolder = Join-Path -Path $docs6folder -ChildPath ($_.Value["DisplayName"])
      if((Test-Path -LiteralPath $modulefolder) -and 
         (-not (Test-Path -LiteralPath $modulefolder -PathType Container))) {
          throw [System.IO.DirectoryNotFoundException]::new("$modulefolder not a folder.")
      }
    }
  
  ## Make log subfolder
  $logsubfolder = Join-Path -Path $platylogfolder -ChildPath $logsubfoldername
  if (-not (Test-Path -LiteralPath $logsubfolder)) {
    New-Item -Path $platylogfolder -Name $logsubfoldername -ItemType 'directory' > $null
  }
  
  
  ## Port available content from 5.1
  $Global:ModuleNameDict.GetEnumerator() |
    ForEach-Object {
      $modulename = $_.Key
      $moduledisplayname = $_.Value["DisplayName"]
      
      if([string]::IsNullOrWhiteSpace($modulename)) {
        $moduledisplayname = "Microsoft.PowerShell.Core"
      }
    
      if (-not [string]::IsNullOrWhiteSpace($modulename) -and "Microsoft.PowerShell.Core" -ne $modulename) {
        Import-Module -Name $modulename
      }
      
      if (-not $Global:ps6docset.ContainsKey($moduledisplayname)) {
        $Global:ps6docset.Add($moduledisplayname, @{})
      }
    
      $modulefolder = Join-Path -Path $docs6folder -ChildPath $moduledisplayname
      if (-not (Test-Path -LiteralPath $modulefolder)) {
        New-Item -Path $docs6folder -Name $moduledisplayname -ItemType 'directory' > $null
      }
    
      ## Iterate over the known cmdlets and find available content
      $Global:ModuleCmdletDict[$modulename].GetEnumerator() |
        ForEach-Object {
          $cmdletname = $_.Key
          $cmdletdisplayname = @($_.Value["Availability"].Values)[0].ToString()
      
          if (-not $Global:ps6docset[$moduledisplayname].ContainsKey($cmdletdisplayname)) {
            $Global:ps6docset[$moduledisplayname].Add($cmdletdisplayname, "checking")
          }
              
          [string]$cmdletmdsrc = Join-Path -Path $docs51folder -ChildPath $moduledisplayname
          $cmdletmd = 
            Get-ChildItem -Path $cmdletmdsrc -Filter "*.md" -Recurse | 
            Where-Object { 
              $_.Name.StartsWith($cmdletname, [System.StringComparison]::InvariantCultureIgnoreCase) 
            }
            
          if ($cmdletmd) {
            $cmdletfs = $cmdletmd[0]
            Write-Progress "Copying $moduledisplayname . $cmdletdisplayname"
            Copy-Item -LiteralPath $cmdletfs.FullName -Destination $modulefolder
            if (Test-Path -LiteralPath (Join-Path -Path $modulefolder -ChildPath ($cmdletfs.Name))) {
              $Global:ps6docset[$moduledisplayname][$cmdletdisplayname] = "ported"
          
              ## Check existing content with PLatyPS
              $modulelogfolder = Join-Path -Path $logsubfolder -ChildPath $moduledisplayname
              if (-not (Test-Path -LiteralPath $modulelogfolder)) {
                New-Item -Path $logsubfolder -Name $moduledisplayname -ItemType 'directory' > $null
              }
                
              [string]$logfilename = Join-Path -Path $modulelogfolder -ChildPath ($cmdletdisplayname + ".log")  
              try{
                Update-MarkdownHelp -Path ($cmdletfs.FullName) -LogPath $logfilename
              } catch {
                $err = $_
                $ex = $err.Exception
                [string[]]$errorinfo = @()
                $errorinfo += "Module         : " + $moduledisplayname
                $errorinfo += "Cmdlet         : " + $cmdletdisplayname
                $errorinfo += "Error message  : " + ($ex.Message)
                $errorinfo += "Error source   : " + ($ex.Source)
                $errorinfo += "Error stack trc: " + ($ex.StackTrace)
                $errorinfo += "PS msg details : " + ($_.PSMessageDetails)
                $errorinfo += "ScriptStackTrace : " + ($_.ScriptStackTrace)
                   
                Write-Warning ([string]::Join("`r`n",$errorinfo))
          
                $Global:ps6docset[$moduledisplayname][$cmdletdisplayname] = "PlatyPS error updating md"
                [System.IO.File]::AppendAllLines($logfilename, $errorinfo)
              }          
            } 
            else {
              $Global:ps6docset[$moduledisplayname][$cmdletdisplayname] = "not ported"                  
            }       
          }
          else {
            $Global:ps6docset[$moduledisplayname][$cmdletdisplayname] = "not documented"
          
            ## Check existing content with PlatyPS
            $modulelogfolder = Join-Path -Path $logsubfolder -ChildPath $moduledisplayname
            if (-not (Test-Path -LiteralPath $modulelogfolder)) {
              New-Item -Path $logsubfolder -Name $moduledisplayname -ItemType 'directory' > $null
            }
            
            try {         
              [string]$logfilename = Join-Path -Path $modulelogfolder -ChildPath ($cmdletdisplayname + ".log")  
              New-MarkdownHelp -Command $cmdletname -OutputFolder $modulefolder
        
              [string]$generatedmd = Join-Path -Path $modulefolder -ChildPath ($cmdletname + ".md")
              if (Test-Path -LiteralPath $generatedmd)
              {
                $Global:ps6docset[$moduledisplayname][$cmdletdisplayname] = "PlatyPS generated"
              }
            } catch {
              $err = $_
              $ex = $err.Exception
              [string[]]$errorinfo = @()
              $errorinfo += "Module         : " + $moduledisplayname
              $errorinfo += "Cmdlet         : " + $cmdletdisplayname
              $errorinfo += "Error message  : " + ($ex.Message)
              $errorinfo += "Error source   : " + ($ex.Source)
              $errorinfo += "Error stack trc: " + ($ex.StackTrace)
              $errorinfo += "PS msg details : " + ($_.PSMessageDetails)
              $errorinfo += "ScriptStackTrace : " + ($_.ScriptStackTrace)
              Write-Warning ([string]::Join("`r`n",$errorinfo))
          
              $Global:ps6docset[$moduledisplayname][$cmdletdisplayname] = "Cmdlet not available in session"
                                                            
              [System.IO.File]::AppendAllLines($logfilename, $errorinfo)                              
            }    
          } 
        }       
    }
}