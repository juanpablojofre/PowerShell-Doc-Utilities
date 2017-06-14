function Get-Int2Binary () {
      [CmdletBinding()]
  Param (
    [parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] $number
  )

  END{
    [System.Convert]::ToString($number,2)
  }

}