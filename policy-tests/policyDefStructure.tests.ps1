[CmdletBinding()]
Param (
	[Parameter(Mandatory=$true)][validateScript({Test-Path $_})][string]$Path
)
Write-Verbose "Path: '$Path'"
#region variables
$TestName = "Policy Definition Syntax Test"
$requiredElements = New-object System.Collections.ArrayList
$requiredProperties = New-Object System.Collections.ArrayList
$optionalElements = New-Object System.Collections.ArrayList
[void]$requiredElements.Add('type')
[void]$requiredElements.Add('name')
[void]$requiredElements.Add('properties')
[void]$requiredProperties.Add('displayName')
[void]$requiredProperties.Add('description')
#endregion
if ((Get-Item $path).PSIsContainer)
{
    Write-Verbose "Specified path '$path' is a directory"
    $files = Get-ChildItem $Path -Include *.json -Recurse
} else {
    Write-Verbose "Specified path '$path' is a file"
    $files = Get-Item $path -Include *.json
}

Foreach ($file in $files)
{
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
        Context "Policy Definition Elements Value Test" {
            It "Name value must not be null" {
                $json.name.length| Should BeGreaterThan 0
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
            It "Properties must contain 'policyRule' element" {
                $json.properties.PSobject.Properties.name -match 'policyRule' | Should Not Be $Null
            }
            It "'DisplayName' value must not be blank" {
                $json.properties.displayName.length | Should Not Be 0
            }
            It "'Description' value must not be blank" {
                $json.properties.description.length | Should Not Be 0
            }
            It "Must contain 'Category' metadata" {
                $json.properties.metadata.category.length| Should Not Be 0
            }
        }
        Context "Policy Rule Test" {
            It "Policy Rule must contain 'if' element" {
                $json.properties.policyRule.PSobject.Properties.name -match 'if' | Should Not Be $Null
            }
            It "Policy Rule must contain 'then' element" {
                $json.properties.policyRule.PSobject.Properties.name -match 'then' | Should Not Be $Null
            }
            It "Policy Rule must use a valid effect" {
                'Deny', 'Audit', 'Append', 'AuditIfNotExists', 'DeployIfNotExists', 'Disabled' -match $json.properties.policyRule.then.effect  | Should Not Be $Null
            }
        }
        if ($json.properties.policyRule.then.effect -ieq 'DeployIfNotExists')
        {
            Context "DeployIfNotExists Configuration Test" {
                It "Policy rule 'then' element Must contain a 'details' element" {
                    $json.properties.policyRule.then.PSobject.Properties.name -match 'details' | Should Not Be $Null
                }
                It "DeployIfNotExists' Policy rule must contain a embedded 'deployment' element" {
                    $json.properties.policyRule.then.details.PSobject.Properties.name -match 'deployment' | Should Not Be $Null
                }
                It "Deployment mode for 'DeployIfNotExists' effect must be 'incremental'" {
                    $json.properties.policyRule.then.details.deployment.properties.mode -match 'incremental' | Should Not Be $Null
                }
                It "DeployIfNotExists' Policy rule must contain a 'roleDefinitionIds' element" {
                    $json.properties.policyRule.then.details.PSobject.Properties.name -match 'roleDefinitionIds' | Should Not Be $Null
                }
                It "'roleDefinitionIds' element must contain at least one item" {
                    $json.properties.policyRule.then.details.roleDefinitionIds.count | Should -BeGreaterThan 0
                }
            }
            Context "DeployIfNotExists Embedded ARM Template Test" {
                It 'Embedded template Must have a valid schema' {
                    $json.properties.policyRule.then.details.deployment.properties.template."`$schema" | Should -BeLike 'http://schema.management.azure.com/schemas/*'
                }
                It 'Embedded template Must contain a valid contentVersion' {
                    $json.properties.policyRule.then.details.deployment.properties.template.contentVersion | Should -BeGreaterThan ([version]'0.0.0.1')
                }
                It "Embedded template Must contain a 'parameters' element" {
                    $json.properties.policyRule.then.details.deployment.properties.template.PSobject.Properties.name -match 'parameters' | Should Not Be $Null
                }
                It "Embedded template Must contain a 'variables' element" {
                    $json.properties.policyRule.then.details.deployment.properties.template.PSobject.Properties.name -match 'variables' | Should Not Be $Null
                }
                It "Embedded template Must contain a 'resources' element" {
                    $json.properties.policyRule.then.details.deployment.properties.template.PSobject.Properties.name -match 'resources' | Should Not Be $Null
                }
                It "Embedded template Must contain a 'outputs' element" {
                    $json.properties.policyRule.then.details.deployment.properties.template.PSobject.Properties.name -match 'outputs' | Should Not Be $Null
                }
            }
        }
    }
}