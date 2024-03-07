[CmdletBinding()]
Param (
  [Parameter(Mandatory = $true)][validateScript({ Test-Path $_ })][string]$Path
)
Write-Verbose "Path: '$Path'"
#variables
$TestName = "Policy Set Definition Syntax Test"

#Get JSON files
if ((Get-Item $path).PSIsContainer) {
  Write-Verbose "Specified path '$path' is a directory"
  $files = Get-ChildItem $Path -Include *.json -Recurse
} else {
  Write-Verbose "Specified path '$path' is a file"
  $files = Get-Item $path -Include *.json
}

Foreach ($file in $files) {
  Write-Verbose "Test '$file'"
  Describe "$TestName for '$file'" {

    $fileContent = Get-Content -Path $file -Raw
    $json = ConvertFrom-Json -InputObject $fileContent -ErrorAction SilentlyContinue
    Context "Required Top-Level Elements Test" {
      It "Should contain top-level element - name" {
        $json.PSobject.Properties.name -match 'name' | Should Not Be $Null
      }
      It "Should contain top-level element - properties" {
        $json.PSobject.Properties.name -match 'properties' | Should Not Be $Null
      }
    }
    Context "Policy Set Definition Elements Value Test" {
      It "Name value must not be null" {
        $json.name.length | Should BeGreaterThan 0
      }
      It "Name value must not be longer than 64 characters" {
        $json.name.length | Should BeLessOrEqual 64
      }
      It "Name value must not contain spaces" {
        $json.name -match ' ' | Should Be $false
      }
    }
    Context "Policy Definition Properties Value Test" {
      It "Properties must contain 'displayName' element" {
        $json.properties.PSobject.Properties.name -match 'displayName' | Should Not Be $Null
      }
      It "Properties must contain 'description' element" {
        $json.properties.PSobject.Properties.name -match 'description' | Should Not Be $Null
      }
      It "Properties must contain 'metadata' element" {
        $json.properties.PSobject.Properties.name -match 'metadata' | Should Not Be $Null
      }
      It "Properties must contain 'parameters' element" {
        $json.properties.PSobject.Properties.name -match 'parameters' | Should Not Be $Null
      }
      It "Properties must contain 'policyDefinitions' element" {
        $json.properties.PSobject.Properties.name -match 'policyDefinitions' | Should Not Be $Null
      }
      It "'policyDefinitions' element must contain at least one item" {
        $json.properties.policyDefinitions.count | Should -BeGreaterThan 0
      }
      It "'DisplayName' value must not be blank" {
        $json.properties.displayName.length | Should BeGreaterThan 0
      }
      It "'Description' value must not be blank" {
        $json.properties.description.length | Should BeGreaterThan 0
      }
      It "Must contain 'Category' metadata" {
        $json.properties.metadata.category.length | Should BeGreaterThan 0
      }
    }
    Context "policy Definitions Test" {
      $i = 0
      Foreach ($policyDefinition in $json.properties.policyDefinitions) {
        $i++
        It "Policy Definition #$i must contain 'policyDefinitionId' element" {
          $policyDefinition.PSobject.properties.name -match 'policyDefinitionId' | Should Not Be $null
        }
        It "'policyDefinitionId' in Policy Definition #$i must contain value" {
          $policyDefinition.policyDefinitionId.length | Should BeGreaterThan 0
        }
      }
    }
  }
}