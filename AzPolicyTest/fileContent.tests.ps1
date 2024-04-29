[CmdletBinding()]
Param (
  [Parameter(Mandatory = $true)][validateScript({ Test-Path $_ })][string]$Path,
  [Parameter(Mandatory = $false)][string[]]$excludePath
)
Write-Verbose "Path: '$Path'"

if ((Get-Item $path).PSIsContainer) {
  Write-Verbose "Specified path '$path' is a directory"
  $gciParams = @{
    Path    = $Path
    Include = '*.json'
    Recurse = $true
  }
  $files = Get-ChildItem @gciParams
  #-Exclude parameter in Get-ChildItem only works on file name, not parent folder name hence it's not used in get-childitem
  if ($excludePath) {
    $excludePath = $excludePath -join "|"
    $files = $files | where-object { $_.FullName -notmatch $excludePath }
  }
} else {
  Write-Verbose "Specified path '$path' is a file"
  $files = Get-Item $path -Include *.json
}

$script:fileCountTestCase = @{
  files = $files
}

$script:jsonFilesTestCases = [System.Collections.ArrayList]@()
foreach ($file in $files) {
  $script:jsonFilesTestCases += @{
    fileName         = (get-item $file).name
    filePath         = (get-item $file).FullName
    fileRelativePath = GetRelativeFilePath -path (get-item $file).FullName
  }
}
Describe "File Existence Test" -Tag 'JsonFileExists' {
  Context "JSON files Should Exist" {
    It 'File count should be greater than 0' -TestCases $script:fileCountTestCase {
      param($files)
      $files.count | should -Not -Be 0
    }
  }
}

Describe "JSON File Syntax Test" -Tag 'JsonSyntax' {
  Context "JSON Syntax Test" {
    It '[<fileRelativePath>] Should be a valid JSON file' -TestCases $script:jsonFilesTestCases {
      param($fileName, $filePath)
      $fileContent = Get-Content -Path $filePath -Raw
      ConvertFrom-Json -InputObject $fileContent -ErrorVariable parseError
      $parseError | Should -Be $Null
    }
  }
}

