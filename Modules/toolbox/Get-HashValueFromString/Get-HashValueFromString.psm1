function Get-HashValueFromString {
  [CmdletBinding()]
  Param (
    [parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [String] $string
    ,  [parameter(Mandatory=$false)] 
       [ValidateSet("SHA1", "SHA256", "SHA384", "SHA512", "MACTripleDES", "MD5", "RIPEMD160")] 
       [String] $algorithm = "SHA256"
  )

  END{
    [byte[]]$testbytes = [System.Text.UnicodeEncoding]::Unicode.GetBytes($string)

    [System.IO.Stream]$memorystream = [System.IO.MemoryStream]::new($testbytes)
    $hashfromstream = Get-FileHash -InputStream $memorystream -Algorithm $algorithm
    $hashfromstream.Hash.ToString()  
  }
}
