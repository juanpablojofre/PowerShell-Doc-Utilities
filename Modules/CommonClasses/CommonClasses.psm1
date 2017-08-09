enum MDReferenceStatus {
    NotTested
    Failed
    Passed
    Restored
}

class MDReference {
    [ValidateNotNullOrEmpty()][string]$DocumentPath
    [int]$LineNumber = 0
    [string]$Text 
    [string]$Link 
    [string]$OriginalReference 
    [MDReferenceStatus]$ReferenceStatus = [MDReferenceStatus]::NotTested

    MDReference([string]$DocumentPath, 
                [int]$LineNumber, 
                [string]$Text, 
                [string]$Link,
                [string]$OriginalReference,
                [MDReferenceStatus]$ReferenceStatus){
        $this.DocumentPath = $DocumentPath
        $this.LineNumber = $LineNumber
        $this.Text = $Text
        $this.Link = $Link
        $this.OriginalReference = $OriginalReference
        $this.ReferenceStatus = $ReferenceStatus
    }

    MDReference([string]$DocumentPath, 
                [string]$Text, 
                [string]$Link,
                [string]$OriginalReference){
        $this.DocumentPath = $DocumentPath
        $this.Text = $Text
        $this.Link = $Link
    }

    [string]GetExternalLink() { return $this.Link.Split('#')[0]}
    [string]GetInternalLink() { return $this.Link.Split('#')[1]}
    [string]GetNewReference() { return ("[{0}]({1})" -f $this.Text, $this.Link)}

}

