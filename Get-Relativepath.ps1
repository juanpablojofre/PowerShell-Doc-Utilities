function Get-RelativePath {
<#
    .SYNOPSIS


    .DESCRIPTION


    .PARAMETER Directory


    .PARAMETER FilePath


    .Example

 
    .SOURCE


#>
    [CmdletBinding()]
    param(
       [Parameter(Mandatory=$true, Position=0)]
       [string]$Directory,

       [Parameter(Mandatory=$true, Position=1, ValueFromPipelineByPropertyName=$true)]
       [Alias("FullName")]
       [Alias("FileName")]
       [string]$FilePath,

       [switch]$UseWebPathSeparator
    )
    process {
        Write-Verbose "Resolving paths relative to '$Directory'"

        $pathChar = [System.IO.Path]::DirectorySeparatorChar
        $altChar = [System.IO.Path]::AltDirectorySeparatorChar
        if($UseWebPathSeparator){
            $pathChar = [System.IO.Path]::AltDirectorySeparatorChar
            $altChar = [System.IO.Path]::DirectorySeparatorChar
        }

        [string]$relativePath = [string]::Empty;

        [string]$sourceRoot = [System.IO.Path]::GetPathRoot($Directory)
        [string]$source = $Directory

        [string]$fileName = [System.IO.Path]::GetFileName($FilePath)
        [string]$fileDirectory = [System.IO.Path]::GetDirectoryName($FilePath)
        [string]$fileRoot = [System.IO.Path]::GetPathRoot($FilePath)
       
        if ((-not [System.IO.Path]::IsPathRooted($Directory))  -or
            (-not $(Test-Path $Directory -IsValid))) { 
            Write-Error "Directory: $Directory --> not rooted, invalid syntax or contains invalid chars."
            Write-Output $relativePath
            return 
        }


        if ((-not [System.IO.Path]::IsPathRooted($FilePath))  -or
            (-not $(Test-Path $FilePath -IsValid))) { 
            Write-Error "File path: $FilePath --> not rooted, invalid syntax or contains invalid chars."
            Write-Output $relativePath
            return 
        }


        if ($sourceRoot -ne $fileRoot) { 
            Write-Error "File path: $FilePath --> not in $Directory tree."
            Write-Output $relativePath
            return 
        }


        $source = $source.Substring($sourceRoot.Length-1).Replace($altChar, $pathChar)
        $fileDirectory = $fileDirectory.Substring($fileRoot.Length-1).Replace($altChar, $pathChar)

        Write-Verbose "Root:            $sourceRoot"
        Write-Verbose "Source:          $source"
        Write-Verbose "File Directory:  $fileDirectory"
        Write-Verbose "File Path:       $FilePath"


        ## Find closest common ancestor
        Write-Verbose "Finding closest common ancestor"


        if($source -eq $pathChar){
            $sourceAncestors = @([string]::Empty)
        }
        else{
            $sourceAncestors = $source.Split($pathChar)
        }


        if($fileDirectory -eq $pathChar){
            $fileAncestors = @([string]::Empty)
        }
        else{
            $fileAncestors = $fileDirectory.Split($pathChar)
        }

        [int]$nearestAncestor = 0
        while(  ($nearestAncestor -lt $sourceAncestors.Length) -and
                ($nearestAncestor -lt $fileAncestors.Length) -and
                ($sourceAncestors[$nearestAncestor] -eq $fileAncestors[$nearestAncestor])){
            $nearestAncestor++
        }

        $nearestAncestor--

        ## There are 4 possible scenarios to solve
        ## - File is in the Directory folder
        ## - File is in folder under Directory
        ## - File is in ancestor's folder
        ## - File branches off from one ancestor

        ## Checking: File is in the Directory folder
        if( ($($nearestAncestor + 1) -eq  $sourceAncestors.Length) -and
            ($($nearestAncestor + 1) -eq  $fileAncestors.Length)) {
            Write-Output $fileName
            return 
        }

        ## Checking: File is in folder under Directory
        if( $($nearestAncestor + 1) -eq  $sourceAncestors.Length) {
            [string[]]$descendants = @()
            for([int]$i = $($nearestAncestor + 1); $i -lt  $fileAncestors.Length; $i++) { $descendants += $fileAncestors[$i]; }
            $relativePath = $([System.String]::Join($pathChar,$descendants)) + $pathChar + $fileName
            Write-Output $relativePath
            return 
        }

        ## Checking: File is in ancestor's folder
        if( $($nearestAncestor + 1) -eq  $fileAncestors.Length) {
            [string[]]$ascendants = @()
            for([int]$i = $($nearestAncestor + 1); $i -lt  $sourceAncestors.Length; $i++) { $ascendants += ".."; }
            $relativePath = $([System.String]::Join($pathChar,$ascendants)) + $pathChar + $fileName
            Write-Output $relativePath
            return 
        }

        ## File branches off from one ancestor
        [string[]]$ascendants = @()
        for([int]$i = $($nearestAncestor + 1); $i -lt  $sourceAncestors.Length; $i++) { $ascendants += ".."; }

        [string[]]$descendants = @()
        for([int]$i = $($nearestAncestor + 1); $i -lt  $fileAncestors.Length; $i++) { $descendants += $fileAncestors[$i]; }

        $relativePath = $([System.String]::Join($pathChar,$ascendants)) + $pathChar + $([System.String]::Join($pathChar,$descendants)) + $pathChar + $fileName
        Write-Output $relativePath
    }
}
