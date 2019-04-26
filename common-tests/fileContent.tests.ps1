[CmdletBinding()]
Param (
	[Parameter(Mandatory=$true)][validateScript({Test-Path $_})][string]$Path
)
Write-Verbose "Path: '$Path'"
$TestName = "File Content Test"

if ((Get-Item $path).PSIsContainer)
{
	Write-Verbose "Specified path '$path' is a directory"
	$files = Get-ChildItem $Path -Include *.json -Recurse
} else {
	Write-Verbose "Specified path '$path' is a file"
  $files = Get-Item $path -Include *.json
}
Describe $TestName {
	Context "JSON files Should Exist" {
    It 'File count should be greater than 0' {
			$files.count | should Not Be 0
			}
	}

	Foreach ($file in $files)
	{
		Write-Verbose "Test '$file'"
		Context "'$file' JSON Syntax Test" {
			It 'Should be a valid JSON file' {
				$fileContent = Get-Content -Path $file -Raw
				ConvertFrom-Json -InputObject $fileContent -ErrorVariable parseError
				$parseError | Should Be $Null
			}
		}
	}
}
	