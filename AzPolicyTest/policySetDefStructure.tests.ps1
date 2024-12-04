[CmdletBinding()]
Param (
  [Parameter(Mandatory = $true)][validateScript({ Test-Path $_ })][string]$Path,
  [Parameter(Mandatory = $false)][string[]]$excludePath
)
Write-Verbose "Path: '$Path'"

function CountPolicyDefinitionReferenceId {
  param(
    [object] $policySetObject,
    [string] $policyDefinitionReferenceId
  )
  $policy = $policySetObject.properties.policyDefinitions | where-object { $_.policyDefinitionReferenceId -ieq $policyDefinitionReferenceId }
  $policy.count
}

function IsParameterInUse {
  param(
    [object] $policySetObject,
    [string] $parameterName
  )
  $parameterRegex = "parameters\(\'($parameterName)\'\)"
  $bIsInUse = $false
  Foreach ($policyObject in $policySetObject.properties.policyDefinitions) {
    foreach ($name in $policyObject.parameters.PSObject.Properties.Name) {
      if ($policyObject.parameters.$name.value -imatch $parameterRegex) {
        $bIsInUse = $true
        break
      }
    }
    if ($bIsInUse) {
      break
    }
  }
  $bIsInUse
}

function IsParameterDefined {
  param(
    [object] $policySetObject,
    [string] $parameter
  )
  $bIsDefined = $false
  Foreach ($p in $policySetObject.properties.parameters.PSObject.Properties) {
    if ($p.Name -ieq $parameter) {
      $bIsDefined = $true
      break
    }
  }
  $bIsDefined
}

# Variables
$TestName = 'Policy Set Definition Syntax Test'

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
    $files = $files | where-object { $_.FullName -notmatch $excludePath }
  }
} else {
  Write-Verbose "Specified path '$path' is a file"
  $files = Get-Item $path -Include '*.json', '*.jsonc'
}

Foreach ($file in $files) {
  Write-Verbose "Test '$file'" -verbose
  $fileName = (get-item $file).name
  $fileFullName = (get-item $file).FullName
  $fileRelativePath = GetRelativeFilePath -path $fileFullName
  $json = ConvertFrom-Json -InputObject (Get-Content -Path $file -Raw) -ErrorAction SilentlyContinue
  $testCase = @{
    fileName         = $fileName
    json             = $json
    fileRelativePath = $fileRelativePath
  }
  Describe "[$fileRelativePath]:: $TestName" -Tag 'policyDefSyntax' {
    BeforeAll {
      $ValidParameterTypes = [string[]](
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
      It -Name 'Should contain top-level element - name' -TestCases $testCase -Test {
        param(
          [object] $json
        )
        $json.PSobject.Properties.name -cmatch 'name' | Should -Not -Be $Null
      }

      It -Name 'Should contain top-level element - properties' -TestCases $testCase -Test {
        param(
          [object] $json
        )
        $json.PSobject.Properties.name -cmatch 'properties' | Should -Not -Be $Null
      }
    }

    Context 'Policy Set Definition Elements Value Test' -Tag 'PolicySetElements' {
      It -Name 'Name value must not be null' -TestCases $testCase -Test {
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

      It -Name 'Name value must not contain spaces' -TestCases $testCase -Test {
        param(
          [object] $json
        )
        $json.name -match ' ' | Should -Be $false
      }

      It -Name 'Name value must not contain forbidden characters' -TestCases $testCase -Tag 'NameForbiddenCharacters' -Test {
        param(
          [object] $json
        )
        $json.name -match '[<>*%&:\\?.+\/]' | Should -Be $false
      }
    }

    Context 'Policy Set Definition Properties Value Test' -Tag 'PolicySetProperties' {
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

      It -Name "'parameters' element must contain no more than four hundred (400) items" -TestCases $testCase -Tag 'ParametersMaxCount' -Test {
        param(
          [object] $json
        )
        $json.properties.parameters.PSObject.Properties.count | Should -BeLessOrEqual 400
      }

      It -Name "Properties must contain 'policyDefinitions' element" -TestCases $testCase -Tag 'PolicyDefinitionsExists' -Test {
        param(
          [object] $json
        )
        $json.properties.PSobject.Properties.name -cmatch 'policyDefinitions' | Should -Not -Be $Null
      }

      It -Name "'policyDefinitions' element must contain at least one item" -TestCases $testCase -Tag 'PolicyDefinitionsCount' -Test {
        param(
          [object] $json
        )
        $json.properties.policyDefinitions.count | Should -BeGreaterThan 0
      }

      It -Name "Properties must contain 'policyDefinitionGroups' element" -TestCases $testCase -Tag 'PolicyDefinitionGroupsExists' -Test {
        param(
          [object] $json
        )
        $json.properties.PSobject.Properties.name -cmatch 'policyDefinitionGroups' | Should -Not -Be $Null
      }

      It -Name "'policyDefinitionGroups' element must contain at least one item" -TestCases $testCase -Tag 'PolicyDefinitionGroupsCount' -Test {
        param(
          [object] $json
        )
        $json.properties.policyDefinitionGroups.count | Should -BeGreaterThan 0
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

      It -Name "Must contain 'Category' metadata" -TestCases $testCase -Test {
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

      It -Name "'Version' metadata value must be a valid semantic version" -TestCases $testCase -Tag 'ValidSemanticVersion' -Test {
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
          parameterInUse  = IsParameterInUse -policySetObject $json -parameterName $parameterName
        }

        It -Name "Parameter [<parameterName>] must contain 'type' element" -TestCases $parameterTestCase -Tag 'ParameterTypeExists' -Test {
          param(
            [string] $parameterName,
            [object] $parameterConfig
          )
          $parameterConfig.PSobject.Properties.name -cmatch 'type' | Should -Not -Be $null
        }

        It -Name 'Parameter [<parameterName>] default value must be a member of allowed values' -TestCases (
          $parameterTestCase | where-Object { $_.parameterConfig.PSObject.properties.name -icontains 'allowedValues' -and $_.parameterConfig.PSObject.properties.name -icontains 'defaultValue' }
        ) -Tag 'ParameterDefaultValueValid' -Test {
          param(
            [string] $parameterName,
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
            [string] $parameterName,
            [object] $parameterConfig
          )
          $ValidParameterTypes -contains $parameterConfig.type.tolower() | Should -Be $true
        }

        It -Name "Parameter [<parameterName>] metadata must contain 'displayName' element" -TestCases $parameterTestCase -Tag 'ParameterDisplayNameExists' -Test {
          param(
            [string] $parameterName,
            [object] $parameterConfig
          )
          $parameterConfig.metadata.PSobject.Properties.name -cmatch 'displayName' | Should -Not -Be $null
        }

        It -Name "Parameter [<parameterName>] metadata must contain 'description' element" -TestCases $parameterTestCase -Tag 'ParameterDescriptionExists' -Test {
          param(
            [string] $parameterName,
            [object] $parameterConfig
          )
          $parameterConfig.metadata.PSobject.Properties.name -cmatch 'description' | Should -Not -Be $null
        }

        It -Name 'Parameter [<parameterName>] must not be unused' -TestCases $parameterTestCase -Tag 'ParameterNotUnused' -Test {
          param(
            [string] $parameterName,
            [boolean] $parameterInUse
          )
          $parameterInUse | Should -Be $true
        }
      }
    }

    Context 'Policy Definitions Test' -Tag 'PolicyDefinitions' {
      $i = 0
      foreach ($policyDefinition in $json.properties.policyDefinitions) {
        $i++
        try {
          $policyDefinitionReferenceId = $policyDefinition.policyDefinitionReferenceId
          $policyDefTestTitle = "Policy Definition #$i ($policyDefinitionReferenceId)"
        } catch {
          $policyDefTestTitle = "Policy Definition #$i"
        }

        $policyDefinitionTestCase = @{
          policyDefinition                 = $policyDefinition
          policyDefinitionReferenceIdCount = CountPolicyDefinitionReferenceId -policySetObject $json -policyDefinitionReferenceId $policyDefinition.policyDefinitionReferenceId
        }

        It -Name "$policyDefTestTitle must contain 'policyDefinitionId' element" -TestCases $policyDefinitionTestCase -Tag 'PolicyDefinitionIdExists' -Test {
          param(
            [object] $policyDefinition
          )
          $policyDefinition.PSobject.properties.name -cmatch 'policyDefinitionId' | Should -Not -Be $null
        }

        It -Name "'policyDefinitionId' in $policyDefTestTitle must contain value" -TestCases $policyDefinitionTestCase -Tag 'PolicyDefinitionIdNotEmpty' -Test {
          param(
            [object] $policyDefinition
          )
          $policyDefinition.policyDefinitionId.length | Should -BeGreaterThan 0
        }

        It -Name "$policyDefTestTitle must contain 'policyDefinitionReferenceId' element" -TestCases $policyDefinitionTestCase -Tag 'policyDefinitionReferenceIdExists' -Test {
          param(
            [object] $policyDefinition
          )
          $policyDefinition.PSobject.properties.name -cmatch 'policyDefinitionReferenceId' | Should -Not -Be $null
        }

        It -Name "'policyDefinitionReferenceId' in $policyDefTestTitle must contain value" -TestCases $policyDefinitionTestCase -Tag 'policyDefinitionReferenceIdNotEmpty' -Test {
          param(
            [object] $policyDefinition
          )
          $policyDefinition.policyDefinitionReferenceId.length | Should -BeGreaterThan 0
        }
        It -Name "'policyDefinitionReferenceId' in $policyDefTestTitle must be only used One (1) time" -TestCases $policyDefinitionTestCase -Tag 'noDuplicatePolicyDefinitionReferenceId' -Test {
          param(
            [object] $policyDefinition,
            [int]$policyDefinitionReferenceIdCount
          )
          $policyDefinitionReferenceIdCount | Should -Be 1
        }

        It -Name "$policyDefTestTitle must contain 'parameters' element" -TestCases $policyDefinitionTestCase -Tag 'PolicyDefinitionParameterExists' -Test {
          param(
            [object] $policyDefinition
          )
          $policyDefinition.PSobject.properties.name -cmatch 'parameters' | Should -Not -Be $null
        }

        It -Name "'parameters' in $policyDefTestTitle must contain at least one item" -TestCases $policyDefinitionTestCase -Tag 'PolicyDefinitionParameterNotEmpty' -Test {
          param(
            [object] $policyDefinition
          )
          $policyDefinition.parameters.PSObject.Properties.count | Should -BeGreaterThan 0
        }

        foreach ($p in $policyDefinition.parameters.PSObject.Properties) {
          $parameterName = $p.Name
          $parameterConfig = $policyDefinition.parameters.$parameterName
          $parameterValue = $policyDefinition.parameters.$parameterName.value
          # Check if the parameter value is from the parameter of the initiative
          $valueExpectedFromInitiativeParameters = $false
          if ($parameterValue -imatch "parameters\(\'(\S+)\'\)") {
            $passedInParameter = $matches[1]
            $valueExpectedFromInitiativeParameters = $true
          }
          $parameterIsDefinedTestCase = @{
            passedInParameter                     = $passedInParameter
            parameterConfig                       = $parameterConfig
            parameterIsDefined                    = IsParameterDefined -policySetObject $json -parameter $passedInParameter
            valueExpectedFromInitiativeParameters = $valueExpectedFromInitiativeParameters
          }

          It -Name "Passed-in Parameter [<passedInParameter>] in $policyDefTestTitle must be defined in the Initiative Parameters" -TestCases (
            $parameterIsDefinedTestCase | where-object {$_.valueExpectedFromInitiativeParameters -eq $true}
          ) -Tag 'PolicyDefinitionParameterIsDefined' -Test {
            param(
              [string] $parameterName,
              [object] $parameterConfig
            )
            $parameterIsDefined | Should -Be $true
          }
        }

        It -Name "$policyDefTestTitle must contain 'groupNames' element" -TestCases $policyDefinitionTestCase -Tag 'PolicyDefinitionGroupNamesExists' -Test {
          param(
            [object] $policyDefinition
          )
          $policyDefinition.PSobject.properties.name -cmatch 'groupNames' | Should -Not -Be $null
        }

        It -Name "'groupNames' in $policyDefTestTitle must contain at least one item" -TestCases $policyDefinitionTestCase -Tag 'PolicyDefinitionGroupNamesNotEmpty' -Test {
          param(
            [object] $policyDefinition
          )
          $policyDefinition.groupNames.count | Should -BeGreaterThan 0
        }
      }
    }
  }
}
