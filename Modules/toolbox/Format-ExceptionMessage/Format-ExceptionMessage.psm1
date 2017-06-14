<# 
    .SYNOPSIS
    Provides a formatted string with almost all interesting values an
    exceptions provides, including first level of inner exception.

    .PARAMETER exception
    The exception to report.

#>
function Format-ExceptionMessage()
{
    [CmdletBinding()]
    Param(
      [System.Exception]$exception 
    )

    $errmsg =  "`n`rVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV`n`r`n`r" + `
            $_.Exception.Message + "`n`r" + `
            $_.Exception.HResult + "`n`r" + `
            $_.Exception.StackTrace + "`n`r" + `
            $_.Exception.TargetSite + "`n`r" + `
            $_.Exception.Source + "`n`r" + `
            $_.Exception.Data + "`n`r" 
            $innerException = $_.Exception.InnerException
            if($innerException){
                $errmsg = $errmsg + `
                    "`n`r***********  Inner Exception ************************`n`r" + `
                    "`tInner message    : " + $innerException.Message + "`n`r" + `
                    "`tInner result code: " + $innerException.HResult + "`n`r" + `
                    "`tInner stack trace: " + $innerException.StackTrace + "`n`r" + `
                    "`tInner target site: " + $innerException.TargetSite + "`n`r" + `
                    "`tInner source     : " + $innerException.Source + "`n`r" + `
                    "`tInner data       : " + $innerException.Data + "`n`r" 
            }

    $errmsg = $errmsg + `
            "`n`r^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^`n`r"
    $errmsg
}

