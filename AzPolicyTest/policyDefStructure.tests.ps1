#Requires -Version 7

[CmdletBinding()]
Param (
  [Parameter(Mandatory = $true)][validateScript({ Test-Path $_ })][string]$Path,
  [Parameter(Mandatory = $false)][string[]]$excludePath
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
  Write-Verbose "[$file] Policy Effect: $($testCase.policyEffect.effects)"
  Describe "[$fileRelativePath]: Policy Definition Syntax Test" -Tag "policyDefSyntax" {

    Context "Required Top-Level Elements Test" -Tag "TopLevelElements" {

      It "Should contain top-level element name" -TestCases $testCase -Tag 'NameExists' {
        param(
          [object] $json
        )
        $json.PSobject.Properties.name -cmatch 'name' | Should -Not -Be $Null
      }

      It "Should contain top-level element - properties" -TestCases $testCase -Tag 'PropertiesExists' {
        param(
          [object] $json
        )
        $json.PSobject.Properties.name -cmatch 'properties' | Should -Not -Be $Null
      }
    }

    Context "Policy Definition Elements Value Test" -Tag 'PolicyElements' {

      It "Name value must not be null" -TestCases $testCase -Tag 'NameNotNull' {
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

      It "Name value must not contain spaces" -TestCases $testCase -Tag 'NoSpaceInName' {
        param(
          [object] $json
        )
        $json.name -match ' ' | Should -Be $false
      }

      It "Name value must not contain forbidden characters" -TestCases $testCase -Tag 'NoForbiddenCharsInName' {
        param(
          [object] $json
        )
        $json.name -match '[<>*%&:\\?.+\/]' | Should -Be $false
      }

    }

    Context "Policy Definition Properties Value Test" -Tag 'PolicyProperties' {

      It "Properties must contain 'displayName' element" -TestCases $testCase -Tag 'DisplayNameExists' {
        param(
          [object] $json
        )
        $json.properties.PSobject.Properties.name -cmatch 'displayName' | Should -Not -Be $Null
      }

      It "'displayName' value must not be longer than 128 characters" -TestCases $testCase -Tag 'DisplayNameLength' {
        param(
          [object] $json
        )
        $json.properties.displayName.length | Should -BeLessOrEqual 128
      }

      It "'displayName' value must not have leading and trailing spaces" -TestCases $testCase -Tag 'DisplayNameStartsOrEndsWithSpace' {
        param(
          [object] $json
        )
        $json.properties.displayName.length -eq $json.properties.displayName.trim().length | Should -Be $true
      }

      It "'displayName' value must not end with a period '.'" -TestCases $testcase -Tag 'DisplayNameNotEndsWithPeriod' {
        param(
          [object] $json
        )
        $json.properties.displayName.substring($json.properties.displayName.length -1, 1) | Should -Not -Be '.'
      }

      It "Properties must contain 'description' element" -TestCases $testCase -Tag 'DescriptionExists' {
        param(
          [object] $json
        )
        $json.properties.PSobject.Properties.name -cmatch 'description' | Should -Not -Be $Null
      }

      It "'description' value must not be longer than 512 characters" -TestCases $testCase -Tag 'DescriptionLength' {
        param(
          [object] $json
        )
        $json.properties.description.length | Should -BeLessOrEqual 512
      }

      It "'description' value must not have leading and trailing spaces" -TestCases $testCase -Tag 'DescriptionStartsOrEndsWithSpace' {
        param(
          [object] $json
        )
        $json.properties.description.length -eq $json.properties.description.trim().length | Should -Be $true
      }

      It "Properties must contain 'metadata' element" -TestCases $testCase -Tag 'MetadataExists' {
        param(
          [object] $json
        )
        $json.properties.PSobject.Properties.name -cmatch 'metadata' | Should -Not -Be $Null
      }

      It "Properties must contain 'mode' element" -TestCases $testCase -Tag 'ModeExists' {
        param(
          [object] $json
        )
        $json.properties.PSobject.Properties.name -cmatch 'mode' | Should -Not -Be $Null
      }

      It "Policy mode must have a valid value." -TestCases $testCase -Tag 'ValidMode' {
        param(
          [object] $json
        )
        $global:validModes.contains($json.properties.mode) | Should -Be $true
      }

      It "Properties must contain 'parameters' element" -TestCases $testCase -Tag 'ParametersExists' {
        param(
          [object] $json
        )
        $json.properties.PSobject.Properties.name -cmatch 'parameters' | Should -Not -Be $Null
      }

      It "'parameters' element must contain at least one (1) item" -TestCases $testCase -Tag 'ParametersMinCount' {
        param(
          [object] $json
        )
        $json.properties.parameters.PSObject.Properties.count | Should -BeGreaterThan 0
      }

      It "'parameters' element must contain no more than twenty (20) items" -TestCases $testCase -Tag 'ParametersMaxCount' {
        param(
          [object] $json
        )
        $json.properties.parameters.PSObject.Properties.count | Should -BeLessOrEqual 20
      }

      It "Properties must contain 'policyRule' element" -TestCases $testCase -Tag 'PolicyRuleExists' {
        param(
          [object] $json
        )
        $json.properties.PSobject.Properties.name -cmatch 'policyRule' | Should -Not -Be $Null
      }

      It "'DisplayName' value must not be blank" -TestCases $testCase -Tag 'DisplayNameNotBlank' {
        param(
          [object] $json
        )
        $json.properties.displayName.length | Should -BeGreaterThan 0
      }

      It "'Description' value must not be blank" -TestCases $testCase -Tag 'DescriptionNotBlank' {
        param(
          [object] $json
        )
        $json.properties.description.length | Should -BeGreaterThan 0
      }

      It "Must contain 'Category' metadata" -TestCases $testCase -Tag 'CategoryExists' {
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

      It "'Version' metadata value must be a valid semantic version" -TestCases $testCase -Tag 'VersionIsSemantic' {
        param(
          [object] $json
        )
        $json.properties.metadata.version -cmatch '^\d+\.\d+.\d+(-preview|-deprecated)?$' | Should -Be $true
      }
    }

    Context "Parameters Tests" -Tag 'Parameters' {
      Foreach ($parameterName in $json.properties.parameters.PSObject.Properties.Name) {
        $parameterConfig = $json.properties.parameters.$parameterName
        $parameterTestCase = @{
          parameterName   = $parameterName
          parameterConfig = $parameterConfig
        }

        It "Parameter [<parameterName>] must contain 'type' element" -TestCases $parameterTestCase -Tag 'ParameterTypeExists' {
          param(
            [string] $parameterName,
            [object] $parameterConfig
          )
          $parameterConfig.PSobject.Properties.name -cmatch 'type' | Should -Not -Be $null
        }

        It "Parameter [<parameterName>] default value must be a member of allowed values" -TestCases ($parameterTestCase | where-Object { $_.parameterConfig.PSObject.properties.name -icontains 'allowedValues' -and $_.parameterConfig.PSObject.properties.name -icontains 'defaultValue' }) -Tag 'ParameterDefaultValueValid' {
          param(
            [string] $parameterName,
            [object] $parameterConfig
          )
          if ($parameterConfig.allowedValues) {
            $parameterConfig.allowedValues -contains $parameterConfig.defaultValue | Should -Be $true
          }
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
          $parameterConfig.metadata.PSobject.Properties.name -cmatch 'displayName' | Should -Not -Be $null
        }

        It "Parameter [<parameterName>] metadata must contain 'description' element" -TestCases $parameterTestCase -Tag 'ParameterDescriptionExists' {
          param(
            [string] $parameterName,
            [object] $parameterConfig
          )
          $parameterConfig.metadata.PSobject.Properties.name -cmatch 'description' | Should -Not -Be $null
        }
      }
    }

    Context "Policy Rule Test" -Tag 'PolicyRule' {
      It "Policy Rule must contain 'if' element" -TestCases $testCase -Tag 'PolicyRuleIfExists' {
        param(
          [object] $json
        )
        $json.properties.policyRule.PSobject.Properties.name -cmatch 'if' | Should -Not -Be $Null
      }
      It "Policy Rule must contain 'then' element" -TestCases $testCase -Tag 'PolicyRuleThenExists' {
        param(
          [object] $json
        )
        $json.properties.policyRule.PSobject.Properties.name -cmatch 'then' | Should -Not -Be $Null
      }
    }

    Context "Policy Effect Test" -Tag 'PolicyEffect' {
      It "Policy Rule should have parameterised effect" -TestCases $testCase -Tag 'PolicyEffectParameterised' {
        param(
          [object] $json,
          [hashtable]$policyEffect
        )
        $policyEffect.isHardCoded | Should -Be $false
      }
      It "Policy Rule parameterised effect should contain 'Disabled' effect" -TestCases ($testCase | where-Object { $_.policyEffect.isHardCoded -eq $false }) -Tag 'PolicyEffectParameterContainsDisabled' {
        param(
          [object] $json,
          [hashtable]$policyEffect
        )
        $policyEffect.effects -contains 'Disabled' | Should -Be $true
      }
      It "Policy Rule parameterised effect should have a default value" -TestCases ($testCase | where-Object { $_.policyEffect.isHardCoded -eq $false }) -Tag 'PolicyEffectParameterHasDefaultValue' {
        param(
          [object] $json,
          [hashtable]$policyEffect
        )
        $policyEffect.defaultEffectValue | Should -Not -Be $null
      }
      It "Policy Rule must use a valid effect" -Tag 'PolicyEffectIsValid'-TestCases $testCase {
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

      It "Policy rule with 'Deny' effect must also support 'Audit' Effect" -TestCases ($testCase | where-Object { $_.policyEffect.effects -contains 'Deny' }) -Tag 'PolicyDenyEffectAlsoSupportAudit' {
        param(
          [object] $json
        )
        $policyEffect.effects -contains 'Audit' | Should -Be $true
      }

      It "Policy rule with 'Audit' effect must also support 'Deny' Effect" -TestCases ($testCase | where-Object { $_.policyEffect.effects -contains 'Audit' }) -Tag 'PolicyAuditEffectAlsoSupportDeny' {
        param(
          [object] $json
        )
        $policyEffect.effects -contains 'Deny' | Should -Be $true
      }
    }

    Context "Non DeployIfNotExists or Modify Effect Policy Configuration Test" -Tag NonDINEorModifyConfig {
      It "Policy rule must not contain a 'roleDefinitionIds' element" -TestCases ($testCase | where-Object { $_.policyEffect.effects -notcontains 'DeployIfNotExists' -and $_.policyEffect.effects -notcontains 'Modify' }) -Tag 'NonDINEorModifyRoleDefinition' {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.PSobject.Properties.name -cmatch 'roleDefinitionIds' | Should -Not -Be $true
      }
    }

    Context "DeployIfNotExists Effect Policy Configuration Test" -Tag 'DINEConfig' {
      It "Policy rule 'then' element Must contain a 'details' element" -TestCases ($testCase | where-Object { $_.policyEffect.effects -contains 'DeployIfNotExists' }) -Tag 'DINEDetails' {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.PSobject.Properties.name -cmatch 'details' | Should -Not -Be $Null
      }
      It "Policy rule must contain a embedded 'deployment' element" -TestCases ($testCase | where-Object { $_.policyEffect.effects -contains 'DeployIfNotExists' }) -Tag 'DINEDeployment' {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.PSobject.Properties.name -cmatch 'deployment' | Should -Not -Be $Null
      }
      It "Deployment mode for the policy rule must be 'incremental'" -TestCases ($testCase | where-Object { $_.policyEffect.effects -contains 'DeployIfNotExists' }) -Tag 'DINEIncrementalDeployment' {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.deployment.properties.mode -cmatch 'incremental' | Should -Not -Be $Null
      }
      It "Policy rule must contain a 'evaluationDelay' element" -TestCases ($testCase | where-Object { $_.policyEffect.effects -contains 'DeployIfNotExists' }) -Tag 'DINEEvaluationDelay' {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.PSobject.Properties.name -cmatch 'evaluationDelay' | Should -Not -Be $Null
      }
      It "Policy rule must contain a 'existenceCondition' element" -TestCases ($testCase | where-Object { $_.policyEffect.effects -contains 'DeployIfNotExists' }) -Tag 'DINEExistenceCondition' {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.PSobject.Properties.name -cmatch 'existenceCondition' | Should -Not -Be $Null
      }
      It "Policy rule must contain a 'roleDefinitionIds' element" -TestCases ($testCase | where-Object { $_.policyEffect.effects -contains 'DeployIfNotExists' }) -Tag 'DINERoleDefinition' {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.PSobject.Properties.name -cmatch 'roleDefinitionIds' | Should -Not -Be $Null
      }
      It "'roleDefinitionIds' element must contain at least one item" -TestCases ($testCase | where-Object { $_.policyEffect.effects -contains 'DeployIfNotExists' }) -Tag 'DINERoleDefinitionCount' {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.roleDefinitionIds.count | Should -BeGreaterThan 0
      }
    }

    Context "DeployIfNotExists Effect Policy Embedded ARM Template Test" -Tag 'DINETemplate' {
      It 'Embedded template Must have a valid schema' -TestCases ($testCase | where-Object { $_.policyEffect.effects -contains 'DeployIfNotExists' }) -Tag 'DINETemplateSchema' {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.deployment.properties.template."`$schema" | Should -BeLike 'https://schema.management.azure.com/schemas/*'
      }
      It 'Embedded template Must contain a valid contentVersion' -TestCases ($testCase | where-Object { $_.policyEffect.effects -contains 'DeployIfNotExists' }) -Tag 'DINETemplateContentVersion' {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.deployment.properties.template.contentVersion | Should -BeGreaterThan ([version]'0.0.0.1')
      }
      It "Embedded template Must contain a 'parameters' element" -TestCases ($testCase | where-Object { $_.policyEffect.effects -contains 'DeployIfNotExists' }) -Tag 'DINETemplateParameters' {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.deployment.properties.template.PSobject.Properties.name -cmatch 'parameters' | Should -Not -Be $Null
      }
      It "Embedded template Must contain a 'variables' element" -TestCases ($testCase | where-Object { $_.policyEffect.effects -contains 'DeployIfNotExists' }) -Tag 'DINETemplateVariables' {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.deployment.properties.template.PSobject.Properties.name -cmatch 'variables' | Should -Not -Be $Null
      }
      It "Embedded template Must contain a 'resources' element" -TestCases ($testCase | where-Object { $_.policyEffect.effects -contains 'DeployIfNotExists' }) -Tag 'DINETemplateResources' {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.deployment.properties.template.PSobject.Properties.name -cmatch 'resources' | Should -Not -Be $Null
      }
      It "Embedded template Must contain a 'outputs' element" -TestCases ($testCase | where-Object { $_.policyEffect.effects -contains 'DeployIfNotExists' }) -Tag 'DINETemplateOutputs' {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.deployment.properties.template.PSobject.Properties.name -cmatch 'outputs' | Should -Not -Be $Null
      }
    }

    Context "Modify Effect Configuration Test" -Tag 'ModifyConfig' {
      It "Policy rule 'then' element Must contain a 'details' element" -TestCases ($testCase | where-Object { $_.policyEffect.effects -contains 'Modify' })  -Tag 'ModifyDetails' {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.PSobject.Properties.name -cmatch 'details' | Should -Not -Be $Null
      }
      It "Policy rule must contain a 'roleDefinitionIds' element" -TestCases ($testCase | where-Object { $_.policyEffect.effects -contains 'Modify' }) -Tag 'ModifyRoleDefinition' {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.PSobject.Properties.name -cmatch 'roleDefinitionIds' | Should -Not -Be $Null
      }
      It "'roleDefinitionIds' element must contain at least one item" -TestCases ($testCase | where-Object { $_.policyEffect.effects -contains 'Modify' }) -Tag 'ModifyRoleDefinitionCount' {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.roleDefinitionIds.count | Should -BeGreaterThan 0
      }
      It "Policy rule must contain a 'conflictEffect' element" -TestCases ($testCase | where-Object { $_.policyEffect.effects -contains 'Modify' }) -Tag 'ModifyConflictEffect' {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.PSobject.Properties.name -cmatch 'conflictEffect' | Should -Not -Be $Null
      }
      It "'conflictEffect' element must have a valid value" -TestCases ($testCase | where-Object { $_.policyEffect.effects -contains 'Modify' }) -Tag 'ModifyConflictEffectValid' {
        param(
          [object] $json
        )
        $global:modifyConflictEffectsValidValues -contains $json.properties.policyRule.then.details.conflictEffect | Should -Be $true
      }
      It "Policy rule must contain an 'operations' element" -TestCases ($testCase | where-Object { $_.policyEffect.effects -contains 'Modify' }) -Tag 'ModifyOperations' {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.PSobject.Properties.name -cmatch 'operations' | Should -Not -Be $Null
      }
    }

    Context "AuditIfNotExists Effect Configuration Test" -Tag 'AuditIfNotExistsConfig' {
      It "Policy rule 'then' element Must contain a 'details' element" -TestCases ($testCase | where-Object { $_.policyEffect.effects -contains 'AuditIfNotExists' }) -Tag 'AINEDetails' {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.PSobject.Properties.name -cmatch 'details' | Should -Not -Be $Null
      }
      It "Policy rule must contain a 'evaluationDelay' element" -TestCases ($testCase | where-Object { $_.policyEffect.effects -contains 'AuditIfNotExists' }) -Tag 'AINEEvaluationDelay' {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.PSobject.Properties.name -cmatch 'evaluationDelay' | Should -Not -Be $Null
      }
      It "Policy rule must contain a 'existenceCondition' element" -TestCases ($testCase | where-Object { $_.policyEffect.effects -contains 'AuditIfNotExists' }) -Tag 'AINEExistenceCondition' {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.PSobject.Properties.name -cmatch 'existenceCondition' | Should -Not -Be $Null
      }
    }
  }
}
