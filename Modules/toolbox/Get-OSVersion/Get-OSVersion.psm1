function Get-OSVersion {
  [CmdletBinding()]
  param()

  BEGIN {
    [string]$Global:OsVersion = [string]::Empty  
  }
  
  PROCESS {
  }
  
  END {
    if("6" -gt $PSVersionTable["PSVersion"]) {
      $Global:OsVersion = [Environment]::OSVersion.VersionString
    }
    else {
      if($IsLinux){
        try{
          ## I'm assuming here this is Ubuntu standard version, that comes with 'lsb_' already installed
          ## For redhat/Centos this might not work, haven't tested them
          $Global:OsVersion = (lsb_release -d).Split(":")[1].Trim()
        }
        catch{
          $Global:OsVersion = uname -v
        }
      }
      elseif($IsOSX){
        $productname = sw_vers -productName
        $productversion = sw_vers -productVersion
        $Global:OsVersion = $productname + " " + $productversion
      }
      elseif($IsWindows){
        $Global:OsVersion = [Environment]::OSVersion.VersionString
      }
      else{
        $Global:OsVersion = "Undefined"
      }
    }
      
    $Global:OsVersion
  }
}
