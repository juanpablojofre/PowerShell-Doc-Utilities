function Get-EncodingFromLabel{
  [CmdletBinding()]
  Param (
    [ValidateSet("UTF8BOM", "UTF8NOBOM", 
                 "ASCII", "UTF7",
                 "UTF16BigEndian","UTF16LittleEndian","Unicode",
                 "UTF32BigEndian","UTF32LittleEndian")]
    [string] $encode = "UTF8NOBOM"
  )
  END{
    switch ($encode) {
      "UTF8BOM" { (New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $true); break }
      "UTF8NOBOM" { (New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false); break }
      "ASCII" { (New-Object -TypeName System.Text.ASCIIEncoding); break }
      "UTF7" { (New-Object -TypeName System.Text.UTF7Encoding); break }
      "UTF16BigEndian" { (New-Object -TypeName System.Text.UnicodeEncoding -ArgumentList $true,$false); break }
      "UTF16LittleEndian" { (New-Object -TypeName System.Text.UnicodeEncoding -ArgumentList $false,$false); break }
      "Unicode" { (New-Object -TypeName System.Text.UnicodeEncoding -ArgumentList $false,$false); break }
      "UTF32BigEndian" { (New-Object -TypeName System.Text.UTF32Encoding -ArgumentList $true,$false); break }
      "UTF32LittleEndian" { (New-Object -TypeName System.Text.UTF32Encoding -ArgumentList $false,$false); break }
      Default { (New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false) }
    }
  }
}