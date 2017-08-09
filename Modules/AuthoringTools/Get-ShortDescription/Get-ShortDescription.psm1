function Get-ShortDescription {
  [CmdletBinding()]
  Param (
    [parameter(ValueFromPipeline=$true,ParameterSetName="FromFile")] 
    [ValidateNotNullOrEmpty()]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf } )]
    [string[]] $aboutPath,
    [parameter(ValueFromPipeline=$false,ParameterSetName="FromContent")] 
    [ValidateNotNullOrEmpty()]
    [string] $content,
    [parameter(ValueFromPipeline=$false,ParameterSetName="FromFile")] 
    [parameter(ValueFromPipeline=$false,ParameterSetName="FromContent")] 
    [ValidateSet("UTF8BOM", "UTF8NOBOM", 
                 "ASCII", "UTF7",
                 "UTF16BigEndian","UTF16LittleEndian","Unicode",
                 "UTF32BigEndian","UTF32LittleEndian")]
    [string] $encode = "UTF8NOBOM"
  )


  PROCESS{
    [System.Text.Encoding]$encoding = Get-EncodingFromLabel -encode $encode

    if($aboutPath){
      $content = [System.IO.File]::ReadAllText($aboutPath, $encoding)
    }

    [string]$ShortDescriptionPattern = '\n#+\s*SHORT\s+DESCRIPTION\s*(\r?\n)+' +
                                       '(?<sd>.+?)\r?\n(\r?\n|#+)' 
    
    [System.Text.RegularExpressions.RegexOptions]$RegexOptions = [System.Text.RegularExpressions.RegexOptions]::Singleline + [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    [System.TimeSpan]$timeout = [System.TimeSpan]::FromMilliseconds(20000)
    $ShortDescriptionRegex = [System.Text.RegularExpressions.Regex]::new($ShortDescriptionPattern, $RegexOptions, $timeout)
    $m = $ShortDescriptionRegex.Match($content)
    if ($m.Success) {
      $m.Groups["sd"].Value.ToString().Trim();
    }
    else {
      [string]::Empty
    }
    
  }
}

