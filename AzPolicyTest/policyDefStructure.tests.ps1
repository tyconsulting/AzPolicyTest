#Requires -Version 7

[CmdletBinding()]
Param (
  [Parameter(Mandatory = $true)][validateScript({ Test-Path $_ })][string]$Path
)
Write-Verbose "Path: '$Path'"

function GetPolicyEffect {
  param(
    [object] $policyObject
  )
  $parameterRegex = "^\[{1,2}parameters\(\'(\S+)\'\)\]$"
  $effect = $policyObject.properties.policyRule.then.effect
  #check if the effect is a parameterised value
  if ($effect -imatch $parameterRegex) {
    $effectParameterName = $matches[1]
    $policyEffectAllowedValues = $policyObject.properties.parameters.$effectParameterName.allowedValues
    $policyEffectDefaultValue = $policyObject.properties.parameters.$effectParameterName.defaultValue
    $effects = @()
    if ($policyEffectAllowedValues) {
      $effects += $policyEffectAllowedValues
    } else {
      $effects += $policyEffectDefaultValue
    }
    $result = @{
      effects            = $effects
      defaultEffectValue = $policyEffectDefaultValue
      isHardCoded        = $false
    }
  } else {
    $result = @{
      effects            = @($effect)
      defaultEffectValue = $null
      isHardCoded        = $true
    }
  }
  $result
}

#variables
$global:validEffects = [System.Collections.ArrayList]@(
  'Modify',
  'Deny',
  'Audit',
  'Append',
  'AuditIfNotExists',
  'DeployIfNotExists',
  'Disabled',
  'AddToNetworkGroup',
  'DenyAction',
  'Manual',
  'Mutate'
)

$global:validModes = [System.Collections.ArrayList]@(
  'All',
  'Indexed',
  'Microsoft.KeyVault.Data',
  'Microsoft.Kubernetes.Data',
  'Microsoft.Network.Data',
  'Microsoft.ManagedHSM.Data',
  'Microsoft.DataFactory.Data',
  'Microsoft.MachineLearningServices.v2.Data'
)

$global:modifyConflictEffectsValidValues = [System.Collections.ArrayList]@(
  'audit',
  'deny',
  'disabled'
)

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

#Policy Definition Tests
foreach ($file in $files) {
  Write-Verbose "Test '$file'" -verbose
  $fileName = (get-item $file).name
  $fileFullName = (get-item $file).FullName
  $fileRelativePath = GetRelativeFilePath -path $fileFullName
  #check if the file is inside a git repository
  $json = ConvertFrom-Json -InputObject (Get-Content -Path $file -Raw) -ErrorAction SilentlyContinue
  $testCase = @{
    fileName         = $fileName
    json             = $json
    policyEffect     = GetPolicyEffect -policyObject $json
    fileRelativePath = $fileRelativePath
  }

  Describe "[$fileRelativePath]: Policy Definition Syntax Test" -Tag "policyDefSyntax" {

    Context "Required Top-Level Elements Test" -Tag "TopLevelElements" {

      It "Should contain top-level element name" -TestCases $testCase -Tag 'NameExists' {
        param(
          [object] $json
        )
        $json.PSobject.Properties.name -match 'name' | Should -Not -Be $Null
      }

      It "Should contain top-level element - properties" -TestCases $testCase -Tag 'PropertiesExists' {
        param(
          [object] $json
        )
        $json.PSobject.Properties.name -match 'properties' | Should -Not -Be $Null
      }
    }

    Context "Policy Definition Elements Value Test" -Tag 'PolicyElements' {

      It "Name value must not be null" -TestCases $testCase {
        param(
          [object] $json
        )
        $json.name.length | Should -BeGreaterThan 0
      }

      It "Name value must not be longer than 64 characters" -TestCases $testCase {
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

      It "Name value must not contain forbidden characters" -TestCases $testCase {
        param(
          [object] $json
        )
        $json.name -match '[<>*%&:\\?.+\/]' | Should -Be $false
      }

    }

    Context "Policy Definition Properties Value Test" -Tag 'PolicyProperties' {

      It "Properties must contain 'displayName' element" -TestCases $testCase {
        param(
          [object] $json
        )
        $json.properties.PSobject.Properties.name -match 'displayName' | Should -Not -Be $Null
      }

      It "'DisplayName' value must not be longer than 128 characters" -TestCases $testCase {
        param(
          [object] $json
        )
        $json.properties.displayName.length | Should -BeLessOrEqual 128
      }

      It "Properties must contain 'description' element" -TestCases $testCase {
        param(
          [object] $json
        )
        $json.properties.PSobject.Properties.name -match 'description' | Should -Not -Be $Null
      }

      It "Properties must contain 'metadata' element" -TestCases $testCase {
        param(
          [object] $json
        )
        $json.properties.PSobject.Properties.name -match 'metadata' | Should -Not -Be $Null
      }

      It "Properties must contain 'mode' element" -TestCases $testCase {
        param(
          [object] $json
        )
        $json.properties.PSobject.Properties.name -match 'mode' | Should -Not -Be $Null
      }

      It "Policy mode must have a valid value." -TestCases $testCase {
        param(
          [object] $json
        )
        $global:validModes.contains($json.properties.mode) | Should -Be $true
      }

      It "Properties must contain 'parameters' element" -TestCases $testCase {
        param(
          [object] $json
        )
        $json.properties.PSobject.Properties.name -match 'parameters' | Should -Not -Be $Null
      }

      It "'parameters' element must contain at least one item" -TestCases $testCase {
        param(
          [object] $json
        )
        $json.properties.parameters.PSObject.Properties.count | Should -BeGreaterThan 0
      }

      It "Properties must contain 'policyRule' element" -TestCases $testCase {
        param(
          [object] $json
        )
        $json.properties.PSobject.Properties.name -match 'policyRule' | Should -Not -Be $Null
      }

      It "'DisplayName' value must not be blank" -TestCases $testCase {
        param(
          [object] $json
        )
        $json.properties.displayName.length | Should -BeGreaterThan 0
      }

      It "'Description' value must not be blank" -TestCases $testCase {
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

      It "Must contain 'Version' metadata" -TestCases $testCase {
        param(
          [object] $json
        )
        $json.properties.metadata.version.length | Should -BeGreaterThan 0
      }

      It "'Version' metadata value must be a valid semantic version" -TestCases $testCase {
        param(
          [object] $json
        )
        $json.properties.metadata.version -match '^\d+\.\d+.\d+$' | Should -Be $true
      }
    }

    Context "Parameters Tests" -Tag 'Parameters' {
      Foreach ($parameterName in $json.properties.parameters.PSObject.Properties.Name) {
        $parameterConfig = $json.properties.parameters.$parameterName
        $parameterTestCase = @{
          parameterName   = $parameterName
          parameterConfig = $parameterConfig
        }

        It "Parameter [<parameterName>] must contain 'type' element" -TestCases $parameterTestCase {
          param(
            [string] $parameterName,
            [object] $parameterConfig
          )
          $parameterConfig.PSobject.Properties.name -match 'type' | Should -Not -Be $null
        }

        It "Parameter [<parameterName>] must have a valid value for the 'type' element" -TestCases $parameterTestCase {
          param(
            [string] $parameterName,
            [object] $parameterConfig
          )
          $global:validParameterTypes -contains $parameterConfig.type.tolower() | Should -Be $true
        }

        It "Parameter [<parameterName>] metadata must contain 'displayName' element" -TestCases $parameterTestCase {
          param(
            [string] $parameterName,
            [object] $parameterConfig
          )
          $parameterConfig.metadata.PSobject.Properties.name -match 'displayName' | Should -Not -Be $null
        }

        It "Parameter [<parameterName>] metadata must contain 'description' element" -TestCases $parameterTestCase {
          param(
            [string] $parameterName,
            [object] $parameterConfig
          )
          $parameterConfig.metadata.PSobject.Properties.name -match 'description' | Should -Not -Be $null
        }
      }
    }

    Context "Policy Rule Test" -Tag 'PolicyRule' {
      It "Policy Rule must contain 'if' element" -TestCases $testCase {
        param(
          [object] $json
        )
        $json.properties.policyRule.PSobject.Properties.name -match 'if' | Should -Not -Be $Null
      }
      It "Policy Rule must contain 'then' element" -TestCases $testCase {
        param(
          [object] $json
        )
        $json.properties.policyRule.PSobject.Properties.name -match 'then' | Should -Not -Be $Null
      }
    }

    Context "Policy Effect Test" -Tag 'PolicyEffect' {
      It "Policy Rule should have parameterised effect" -TestCases $testCase {
        param(
          [object] $json,
          [hashtable]$policyEffect
        )
        $policyEffect.isHardCoded | Should -Be $false
      }
      It "Policy Rule parameterised effect should contain 'Disabled' effect" -TestCases ($script:testCases | where-Object { $_.policyEffect.isHardCoded -eq $false }) {
        param(
          [object] $json,
          [hashtable]$policyEffect
        )
        $policyEffect.effects -contains 'Disabled' | Should -Be $true
      }
      It "Policy Rule parameterised effect should have a default value" -TestCases ($script:testCases | where-Object { $_.policyEffect.isHardCoded -eq $false }) {
        param(
          [object] $json,
          [hashtable]$policyEffect
        )
        $policyEffect.defaultEffectValue | Should -Not -Be $null
      }
      It "Policy Rule must use a valid effect" -TestCases $testCase {
        param(
          [object] $json,
          [hashtable]$policyEffect
        )
        $validEffectCount = 0
        foreach ($item in $policyEffect.effects) {
          if ($global:validEffects.Contains($item)) {
            $validEffectCount++
          }
        }
        $validEffectCount  | Should -BeGreaterThan 0
      }

      It "Policy rule with 'Deny' effect must also support 'Audit' Effect" -TestCases ($script:testCases | where-Object { $_.policyEffect.effects -contains 'Deny' }) {
        param(
          [object] $json
        )
        $policyEffect.effects -contains 'Audit' | Should -Be $true
      }

      It "Policy rule with 'Audit' effect must also support 'Deny' Effect" -TestCases ($script:testCases | where-Object { $_.policyEffect.effects -contains 'Audit' }) {
        param(
          [object] $json
        )
        $policyEffect.effects -contains 'Deny' | Should -Be $true
      }
    }

    Context "DeployIfNotExists Effect Policy Configuration Test" -Tag 'DeployIfNotExistsConfig' {
      It "Policy rule 'then' element Must contain a 'details' element" -TestCases ($script:testCases | where-Object { $_.policyEffect.effects -contains 'DeployIfNotExists' }) {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.PSobject.Properties.name -match 'details' | Should -Not -Be $Null
      }
      It "Policy rule must contain a embedded 'deployment' element" -TestCases ($script:testCases | where-Object { $_.policyEffect.effects -contains 'DeployIfNotExists' }) {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.PSobject.Properties.name -match 'deployment' | Should -Not -Be $Null
      }
      It "Deployment mode for the policy rule must be 'incremental'" -TestCases ($script:testCases | where-Object { $_.policyEffect.effects -contains 'DeployIfNotExists' }) {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.deployment.properties.mode -match 'incremental' | Should -Not -Be $Null
      }
      It "Policy rule must contain a 'evaluationDelay' element" -TestCases ($script:testCases | where-Object { $_.policyEffect.effects -contains 'DeployIfNotExists' }) {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.PSobject.Properties.name -match 'evaluationDelay' | Should -Not -Be $Null
      }
      It "Policy rule must contain a 'existenceCondition' element" -TestCases ($script:testCases | where-Object { $_.policyEffect.effects -contains 'DeployIfNotExists' }) {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.PSobject.Properties.name -match 'existenceCondition' | Should -Not -Be $Null
      }
      It "Policy rule must contain a 'roleDefinitionIds' element" -TestCases ($script:testCases | where-Object { $_.policyEffect.effects -contains 'DeployIfNotExists' }) {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.PSobject.Properties.name -match 'roleDefinitionIds' | Should -Not -Be $Null
      }
      It "'roleDefinitionIds' element must contain at least one item" -TestCases ($script:testCases | where-Object { $_.policyEffect.effects -contains 'DeployIfNotExists' }) {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.roleDefinitionIds.count | Should -BeGreaterThan 0
      }
    }

    Context "DeployIfNotExists Effect Policy Embedded ARM Template Test" -Tag 'DeployIfNotExistsTemplate' {
      It 'Embedded template Must have a valid schema' -TestCases ($script:testCases | where-Object { $_.policyEffect.effects -contains 'DeployIfNotExists' }) {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.deployment.properties.template."`$schema" | Should -BeLike 'https://schema.management.azure.com/schemas/*'
      }
      It 'Embedded template Must contain a valid contentVersion' -TestCases ($script:testCases | where-Object { $_.policyEffect.effects -contains 'DeployIfNotExists' }) {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.deployment.properties.template.contentVersion | Should -BeGreaterThan ([version]'0.0.0.1')
      }
      It "Embedded template Must contain a 'parameters' element" -TestCases ($script:testCases | where-Object { $_.policyEffect.effects -contains 'DeployIfNotExists' }) {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.deployment.properties.template.PSobject.Properties.name -match 'parameters' | Should -Not -Be $Null
      }
      It "Embedded template Must contain a 'variables' element" -TestCases ($script:testCases | where-Object { $_.policyEffect.effects -contains 'DeployIfNotExists' }) {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.deployment.properties.template.PSobject.Properties.name -match 'variables' | Should -Not -Be $Null
      }
      It "Embedded template Must contain a 'resources' element" -TestCases ($script:testCases | where-Object { $_.policyEffect.effects -contains 'DeployIfNotExists' }) {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.deployment.properties.template.PSobject.Properties.name -match 'resources' | Should -Not -Be $Null
      }
      It "Embedded template Must contain a 'outputs' element" -TestCases ($script:testCases | where-Object { $_.policyEffect.effects -contains 'DeployIfNotExists' }) {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.deployment.properties.template.PSobject.Properties.name -match 'outputs' | Should -Not -Be $Null
      }
    }

    Context "Modify Effect Configuration Test" -Tag 'ModifyConfig' {
      It "Policy rule 'then' element Must contain a 'details' element" -TestCases ($script:testCases | where-Object { $_.policyEffect.effects -contains 'Modify' }) {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.PSobject.Properties.name -match 'details' | Should -Not -Be $Null
      }
      It "Policy rule must contain a 'roleDefinitionIds' element" -TestCases ($script:testCases | where-Object { $_.policyEffect.effects -contains 'Modify' }) {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.PSobject.Properties.name -match 'roleDefinitionIds' | Should -Not -Be $Null
      }
      It "'roleDefinitionIds' element must contain at least one item" -TestCases ($script:testCases | where-Object { $_.policyEffect.effects -contains 'Modify' }) {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.roleDefinitionIds.count | Should -BeGreaterThan 0
      }
      It "Policy rule must contain a 'conflictEffect' element" -TestCases ($script:testCases | where-Object { $_.policyEffect.effects -contains 'Modify' }) {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.PSobject.Properties.name -match 'conflictEffect' | Should -Not -Be $Null
      }
      It "'conflictEffect' element must have a valid value" -TestCases ($script:testCases | where-Object { $_.policyEffect.effects -contains 'Modify' }) {
        param(
          [object] $json
        )
        $global:modifyConflictEffectsValidValues -contains $json.properties.policyRule.then.details.conflictEffect | Should -Be $true
      }
      It "Policy rule must contain an 'operations' element" -TestCases ($script:testCases | where-Object { $_.policyEffect.effects -contains 'Modify' }) {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.PSobject.Properties.name -match 'operations' | Should -Not -Be $Null
      }
    }

    Context "AuditIfNotExists Effect Configuration Test" -Tag 'AuditIfNotExistsConfig' {
      It "Policy rule 'then' element Must contain a 'details' element" -TestCases ($script:testCases | where-Object { $_.policyEffect.effects -contains 'AuditIfNotExists' }) {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.PSobject.Properties.name -match 'details' | Should -Not -Be $Null
      }
      It "Policy rule must contain a 'evaluationDelay' element" -TestCases ($script:testCases | where-Object { $_.policyEffect.effects -contains 'AuditIfNotExists' }) {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.PSobject.Properties.name -match 'evaluationDelay' | Should -Not -Be $Null
      }
      It "Policy rule must contain a 'existenceCondition' element" -TestCases ($script:testCases | where-Object { $_.policyEffect.effects -contains 'AuditIfNotExists' }) {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.PSobject.Properties.name -match 'existenceCondition' | Should -Not -Be $Null
      }
    }
  }
}
