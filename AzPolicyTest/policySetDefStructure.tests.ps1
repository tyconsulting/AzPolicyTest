[CmdletBinding()]
Param (
  [Parameter(Mandatory = $true)][validateScript({ Test-Path $_ })][string]$Path
)
Write-Verbose "Path: '$Path'"
#variables
$TestName = "Policy Set Definition Syntax Test"

$global:validParameterTypes = @(
  'string',
  'array',
  'object',
  'boolean',
  'integer',
  'float',
  'datetime'
)

#Get JSON files
if ((Get-Item $path).PSIsContainer) {
  Write-Verbose "Specified path '$path' is a directory"
  $files = Get-ChildItem $Path -Include *.json -Recurse
} else {
  Write-Verbose "Specified path '$path' is a file"
  $files = Get-Item $path -Include *.json
}

Foreach ($file in $files) {
  Write-Verbose "Test '$file'" -verbose
  $fileName = (get-item $file).name
  $fileFullName = (get-item $file).FullName
  $json = ConvertFrom-Json -InputObject (Get-Content -Path $file -Raw) -ErrorAction SilentlyContinue
  $testCase = @{
    fileName = $fileName
    json     = $json
  }
  Describe "[$fileFullName]: $TestName" -Tag "policyDefSyntax" {

    Context "Required Top-Level Elements Test" -Tag "TopLevelElements" {

      It "Should contain top-level element - name" -TestCases $testCase {
        param(
          [object] $json
        )
        $json.PSobject.Properties.name -match 'name' | Should -Not -Be $Null
      }

      It "Should contain top-level element - properties" -TestCases $testCase {
        param(
          [object] $json
        )
        $json.PSobject.Properties.name -match 'properties' | Should -Not -Be $Null
      }
    }

    Context "Policy Set Definition Elements Value Test" -Tag 'PolicySetElements' {

      It "Name value must not be null" -TestCases $testCase {
        param(
          [object] $json
        )
        $json.name.length | Should -BeGreaterThan 0
      }

      It "Name value must not be longer than 64 characters" -TestCases $testCase -Tag 'NameLength' {
        param(
          [object] $json
        )
        $json.name.length | Should -BeLessOrEqual 64
      }

      It "Name value must not contain spaces" -TestCases $testCase {
        param(
          [object] $json
        )
        $json.name -match ' ' | Should -Be $false
      }

      It "Name value must not contain forbidden characters" -TestCases $testCase -Tag 'NameForbiddenCharacters' {
        param(
          [object] $json
        )
        $json.name -match '[<>*%&:\\?.+\/]' | Should -Be $false
      }
    }

    Context "Policy Definition Properties Value Test" -Tag 'PolicySetProperties' {

      It "Properties must contain 'displayName' element" -TestCases $testCase -Tag 'DisplayNameExists' {
        param(
          [object] $json
        )
        $json.properties.PSobject.Properties.name -match 'displayName' | Should -Not -Be $Null
      }

      It "'DisplayName' value must not be longer than 128 characters" -TestCases $testCase -Tag 'DisplayNameLength' {
        param(
          [object] $json
        )
        $json.properties.displayName.length | Should -BeLessOrEqual 128
      }

      It "Properties must contain 'description' element" -TestCases $testCase -Tag 'DescriptionExists' {
        param(
          [object] $json
        )
        $json.properties.PSobject.Properties.name -match 'description' | Should -Not -Be $Null
      }

      It "Properties must contain 'metadata' element" -TestCases $testCase -Tag 'MetadataExists' {
        param(
          [object] $json
        )
        $json.properties.PSobject.Properties.name -match 'metadata' | Should -Not -Be $Null
      }

      It "Properties must contain 'parameters' element" -TestCases $testCase - Tag 'ParametersExists' {
        param(
          [object] $json
        )
        $json.properties.PSobject.Properties.name -match 'parameters' | Should -Not -Be $Null
      }

      It "'parameters' element must contain at least one item" -TestCases $testCase -Tag "ParametersCount" {
        param(
          [object] $json
        )
        $json.properties.parameters.PSObject.Properties.count | Should -BeGreaterThan 0
      }

      It "Properties must contain 'policyDefinitions' element" -TestCases $testCase -Tag 'PolicyDefinitionsExists'{
        param(
          [object] $json
        )
        $json.properties.PSobject.Properties.name -match 'policyDefinitions' | Should -Not -Be $Null
      }

      It "'policyDefinitions' element must contain at least one item" -TestCases $testCase -Tag 'PolicyDefinitionsCount' {
        param(
          [object] $json
        )
        $json.properties.policyDefinitions.count | Should -BeGreaterThan 0
      }

      It "Properties must contain 'policyDefinitionGroups' element" -TestCases $testCase -Tag 'PolicyDefinitionGroupsExists'{
        param(
          [object] $json
        )
        $json.properties.PSobject.Properties.name -match 'policyDefinitionGroups' | Should -Not -Be $Null
      }

      It "'policyDefinitionGroups' element must contain at least one item" -TestCases $testCase -Tag 'PolicyDefinitionGroupsCount'{
        param(
          [object] $json
        )
        $json.properties.policyDefinitionGroups.count | Should -BeGreaterThan 0
      }

      It "'DisplayName' value must not be blank" -TestCases $testCase -Tag 'DisplayNameNotBlank'{
        param(
          [object] $json
        )
        $json.properties.displayName.length | Should -BeGreaterThan 0
      }

      It "'Description' value must not be blank" -TestCases $testCase -Tag 'DescriptionNotBlank'{
        param(
          [object] $json
        )
        $json.properties.description.length | Should -BeGreaterThan 0
      }

      It "Must contain 'Category' metadata" -TestCases $testCase {
        param(
          [object] $json
        )
        $json.properties.metadata.category.length | Should -BeGreaterThan 0
      }

      It "Must contain 'Version' metadata" -TestCases $testCase -Tag 'VersionExists' {
        param(
          [object] $json
        )
        $json.properties.metadata.version.length | Should -BeGreaterThan 0
      }

      It "'Version' metadata value must be a valid semantic version" -TestCases $testCase -Tag 'ValidSemanticVersion' {
        param(
          [object] $json
        )
        $json.properties.metadata.version -match '^\d+\.\d+.\d+$' | Should -Be $true
      }
    }

    Context "Parameters Tests" -Tag 'Parameters'{
      Foreach ($parameterName in $json.properties.parameters.PSObject.Properties.Name) {
        $parameterConfig = $json.properties.parameters.$parameterName
        $parameterTestCase = @{
          parameterName = $parameterName
          parameterConfig = $parameterConfig
        }

        It "Parameter [<parameterName>] must contain 'type' element" -TestCases $parameterTestCase -Tag 'ParameterTypeExists' {
          param(
            [string] $parameterName,
            [object] $parameterConfig
          )
          $parameterConfig.PSobject.Properties.name -match 'type' | Should -Not -Be $null
        }

        It "Parameter [<parameterName>] must have a valid value for the 'type' element" -TestCases $parameterTestCase -Tag 'ParameterTypeValid' {
          param(
            [string] $parameterName,
            [object] $parameterConfig
          )
          $global:validParameterTypes -contains $parameterConfig.type.tolower() | Should -Be $true
        }

        It "Parameter [<parameterName>] metadata must contain 'displayName' element" -TestCases $parameterTestCase -Tag 'ParameterDisplayNameExists' {
          param(
            [string] $parameterName,
            [object] $parameterConfig
          )
          $parameterConfig.metadata.PSobject.Properties.name -match 'displayName' | Should -Not -Be $null
        }

        It "Parameter [<parameterName>] metadata must contain 'description' element" -TestCases $parameterTestCase -Tag 'ParameterDescriptionExists' {
          param(
            [string] $parameterName,
            [object] $parameterConfig
          )
          $parameterConfig.metadata.PSobject.Properties.name -match 'description' | Should -Not -Be $null
        }
      }
    }

    Context "Policy Definitions Test" -Tag 'PolicyDefinitions' {
      $i = 0
      Foreach ($policyDefinition in $json.properties.policyDefinitions) {
        $i++
        $policyDefinitionTestCase = @{
          policyDefinition = $policyDefinition
        }

        It "Policy Definition #$i must contain 'policyDefinitionId' element" -TestCases $policyDefinitionTestCase -Tag 'PolicyDefinitionIdExists' {
          param(
            [object] $policyDefinition
          )
          $policyDefinition.PSobject.properties.name -match 'policyDefinitionId' | Should -Not -Be $null
        }

        It "'policyDefinitionId' in Policy Definition #$i must contain value" -TestCases $policyDefinitionTestCase -Tag 'PolicyDefinitionIdNotEmpty' {
          param(
            [object] $policyDefinition
          )
          $policyDefinition.policyDefinitionId.length | Should -BeGreaterThan 0
        }

        It "Policy Definition #$i must contain 'policyDefinitionReferenceId' element" -TestCases $policyDefinitionTestCase -Tag 'policyDefinitionReferenceIdExists' {
          param(
            [object] $policyDefinition
          )
          $policyDefinition.PSobject.properties.name -match 'policyDefinitionReferenceId' | Should -Not -Be $null
        }

        It "'policyDefinitionReferenceId' in Policy Definition #$i must contain value" -TestCases $policyDefinitionTestCase -Tag 'policyDefinitionReferenceIdNotEmpty' {
          param(
            [object] $policyDefinition
          )
          $policyDefinition.policyDefinitionReferenceId.length | Should -BeGreaterThan 0
        }

        It "Policy Definition #$i must contain 'parameters' element" -TestCases $policyDefinitionTestCase -Tag 'PolicyDefinitionParameterExists' {
          param(
            [object] $policyDefinition
          )
          $policyDefinition.PSobject.properties.name -match 'parameters' | Should -Not -Be $null
        }
        It "'parameters' in Policy Definition #$i must contain at least one item" -TestCases $policyDefinitionTestCase -Tag 'PolicyDefinitionParameterNotEmpty' {
          param(
            [object] $policyDefinition
          )
          $policyDefinition.parameters.PSObject.Properties.count | Should -BeGreaterThan 0
        }

        It "Policy Definition #$i must contain 'groupNames' element" -TestCases $policyDefinitionTestCase -Tag 'PolicyDefinitionGroupNamesExists' {
          param(
            [object] $policyDefinition
          )
          $policyDefinition.PSobject.properties.name -match 'groupNames' | Should -Not -Be $null
        }

        It "'groupNames' in Policy Definition #$i must contain at least one item" -TestCases $policyDefinitionTestCase -Tag 'PolicyDefinitionGroupNamesNotEmpty' {
          param(
            [object] $policyDefinition
          )
          $policyDefinition.groupNames.count | Should -BeGreaterThan 0
        }
      }
    }
  }
}