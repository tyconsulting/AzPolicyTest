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
  $parameterRegex = "^\[parameters\(\'(\S+)\'\)\]$"
  $effect = $policyObject.properties.policyRule.then.effect
  #check if the effect is a parameterised value
  if ($effect -imatch  $parameterRegex)
  {
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
      effects = $effects
      defaultEffectValue = $policyEffectDefaultValue
      isHardCoded = $false
    }
  } else {
    $result = @{
      effects = @($effect)
      defaultEffectValue = $null
      isHardCoded = $true
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
  'Disabled'
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

#Get JSON files
if ((Get-Item $path).PSIsContainer) {
  Write-Verbose "Specified path '$path' is a directory"
  $files = Get-ChildItem $Path -Include *.json -Recurse
} else {
  Write-Verbose "Specified path '$path' is a file"
  $files = Get-Item $path -Include *.json
}

$script:testCases = [System.Collections.ArrayList]@()
foreach ($file in $files) {
  $json = ConvertFrom-Json -InputObject (Get-Content -Path $file -Raw) -ErrorAction SilentlyContinue
  $script:testCases += @{
    fileName = (get-item $file).name
    json     = $json
    policyEffect = GetPolicyEffect -policyObject $json
  }
}
Describe "Policy Definition Syntax Test" -Tag "policyDefSyntax" {
  Context "Required Top-Level Elements Test" {
    It "[<fileName>] Should contain top-level element name" -TestCases $script:testCases {
      param(
        [object] $json
      )
      $json.PSobject.Properties.name -match 'name' | Should -Not -Be $Null
    }
    It "[<fileName>] Should contain top-level element - properties" -TestCases $script:testCases {
      param(
        [object] $json
      )
      $json.PSobject.Properties.name -match 'properties' | Should -Not -Be $Null
    }
  }

  Context "Policy Definition Elements Value Test" -Tag 'PolicyElements' {
    It "[<fileName>] Name value must not be null" -TestCases $script:testCases {
      param(
        [object] $json
      )
      $json.name.length | Should -BeGreaterThan 0
    }
    It "[<fileName>] Name value must not be longer than 64 characters" -TestCases $script:testCases {
      param(
        [object] $json
      )
      $json.name.length | Should -BeLessOrEqual 64
    }
    It "[<fileName>] Name value must not contain spaces" -TestCases $script:testCases {
      param(
        [object] $json
      )
      $json.name -match ' ' | Should -Be $false
    }
  }

  Context "Policy Definition Properties Value Test" -Tag 'PolicyProperties' {
    It "[<fileName>] Properties must contain 'displayName' element" -TestCases $script:testCases {
      param(
        [object] $json
      )
      $json.properties.PSobject.Properties.name -match 'displayName' | Should -Not -Be $Null
    }
    It "[<fileName>] Properties must contain 'description' element" -TestCases $script:testCases {
      param(
        [object] $json
      )
      $json.properties.PSobject.Properties.name -match 'description' | Should -Not -Be $Null
    }
    It "[<fileName>] Properties must contain 'metadata' element" -TestCases $script:testCases {
      param(
        [object] $json
      )
      $json.properties.PSobject.Properties.name -match 'metadata' | Should -Not -Be $Null
    }
    It "[<fileName>] Properties must contain 'mode' element" -TestCases $script:testCases {
      param(
        [object] $json
      )
      $json.properties.PSobject.Properties.name -match 'mode' | Should -Not -Be $Null
    }
    It "[<fileName>] Policy mode must have a valid value." -TestCases $script:testCases {
      param(
        [object] $json
      )
      $global:validModes.contains($json.properties.mode) | Should -Be $true
    }
    It "[<fileName>] Properties must contain 'parameters' element" -TestCases $script:testCases {
      param(
        [object] $json
      )
      $json.properties.PSobject.Properties.name -match 'parameters' | Should -Not -Be $Null
    }
    It "[<fileName>] Properties must contain 'policyRule' element" -TestCases $script:testCases {
      param(
        [object] $json
      )
      $json.properties.PSobject.Properties.name -match 'policyRule' | Should -Not -Be $Null
    }
    It "[<fileName>] 'DisplayName' value must not be blank" -TestCases $script:testCases {
      param(
        [object] $json
      )
      $json.properties.displayName.length | Should -BeGreaterThan 0
    }
    It "[<fileName>] 'Description' value must not be blank" -TestCases $script:testCases {
      param(
        [object] $json
      )
      $json.properties.description.length | Should -BeGreaterThan 0
    }
    It "[<fileName>] Must contain 'Category' metadata" -TestCases $script:testCases {
      param(
        [object] $json
      )
      $json.properties.metadata.category.length | Should -BeGreaterThan 0
    }
  }

  Context "Policy Rule Test" -Tag 'PolicyRule' {
    It "[<fileName>] Policy Rule must contain 'if' element" -TestCases $script:testCases {
      param(
        [object] $json
      )
      $json.properties.policyRule.PSobject.Properties.name -match 'if' | Should -Not -Be $Null
    }
    It "[<fileName>] Policy Rule must contain 'then' element" -TestCases $script:testCases {
      param(
        [object] $json
      )
      $json.properties.policyRule.PSobject.Properties.name -match 'then' | Should -Not -Be $Null
    }
  }

  Context "Policy Effect Test" -Tag 'PolicyEffect' {
    It "[<fileName>] Policy Rule should have parameterised effect" -TestCases $script:testCases {
      param(
        [object] $json,
        [hashtable]$policyEffect
      )
      $policyEffect.isHardCoded | Should -Be $false
    }
    It "[<fileName>] Policy Rule parameterised effect should contain 'Disabled' effect" -TestCases ($script:testCases | where-Object {$_.policyEffect.isHardCoded -eq $false}) {
      param(
        [object] $json,
        [hashtable]$policyEffect
      )
      $policyEffect.effects -contains 'Disabled' | Should -Be $true
    }
    It "[<fileName>] Policy Rule parameterised effect should have a default value" -TestCases ($script:testCases | where-Object {$_.policyEffect.isHardCoded -eq $false}) {
      param(
        [object] $json,
        [hashtable]$policyEffect
      )
      $policyEffect.defaultEffectValue | Should -Not -Be $null
    }
    It "[<fileName>] Policy Rule must use a valid effect" -TestCases $script:testCases {
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

    It "[<fileName>] Policy rule with 'Deny' effect must also support 'Audit' Effect" -TestCases ($script:testCases | where-Object {$_.policyEffect.effects -contains 'Deny'}) {
      param(
        [object] $json
      )
      $policyEffect.effects -contains 'Audit' | Should -Be $true
    }

    It "[<fileName>] Policy rule with 'Audit' effect must also support 'Deny' Effect" -TestCases ($script:testCases | where-Object {$_.policyEffect.effects -contains 'Audit'}) {
      param(
        [object] $json
      )
      $policyEffect.effects -contains 'Deny' | Should -Be $true
    }
  }

  Context "DeployIfNotExists Effect Policy Configuration Test" -Tag 'DeployIfNotExistsConfig' {
    It "[<fileName>] Policy rule 'then' element Must contain a 'details' element" -TestCases ($script:testCases | where-Object {$_.policyEffect.effects -contains 'DeployIfNotExists'}) {
      param(
        [object] $json
      )
      $json.properties.policyRule.then.PSobject.Properties.name -match 'details' | Should -Not -Be $Null
    }
    It "[<fileName>] Policy rule must contain a embedded 'deployment' element" -TestCases ($script:testCases | where-Object {$_.policyEffect.effects -contains 'DeployIfNotExists'}) {
      param(
        [object] $json
      )
      $json.properties.policyRule.then.details.PSobject.Properties.name -match 'deployment' | Should -Not -Be $Null
    }
    It "[<fileName>] Deployment mode for the policy rule must be 'incremental'" -TestCases ($script:testCases | where-Object {$_.policyEffect.effects -contains 'DeployIfNotExists'}) {
      param(
        [object] $json
      )
      $json.properties.policyRule.then.details.deployment.properties.mode -match 'incremental' | Should -Not -Be $Null
    }
    It "[<fileName>] Policy rule must contain a 'evaluationDelay' element" -TestCases ($script:testCases | where-Object {$_.policyEffect.effects -contains 'DeployIfNotExists'}) {
      param(
        [object] $json
      )
      $json.properties.policyRule.then.details.PSobject.Properties.name -match 'evaluationDelay' | Should -Not -Be $Null
    }
    It "[<fileName>] Policy rule must contain a 'existenceCondition' element" -TestCases ($script:testCases | where-Object {$_.policyEffect.effects -contains 'DeployIfNotExists'}) {
      param(
        [object] $json
      )
      $json.properties.policyRule.then.details.PSobject.Properties.name -match 'existenceCondition' | Should -Not -Be $Null
    }
    It "[<fileName>] Policy rule must contain a 'roleDefinitionIds' element" -TestCases ($script:testCases | where-Object {$_.policyEffect.effects -contains 'DeployIfNotExists'}) {
      param(
        [object] $json
      )
      $json.properties.policyRule.then.details.PSobject.Properties.name -match 'roleDefinitionIds' | Should -Not -Be $Null
    }
    It "[<fileName>] 'roleDefinitionIds' element must contain at least one item" -TestCases ($script:testCases | where-Object {$_.policyEffect.effects -contains 'DeployIfNotExists'}) {
      param(
        [object] $json
      )
      $json.properties.policyRule.then.details.roleDefinitionIds.count | Should -BeGreaterThan 0
    }
  }

  Context "DeployIfNotExists Effect Policy Embedded ARM Template Test" -Tag 'DeployIfNotExistsTemplate' {
    It '[<fileName>] Embedded template Must have a valid schema' -TestCases ($script:testCases | where-Object {$_.policyEffect.effects -contains 'DeployIfNotExists'}) {
      param(
        [object] $json
      )
      $json.properties.policyRule.then.details.deployment.properties.template."`$schema" | Should -BeLike 'https://schema.management.azure.com/schemas/*'
    }
    It '[<fileName>] Embedded template Must contain a valid contentVersion' -TestCases ($script:testCases | where-Object {$_.policyEffect.effects -contains 'DeployIfNotExists'}) {
      param(
        [object] $json
      )
      $json.properties.policyRule.then.details.deployment.properties.template.contentVersion | Should -BeGreaterThan ([version]'0.0.0.1')
    }
    It "[<fileName>] Embedded template Must contain a 'parameters' element" -TestCases ($script:testCases | where-Object {$_.policyEffect.effects -contains 'DeployIfNotExists'}) {
      param(
        [object] $json
      )
      $json.properties.policyRule.then.details.deployment.properties.template.PSobject.Properties.name -match 'parameters' | Should -Not -Be $Null
    }
    It "[<fileName>] Embedded template Must contain a 'variables' element" -TestCases ($script:testCases | where-Object {$_.policyEffect.effects -contains 'DeployIfNotExists'}) {
      param(
        [object] $json
      )
      $json.properties.policyRule.then.details.deployment.properties.template.PSobject.Properties.name -match 'variables' | Should -Not -Be $Null
    }
    It "[<fileName>] Embedded template Must contain a 'resources' element" -TestCases ($script:testCases | where-Object {$_.policyEffect.effects -contains 'DeployIfNotExists'}) {
      param(
        [object] $json
      )
      $json.properties.policyRule.then.details.deployment.properties.template.PSobject.Properties.name -match 'resources' | Should -Not -Be $Null
    }
    It "[<fileName>] Embedded template Must contain a 'outputs' element" -TestCases ($script:testCases | where-Object {$_.policyEffect.effects -contains 'DeployIfNotExists'}) {
      param(
        [object] $json
      )
      $json.properties.policyRule.then.details.deployment.properties.template.PSobject.Properties.name -match 'outputs' | Should -Not -Be $Null
    }
  }

  Context "Modify Effect Configuration Test" -Tag 'ModifyConfig' {
    It "[<fileName>] Policy rule 'then' element Must contain a 'details' element" -TestCases ($script:testCases | where-Object {$_.policyEffect.effects -contains 'Modify'}) {
      param(
        [object] $json
      )
      $json.properties.policyRule.then.PSobject.Properties.name -match 'details' | Should -Not -Be $Null
    }
    It "[<fileName>] Policy rule must contain a 'roleDefinitionIds' element" -TestCases ($script:testCases | where-Object {$_.policyEffect.effects -contains 'Modify'}) {
      param(
        [object] $json
      )
      $json.properties.policyRule.then.details.PSobject.Properties.name -match 'roleDefinitionIds' | Should -Not -Be $Null
    }
    It "[<fileName>] 'roleDefinitionIds' element must contain at least one item" -TestCases ($script:testCases | where-Object {$_.policyEffect.effects -contains 'Modify'}) {
      param(
        [object] $json
      )
      $json.properties.policyRule.then.details.roleDefinitionIds.count | Should -BeGreaterThan 0
    }
    It "[<fileName>] Policy rule must contain a 'conflictEffect' element" -TestCases ($script:testCases | where-Object {$_.policyEffect.effects -contains 'Modify'}) {
      param(
        [object] $json
      )
      $json.properties.policyRule.then.details.PSobject.Properties.name -match 'conflictEffect' | Should -Not -Be $Null
    }
    It "[<fileName>] 'conflictEffect' element must have a valid value" -TestCases ($script:testCases | where-Object {$_.policyEffect.effects -contains 'Modify'}) {
      param(
        [object] $json
      )
      $global:modifyConflictEffectsValidValues -contains $json.properties.policyRule.then.details.conflictEffect | Should -Be $true
    }
    It "[<fileName>] Policy rule must contain an 'operations' element" -TestCases ($script:testCases | where-Object {$_.policyEffect.effects -contains 'Modify'}) {
      param(
        [object] $json
      )
      $json.properties.policyRule.then.details.PSobject.Properties.name -match 'operations' | Should -Not -Be $Null
    }
  }

  Context "AuditIfNotExists Effect Configuration Test" -Tag 'AuditIfNotExistsConfig' {
    It "[<fileName>] Policy rule 'then' element Must contain a 'details' element" -TestCases ($script:testCases | where-Object {$_.policyEffect.effects -contains 'AuditIfNotExists'}) {
      param(
        [object] $json
      )
      $json.properties.policyRule.then.PSobject.Properties.name -match 'details' | Should -Not -Be $Null
    }
    It "[<fileName>] Policy rule must contain a 'evaluationDelay' element" -TestCases ($script:testCases | where-Object {$_.policyEffect.effects -contains 'AuditIfNotExists'}) {
      param(
        [object] $json
      )
      $json.properties.policyRule.then.details.PSobject.Properties.name -match 'evaluationDelay' | Should -Not -Be $Null
    }
    It "[<fileName>] Policy rule must contain a 'existenceCondition' element" -TestCases ($script:testCases | where-Object {$_.policyEffect.effects -contains 'AuditIfNotExists'}) {
      param(
        [object] $json
      )
      $json.properties.policyRule.then.details.PSobject.Properties.name -match 'existenceCondition' | Should -Not -Be $Null
    }
  }
}
