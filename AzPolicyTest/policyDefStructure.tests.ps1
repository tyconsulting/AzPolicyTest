#Requires -Version 7

[CmdletBinding()]
Param (
  [Parameter(Mandatory = $true)][validateScript({ Test-Path $_ })][string] $Path,
  [Parameter(Mandatory = $false)][string[]] $excludePath
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

# Get JSON files
if ((Get-Item $path).PSIsContainer) {
  Write-Verbose "Specified path '$path' is a directory"
  $gciParams = @{
    Path    = $Path
    Include = '*.json', '*.jsonc'
    Recurse = $true
  }
  $files = Get-ChildItem @gciParams
  # -Exclude parameter in Get-ChildItem only works on file name, not parent folder name hence it's not used in get-childitem
  if ($excludePath) {
    $excludePath = $excludePath -join '|'
    $files = $files | Where-Object -FilterScript {$_.FullName -notmatch $excludePath }
  }

} else {
  Write-Verbose "Specified path '$path' is a file"
  $files = Get-Item $path -Include '*.json', '*.jsonc'
}

# Policy Definition Tests
foreach ($file in $files) {
  Write-Verbose "Test '$file'" -verbose
  $fileName = (get-item $file).name
  $fileFullName = (get-item $file).FullName
  $fileRelativePath = GetRelativeFilePath -path $fileFullName
  #check if the file is inside a git repository
  $json = ConvertFrom-Json -InputObject (Get-Content -Path $file -Raw) -Depth 10 -ErrorAction SilentlyContinue
  $testCase = @{
    fileName         = $fileName
    json             = $json
    policyEffect     = GetPolicyEffect -policyObject $json
    fileRelativePath = $fileRelativePath
  }
  Write-Verbose "[$file] Policy Effect: $($testCase.policyEffect.effects)"

  # Start Pester tests
  Describe "[$fileRelativePath]: Policy Definition Syntax Test" -Tag 'policyDefSyntax' {

    BeforeAll {
      # Variables - Use Script scope to make PSScriptAnalyzer happy <https://github.com/PowerShell/PSScriptAnalyzer/issues/1641>
      $Script:ValidEffects = [string[]](
        'AddToNetworkGroup',
        'Append',
        'Audit',
        'AuditIfNotExists',
        'Deny',
        'DenyAction',
        'DeployIfNotExists',
        'Disabled',
        'Manual',
        'Modify',
        'Mutate'
      )
      $Script:ValidModes = [string[]](
        'All',
        'Indexed',
        'Microsoft.DataFactory.Data',
        'Microsoft.KeyVault.Data',
        'Microsoft.Kubernetes.Data',
        'Microsoft.MachineLearningServices.v2.Data',
        'Microsoft.ManagedHSM.Data',
        'Microsoft.Network.Data'
      )
      $Script:ModifyConflictEffectsValidValues = [string[]](
        'audit',
        'deny',
        'disabled'
      )
      $Script:ValidParameterTypes = [string[]](
        'array',
        'boolean',
        'datetime',
        'float',
        'integer',
        'object',
        'string'
      )
    }

    Context 'Required Top-Level Elements Test' -Tag 'TopLevelElements' {

      It -Name 'Should contain top-level element name' -TestCases $testCase -Tag 'NameExists' -Test {
        param(
          [object] $json
        )
        $json.PSobject.Properties.name -cmatch 'name' | Should -Not -Be $Null
      }

      It -Name 'Should contain top-level element - properties' -TestCases $testCase -Tag 'PropertiesExists' -Test {
        param(
          [object] $json
        )
        $json.PSobject.Properties.name -cmatch 'properties' | Should -Not -Be $Null
      }
    }

    Context 'Policy Definition Elements Value Test' -Tag 'PolicyElements' {
      It -Name 'Name value must not be null' -TestCases $testCase -Tag 'NameNotNull' -Test {
        param(
          [object] $json
        )
        $json.name.length | Should -BeGreaterThan 0
      }

      It -Name 'Name value must not be longer than 64 characters' -TestCases $testCase -Tag 'NameLength' -Test {
        param(
          [object] $json
        )
        $json.name.length | Should -BeLessOrEqual 64
      }

      It -Name 'Name value must not contain spaces' -TestCases $testCase -Tag 'NoSpaceInName' -Test {
        param(
          [object] $json
        )
        $json.name -match ' ' | Should -Be $false
      }

      It -Name 'Name value must not contain forbidden characters' -TestCases $testCase -Tag 'NoForbiddenCharsInName' -Test {
        param(
          [object] $json
        )
        $json.name -match '[<>*%&:\\?.+\/]' | Should -Be $false
      }

    }

    Context 'Policy Definition Properties Value Test' -Tag 'PolicyProperties' {
      It -Name "Properties must contain 'displayName' element" -TestCases $testCase -Tag 'DisplayNameExists' -Test {
        param(
          [object] $json
        )
        $json.properties.PSobject.Properties.name -cmatch 'displayName' | Should -Not -Be $Null
      }

      It -Name "'displayName' value must not be longer than 128 characters" -TestCases $testCase -Tag 'DisplayNameLength' -Test {
        param(
          [object] $json
        )
        $json.properties.displayName.length | Should -BeLessOrEqual 128
      }

      It -Name "'displayName' value must not have leading and trailing spaces" -TestCases $testCase -Tag 'DisplayNameStartsOrEndsWithSpace' -Test {
        param(
          [object] $json
        )
        $json.properties.displayName.length -eq $json.properties.displayName.trim().length | Should -Be $true
      }

      It -Name "'displayName' value must not end with a period '.'" -TestCases $testcase -Tag 'DisplayNameNotEndsWithPeriod' -Test {
        param(
          [object] $json
        )
        $json.properties.displayName.substring($json.properties.displayName.length -1, 1) | Should -Not -Be '.'
      }

      It -Name "Properties must contain 'description' element" -TestCases $testCase -Tag 'DescriptionExists' -Test {
        param(
          [object] $json
        )
        $json.properties.PSobject.Properties.name -cmatch 'description' | Should -Not -Be $Null
      }

      It -Name "'description' value must not be longer than 512 characters" -TestCases $testCase -Tag 'DescriptionLength' -Test {
        param(
          [object] $json
        )
        $json.properties.description.length | Should -BeLessOrEqual 512
      }

      It -Name "'description' value must not have leading and trailing spaces" -TestCases $testCase -Tag 'DescriptionStartsOrEndsWithSpace' -Test {
        param(
          [object] $json
        )
        $json.properties.description.length -eq $json.properties.description.trim().length | Should -Be $true
      }

      It -Name "Properties must contain 'metadata' element" -TestCases $testCase -Tag 'MetadataExists' -Test {
        param(
          [object] $json
        )
        $json.properties.PSobject.Properties.name -cmatch 'metadata' | Should -Not -Be $Null
      }

      It -Name "Properties must contain 'mode' element" -TestCases $testCase -Tag 'ModeExists' -Test {
        param(
          [object] $json
        )
        $json.properties.PSobject.Properties.name -cmatch 'mode' | Should -Not -Be $Null
      }

      It -Name 'Policy mode must have a valid value.' -TestCases $testCase -Tag 'ValidMode' -Test {
        param(
          [object] $json
        )
        $ValidModes -contains $json.properties.mode | Should -Be $true
      }

      It -Name "Properties must contain 'parameters' element" -TestCases $testCase -Tag 'ParametersExists' -Test {
        param(
          [object] $json
        )
        $json.properties.PSobject.Properties.name -cmatch 'parameters' | Should -Not -Be $Null
      }

      It -Name "'parameters' element must contain at least one (1) item" -TestCases $testCase -Tag 'ParametersMinCount' -Test {
        param(
          [object] $json
        )
        $json.properties.parameters.PSObject.Properties.count | Should -BeGreaterThan 0
      }

      It -Name "'parameters' element must contain no more than twenty (20) items" -TestCases $testCase -Tag 'ParametersMaxCount' -Test {
        param(
          [object] $json
        )
        $json.properties.parameters.PSObject.Properties.count | Should -BeLessOrEqual 20
      }

      It -Name "Properties must contain 'policyRule' element" -TestCases $testCase -Tag 'PolicyRuleExists' -Test {
        param(
          [object] $json
        )
        $json.properties.PSobject.Properties.name -cmatch 'policyRule' | Should -Not -Be $Null
      }

      It -Name "'DisplayName' value must not be blank" -TestCases $testCase -Tag 'DisplayNameNotBlank' -Test {
        param(
          [object] $json
        )
        $json.properties.displayName.length | Should -BeGreaterThan 0
      }

      It -Name "'Description' value must not be blank" -TestCases $testCase -Tag 'DescriptionNotBlank' -Test {
        param(
          [object] $json
        )
        $json.properties.description.length | Should -BeGreaterThan 0
      }

      It -Name "Must contain 'Category' metadata" -TestCases $testCase -Tag 'CategoryExists' -Test {
        param(
          [object] $json
        )
        $json.properties.metadata.category.length | Should -BeGreaterThan 0
      }

      It -Name "Must contain 'Version' metadata" -TestCases $testCase -Tag 'VersionExists' -Test {
        param(
          [object] $json
        )
        $json.properties.metadata.version.length | Should -BeGreaterThan 0
      }

      It -Name "'Version' metadata value must be a valid semantic version" -TestCases $testCase -Tag 'VersionIsSemantic' -Test {
        param(
          [object] $json
        )
        $json.properties.metadata.version -cmatch '^\d+\.\d+.\d+(-preview|-deprecated)?$' | Should -Be $true
      }
    }

    Context 'Parameters Tests' -Tag 'Parameters' {
      foreach ($parameterName in $json.properties.parameters.PSObject.Properties.Name) {
        $parameterConfig = $json.properties.parameters.$parameterName
        $parameterTestCase = @{
          parameterName   = $parameterName
          parameterConfig = $parameterConfig
        }

        It -Name "Parameter [<parameterName>] must contain 'type' element" -TestCases $parameterTestCase -Tag 'ParameterTypeExists' -Test {
          param(
            [object] $parameterConfig
          )
          $parameterConfig.PSobject.Properties.name -cmatch 'type' | Should -Not -Be $null
        }

        It -Name 'Parameter [<parameterName>] default value must be a member of allowed values' -TestCases (
          $parameterTestCase | Where-Object -FilterScript {
            $_.parameterConfig.PSObject.properties.name -icontains 'allowedValues' -and
            $_.parameterConfig.PSObject.properties.name -icontains 'defaultValue'
          }
        ) -Tag 'ParameterDefaultValueValid' -Test {
          param(
            [object] $parameterConfig
          )
          if ($parameterConfig.allowedValues) {
            if ($parameterConfig.type -ieq 'array') {
              $allInAllowedValues = $true
              foreach ($d in $parameterConfig.defaultValue) {
                if ($parameterConfig.allowedValues -notcontains $d) {$allInAllowedValues = $false}
              }
              $allInAllowedValues | Should -Be $true
            } else {
              $parameterConfig.allowedValues -contains $parameterConfig.defaultValue | Should -Be $true
            }
          }
        }

        It -Name "Parameter [<parameterName>] must have a valid value for the 'type' element" -TestCases $parameterTestCase -Tag 'ParameterTypeValid' -Test {
          param(
            [object] $parameterConfig
          )
          $ValidParameterTypes -contains $parameterConfig.type | Should -Be $true
        }

        It -Name "Parameter [<parameterName>] metadata must contain 'displayName' element" -TestCases $parameterTestCase -Tag 'ParameterDisplayNameExists' -Test {
          param(
            [object] $parameterConfig
          )
          $parameterConfig.metadata.PSobject.Properties.name -cmatch 'displayName' | Should -Not -Be $null
        }

        It -Name "Parameter [<parameterName>] metadata must contain 'description' element" -TestCases $parameterTestCase -Tag 'ParameterDescriptionExists' -Test {
          param(
            [object] $parameterConfig
          )
          $parameterConfig.metadata.PSobject.Properties.name -cmatch 'description' | Should -Not -Be $null
        }
      }
    }

    Context 'Policy Rule Test' -Tag 'PolicyRule' {
      It -Name "Policy Rule must contain 'if' element" -TestCases $testCase -Tag 'PolicyRuleIfExists' -Test {
        param(
          [object] $json
        )
        $json.properties.policyRule.PSobject.Properties.name -cmatch 'if' | Should -Not -Be $Null
      }
      It -Name "Policy Rule must contain 'then' element" -TestCases $testCase -Tag 'PolicyRuleThenExists' -Test {
        param(
          [object] $json
        )
        $json.properties.policyRule.PSobject.Properties.name -cmatch 'then' | Should -Not -Be $Null
      }
    }

    Context 'Policy Effect Test' -Tag 'PolicyEffect' {
      It -Name 'Policy Rule should have parameterised effect' -TestCases $testCase -Tag 'PolicyEffectParameterised' -Test {
        param(
          [hashtable] $policyEffect
        )
        $policyEffect.isHardCoded | Should -Be $false
      }

      It -Name "Policy Rule parameterised effect should contain 'Disabled' effect" -TestCases (
        $testCase | Where-Object -FilterScript {$_.policyEffect.isHardCoded -eq $false }
      ) -Tag 'PolicyEffectParameterContainsDisabled' -Test {
        param(
          [hashtable] $policyEffect
        )
        $policyEffect.effects -contains 'Disabled' | Should -Be $true
      }

      It -Name 'Policy Rule parameterised effect should have a default value' -TestCases (
        $testCase | Where-Object -FilterScript {$_.policyEffect.isHardCoded -eq $false }
      ) -Tag 'PolicyEffectParameterHasDefaultValue' -Test {
        param(
          [hashtable] $policyEffect
        )
        $policyEffect.defaultEffectValue | Should -Not -Be $null
      }

      It -Name 'Policy Rule must use a valid effect' -Tag 'PolicyEffectIsValid' -TestCases $testCase -Test {
        param(
          [hashtable] $policyEffect
        )
        $policyEffect.effects.Where{
          $_ -notin $ValidEffects
        }.Count | Should -BeLessOrEqual 0
      }

      It -Name "Policy rule with 'Deny' effect must also support 'Audit' Effect" -TestCases (
        $testCase | Where-Object -FilterScript {$_.policyEffect.effects -contains 'Deny'}
      ) -Tag 'PolicyDenyEffectAlsoSupportAudit' -Test {
        param(
          [hashtable] $policyEffect
        )
        $policyEffect.effects -contains 'Audit' | Should -Be $true
      }

      It -Name "Policy rule with 'Audit' effect must also support 'Deny' Effect" -TestCases (
        $testCase | Where-Object -FilterScript {$_.policyEffect.effects -contains 'Audit'}
      ) -Tag 'PolicyAuditEffectAlsoSupportDeny' -Test {
        param(
          [hashtable] $policyEffect
        )
        $policyEffect.effects -contains 'Deny' | Should -Be $true
      }
    }

    Context 'Non DeployIfNotExists or Modify Effect Policy Configuration Test' -Tag NonDINEorModifyConfig {
      It -Name "Policy rule must not contain a 'roleDefinitionIds' element" -TestCases (
        $testCase | Where-Object -FilterScript {$_.policyEffect.effects -notcontains 'DeployIfNotExists' -and $_.policyEffect.effects -notcontains 'Modify'}
      ) -Tag 'NonDINEorModifyRoleDefinition' -Test {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.PSobject.Properties.name -cmatch 'roleDefinitionIds' | Should -Not -Be $true
      }
    }

    Context 'DeployIfNotExists Effect Policy Configuration Test' -Tag 'DINEConfig' {
      It -Name "Policy rule 'then' element Must contain a 'details' element" -TestCases (
        $testCase | Where-Object -FilterScript {$_.policyEffect.effects -contains 'DeployIfNotExists'}
      ) -Tag 'DINEDetails' -Test {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.PSobject.Properties.name -cmatch 'details' | Should -Not -Be $Null
      }

      It -Name "Policy rule must contain a embedded 'deployment' element" -TestCases (
        $testCase | Where-Object -FilterScript {$_.policyEffect.effects -contains 'DeployIfNotExists'}
      ) -Tag 'DINEDeployment' -Test {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.PSobject.Properties.name -cmatch 'deployment' | Should -Not -Be $Null
      }

      It -Name "Deployment mode for the policy rule must be 'incremental'" -TestCases (
        $testCase | Where-Object -FilterScript {$_.policyEffect.effects -contains 'DeployIfNotExists'}
      ) -Tag 'DINEIncrementalDeployment' -Test {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.deployment.properties.mode -cmatch 'incremental' | Should -Not -Be $Null
      }

      It -Name "Policy rule must contain a 'evaluationDelay' element" -TestCases (
        $testCase | Where-Object -FilterScript {$_.policyEffect.effects -contains 'DeployIfNotExists'}
      ) -Tag 'DINEEvaluationDelay' -Test {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.PSobject.Properties.name -cmatch 'evaluationDelay' | Should -Not -Be $Null
      }

      It -Name "Policy rule must contain a 'existenceCondition' element" -TestCases (
        $testCase | Where-Object -FilterScript {$_.policyEffect.effects -contains 'DeployIfNotExists'}) -Tag 'DINEExistenceCondition' -Test {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.PSobject.Properties.name -cmatch 'existenceCondition' | Should -Not -Be $Null
      }

      It -Name 'Policy rule existenceCondition must not be empty' -TestCases (
        $testCase | Where-Object -FilterScript {
          $_.policyEffect.effects -contains 'DeployIfNotExists' -and
          $_.json.properties.policyRule.then.details.PSobject.Properties.name -cmatch 'existenceCondition'
        }
      ) -Tag 'DINEExistenceConditionNotEmpty' -Test {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.existenceCondition | ConvertTo-Json -Depth 10 | Should -Not -Be '{}'
      }

      It -Name "Policy rule must contain a 'roleDefinitionIds' element" -TestCases (
        $testCase | Where-Object -FilterScript {$_.policyEffect.effects -contains 'DeployIfNotExists'}
      ) -Tag 'DINERoleDefinition' -Test {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.PSobject.Properties.name -cmatch 'roleDefinitionIds' | Should -Not -Be $Null
      }

      It -Name "'roleDefinitionIds' element must contain at least one item" -TestCases (
        $testCase | Where-Object -FilterScript {$_.policyEffect.effects -contains 'DeployIfNotExists'}
      ) -Tag 'DINERoleDefinitionCount' -Test {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.roleDefinitionIds.count | Should -BeGreaterThan 0
      }
    }

    Context 'DeployIfNotExists Effect Policy Embedded ARM Template Test' -Tag 'DINETemplate' {
      It -Name 'Embedded template Must have a valid schema' -TestCases (
        $testCase | Where-Object -FilterScript {$_.policyEffect.effects -contains 'DeployIfNotExists'}
      ) -Tag 'DINETemplateSchema' -Test {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.deployment.properties.template."`$schema" | Should -BeLike 'https://schema.management.azure.com/schemas/*'
      }

      It -Name 'Embedded template Must contain a valid contentVersion' -TestCases (
        $testCase | Where-Object -FilterScript {$_.policyEffect.effects -contains 'DeployIfNotExists'}
      ) -Tag 'DINETemplateContentVersion' -Test {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.deployment.properties.template.contentVersion | Should -BeGreaterThan ([version]'0.0.0.1')
      }

      It -Name "Embedded template Must contain a 'parameters' element" -TestCases (
        $testCase | Where-Object -FilterScript {$_.policyEffect.effects -contains 'DeployIfNotExists'}
      ) -Tag 'DINETemplateParameters' -Test {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.deployment.properties.template.PSobject.Properties.name -cmatch 'parameters' | Should -Not -Be $Null
      }

      It -Name "Embedded template Must contain a 'variables' element" -TestCases (
        $testCase | Where-Object -FilterScript {$_.policyEffect.effects -contains 'DeployIfNotExists'}
      ) -Tag 'DINETemplateVariables' -Test {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.deployment.properties.template.PSobject.Properties.name -cmatch 'variables' | Should -Not -Be $Null
      }

      It -Name "Embedded template Must contain a 'resources' element" -TestCases (
        $testCase | Where-Object -FilterScript {$_.policyEffect.effects -contains 'DeployIfNotExists'}
      ) -Tag 'DINETemplateResources' -Test {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.deployment.properties.template.PSobject.Properties.name -cmatch 'resources' | Should -Not -Be $Null
      }

      It -Name "Embedded template Must contain a 'outputs' element" -TestCases (
        $testCase | Where-Object -FilterScript {$_.policyEffect.effects -contains 'DeployIfNotExists'}
      ) -Tag 'DINETemplateOutputs' -Test {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.deployment.properties.template.PSobject.Properties.name -cmatch 'outputs' | Should -Not -Be $Null
      }
    }

    Context 'Modify Effect Configuration Test' -Tag 'ModifyConfig' {
      It -Name "Policy rule 'then' element Must contain a 'details' element" -TestCases (
        $testCase | Where-Object -FilterScript {$_.policyEffect.effects -contains 'Modify'}
      )  -Tag 'ModifyDetails' -Test {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.PSobject.Properties.name -cmatch 'details' | Should -Not -Be $Null
      }

      It -Name "Policy rule must contain a 'roleDefinitionIds' element" -TestCases (
        $testCase | Where-Object -FilterScript {$_.policyEffect.effects -contains 'Modify'}
      ) -Tag 'ModifyRoleDefinition' -Test {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.PSobject.Properties.name -cmatch 'roleDefinitionIds' | Should -Not -Be $Null
      }

      It -Name "'roleDefinitionIds' element must contain at least one item" -TestCases (
        $testCase | Where-Object -FilterScript {$_.policyEffect.effects -contains 'Modify'}
      ) -Tag 'ModifyRoleDefinitionCount' -Test {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.roleDefinitionIds.count | Should -BeGreaterThan 0
      }

      It -Name "Policy rule must contain a 'conflictEffect' element" -TestCases (
        $testCase | Where-Object -FilterScript {$_.policyEffect.effects -contains 'Modify'}
      ) -Tag 'ModifyConflictEffect' -Test {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.PSobject.Properties.name -cmatch 'conflictEffect' | Should -Not -Be $Null
      }

      It -Name "'conflictEffect' element must have a valid value" -TestCases (
        $testCase | Where-Object -FilterScript {$_.policyEffect.effects -contains 'Modify'}
      ) -Tag 'ModifyConflictEffectValid' -Test {
        param(
          [object] $json
        )
        $ModifyConflictEffectsValidValues -contains $json.properties.policyRule.then.details.conflictEffect | Should -Be $true
      }

      It -Name "Policy rule must contain an 'operations' element" -TestCases (
        $testCase | Where-Object -FilterScript {$_.policyEffect.effects -contains 'Modify'}
      ) -Tag 'ModifyOperations' -Test {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.PSobject.Properties.name -cmatch 'operations' | Should -Not -Be $Null
      }
    }

    Context 'AuditIfNotExists Effect Configuration Test' -Tag 'AuditIfNotExistsConfig' {
      It -Name "Policy rule 'then' element Must contain a 'details' element" -TestCases (
        $testCase | Where-Object -FilterScript {$_.policyEffect.effects -contains 'AuditIfNotExists'}
      ) -Tag 'AINEDetails' -Test {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.PSobject.Properties.name -cmatch 'details' | Should -Not -Be $Null
      }

      It -Name "Policy rule must contain a 'evaluationDelay' element" -TestCases (
        $testCase | Where-Object -FilterScript {$_.policyEffect.effects -contains 'AuditIfNotExists'}
      ) -Tag 'AINEEvaluationDelay' -Test {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.PSobject.Properties.name -cmatch 'evaluationDelay' | Should -Not -Be $Null
      }

      It -Name "Policy rule must contain a 'existenceCondition' element" -TestCases (
        $testCase | Where-Object -FilterScript {$_.policyEffect.effects -contains 'AuditIfNotExists'}
      ) -Tag 'AINEExistenceCondition' -Test {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.PSobject.Properties.name -cmatch 'existenceCondition' | Should -Not -Be $Null
      }

      It -Name 'Policy rule existenceCondition must not be empty' -TestCases (
        $testCase | Where-Object -FilterScript {
          $_.policyEffect.effects -contains 'AuditIfNotExists' -and
          $_.json.properties.policyRule.then.details.PSobject.Properties.name -cmatch 'existenceCondition'
        }
      ) -Tag 'AINEExistenceConditionNotEmpty' -Test {
        param(
          [object] $json
        )
        $json.properties.policyRule.then.details.existenceCondition | ConvertTo-Json -Depth 10 | Should -Not -Be '{}'
      }
    }
  }
}
