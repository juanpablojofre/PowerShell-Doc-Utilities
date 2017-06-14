function Get-UnEscapedText () {
    [CmdletBinding()]
    Param (
        [parameter(Mandatory = $true)] [string]$text,
        [parameter(Mandatory = $false)] [char]$escapeChar = '\'
    )

    BEGIN {
        [int]$pos = 0
    }

    END {
        while (($text.Length -gt $pos) -and (($pos = $text.IndexOf($escapeChar, $pos)) -ge 0)) {
            [string]$left = $text.Substring(0, $pos)
            [string]$mid = $text.Substring(($pos + 1), 1)
            [string]$right = [string]::Empty

            switch -CaseSensitive ($mid) {
                '0' { $mid = "`0" ; break}
                'a' { $mid = "`a" ; break}
                'b' { $mid = "`b" ; break}
                'f' { $mid = "`f" ; break}
                'n' { $mid = "`n" ; break}
                'r' { $mid = "`r" ; break}
                't' { $mid = "`t" ; break}
                'v' { $mid = "`v" ; break}
            }

            if (($text.Length) -gt ($pos + 2)) {
                $right = $text.Substring($pos + 2)
            }

            $text = $left + $mid + $right
            $pos++
        }

        $text
    }  
}
