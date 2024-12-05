[CmdletBinding()]
Param (
  [Parameter(Mandatory = $true)]
  [ValidateScript({Test-Path -Path $_})]
  [string] $Path,

  [Parameter(Mandatory = $false)]
  [string[]] $ExcludePath
)
Write-Verbose "Path: '$Path'"

if ((Get-Item $path).PSIsContainer) {
  Write-Verbose "Specified path '$path' is a directory"
  $gciParams = @{
    Path    = $Path
    Include = '*.json', '*.jsonc'
    Recurse = $true
  }
  $files = Get-ChildItem @gciParams
  #-Exclude parameter in Get-ChildItem only works on file name, not parent folder name hence it's not used in get-childitem
  if ($ExcludePath) {
    $ExcludePath = $ExcludePath -join '|'
    $files = $files | Where-Object -FilterScript {$_.FullName -notmatch $ExcludePath}
  }
} else {
  Write-Verbose "Specified path '$path' is a file"
  $files = Get-Item $path -Include '*.json', '*.jsonc'
}

$script:fileCountTestCase = @{
  files = $files
}

$script:jsonFilesTestCases = [System.Collections.ArrayList]@()
foreach ($file in $files) {
  $script:jsonFilesTestCases += @{
    fileName         = (Get-Item -Path $file).name
    filePath         = (Get-Item -Path $file).FullName
    fileRelativePath = GetRelativeFilePath -path (Get-Item -Path $file).FullName
  }
}
Describe 'File Existence Test' -Tag 'JsonFileExists' {
  Context 'JSON files Should Exist' {
    It 'File count should be greater than 0' -TestCases $script:fileCountTestCase {
      param(
        $files
      )
      $files.count | should -Not -Be 0
    }
  }
}

Describe 'JSON File Syntax Test' -Tag 'JsonSyntax' {
  Context 'JSON Syntax Test' {
    It '[<fileRelativePath>] Should be a valid JSON file' -TestCases $script:jsonFilesTestCases {
      param(
        [string] $filePath
      )
      $fileContent = Get-Content -Path $filePath -Raw
      ConvertFrom-Json -InputObject $fileContent -ErrorVariable parseError
      $parseError | Should -Be $Null
    }
  }
}
