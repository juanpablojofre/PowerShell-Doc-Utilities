#
# Module manifest for module 'AuthoringTools'
#
# Generated by: JuanPablo Jofre
#
# Generated on: 2/15/2017
#

@{

# Script module or binary module file associated with this manifest.
RootModule = './AuthoringTools.psm1'

# Version number of this module.
ModuleVersion = '1.0'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = 'b41c92cf-bc0d-4aff-a330-508eff27b9ac'

# Author of this module
Author = 'JuanPablo Jofre'

# Company or vendor of this module
CompanyName = 'Microsoft Corporation'

# Copyright statement for this module
Copyright = '(c) 2017 Microsoft Corporation. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Markdown authoring tools'

# Minimum version of the Windows PowerShell engine required by this module
# PowerShellVersion = ''

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @(
    "toolbox",
    "CommonClasses"
)

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
NestedModules = @(
      "./Compare-MDCollection"
    , "./Get-AssetList" 
    , "./Get-BrokenReferencesInMDCollection"
    , "./Get-EmptyLinksInMdDocument"
    , "./Get-EmptyTopics"
    , "./Get-MDHeadingReferences"
    , "./Get-MDReferencesFromDocument"
    , "./Get-MetadataTagsInMD"
    , "./Get-OrphanMdDocuments"
    , "./Get-ShortDescription"
    , "./Restore-BrokenReferencesInMDCollection"
    , "./Test-MDReference"
    , "./Update-Metadata"
    , "./Update-MetadataInTopics"
    , "./Update-ToC"
    , "./Write-DocumentsForTOC"
)

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @(
      "Compare-MDCollection"
    , "Get-AssetList" 
    , "Get-BrokenReferencesInMDCollection"
    , "Get-EmptyLinksInMdDocument"
    , "Get-EmptyTopics"
    , "Get-MDHeadingReferences"
    , "Get-MDReferencesFromDocument"
    , "Get-MetadataTagsInMD"
    , "Get-OrphanMdDocuments"
    , "Get-ShortDescription"
    , "Restore-BrokenReferencesInMDCollection"
    , "Test-MDReference"
    , "Update-Metadata"
    , "Update-MetadataInTopics"
    , "Update-ToC"
    , "Write-DocumentsForTOC"
)

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
# CmdletsToExport = '*'

# Variables to export from this module
# VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
# AliasesToExport = '*'

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
ModuleList = @(
      "./Compare-MDCollection"
    , "./Get-AssetList" 
    , "./Get-BrokenReferencesInMDCollection"
    , "./Get-EmptyLinksInMdDocument"
    , "./Get-EmptyTopics"
    , "./Get-MDHeadingReferences"
    , "./Get-MDReferencesFromDocument"
    , "./Get-MetadataTagsInMD"
    , "./Get-OrphanMdDocuments"
    , "./Get-ShortDescription"
    , "./Restore-BrokenReferencesInMDCollection"
    , "./Test-MDReference"
    , "./Update-Metadata"
    , "./Update-MetadataInTopics"
    , "./Update-ToC"
    , "./Write-DocumentsForTOC"
)

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        # Tags = @()

        # A URL to the license for this module.
        # LicenseUri = ''

        # A URL to the main website for this project.
        # ProjectUri = ''

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        # ReleaseNotes = ''

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

