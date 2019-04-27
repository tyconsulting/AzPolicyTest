# .EXTERNALHELP AzPolicyTest.psm1-Help.xml
Function Test-JSONContent
{
  [CmdLetBinding()]
  Param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ProduceOutputFile', HelpMessage = 'Specify the file paths for the policy definition files.')]
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'NoOutputFile', HelpMessage = 'Specify the file paths for the policy definition files.')]
    [String]$path,

    [Parameter(ParameterSetName = 'ProduceOutputFile', Mandatory=$true)][ValidateNotNullOrEmpty()][string]$OutputFile,
		[Parameter(ParameterSetName = 'ProduceOutputFile', Mandatory=$false)][ValidateSet('NUnitXml', 'LegacyNUnitXML')][string]$OutputFormat='NUnitXml'
  )
  #Test files
  $FileContentTestFilePath = Join-Path $PSScriptRoot '\common-tests\fileContent.tests.ps1'

  #File Content tests
  If ($PSCmdlet.ParameterSetName -eq 'ProduceOutputFile')
  {
    #Common - File content tests
    $FileContentTestResult = Invoke-Pester -script @{path = $FileContentTestFilePath; Parameters=@{path = $path}} -OutputFile $OutputFile -OutputFormat $OutputFormat -PassThru
  } else {
    $FileContentTestResult = Invoke-Pester -script @{path = $FileContentTestFilePath; Parameters=@{path = $path}} -PassThru
  }
  if ($FileContentTestResult.TestResult.Result -ieq 'failed')
  {
    Write-Error "File content test failed."
  }
}

# .EXTERNALHELP AzPolicyTest.psm1-Help.xml
Function Test-AzPolicyDefinition
{
  [CmdLetBinding()]
  Param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ProduceOutputFile', HelpMessage = 'Specify the file paths for the policy definition files.')]
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'NoOutputFile', HelpMessage = 'Specify the file paths for the policy definition files.')]
    [String]$path,

    [Parameter(ParameterSetName = 'ProduceOutputFile', Mandatory=$true)][ValidateNotNullOrEmpty()][string]$OutputFile,
    [Parameter(ParameterSetName = 'ProduceOutputFile', Mandatory=$false)][ValidateSet('NUnitXml', 'LegacyNUnitXML')][string]$OutputFormat='NUnitXml'
  )
  #Test files
  $DefinitionStructureTestFilePath = join-path $PSScriptRoot '\policy-tests\policyDefStructure.tests.ps1'
  Write-Verbose "Testing '$definitionFile'..."
  #File Content tests
  If ($PSCmdlet.ParameterSetName -eq 'ProduceOutputFile')
  {
    #Common - File content tests
    $DefinitionStructureTestResult = Invoke-Pester -script @{path = $DefinitionStructureTestFilePath; Parameters=@{path = $path}} -OutputFile $OutputFile -OutputFormat $OutputFormat -PassThru
  } else {
    $DefinitionStructureTestResult = Invoke-Pester -script @{path = $DefinitionStructureTestFilePath; Parameters=@{path = $path}} -PassThru
  }
  if ($DefinitionStructureTestResult.TestResult.Result -ieq 'failed')
  {
    Write-Error "Policy Definition Syntax test failed."
  }
}

# .EXTERNALHELP AzPolicyTest.psm1-Help.xml
Function Test-AzPolicySetDefinition
{
  [CmdLetBinding()]
  Param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ProduceOutputFile', HelpMessage = 'Specify the file paths for the policy definition files.')]
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'NoOutputFile', HelpMessage = 'Specify the file paths for the policy definition files.')]
    [String]$path,

    [Parameter(ParameterSetName = 'ProduceOutputFile', Mandatory=$true)][ValidateNotNullOrEmpty()][string]$OutputFile,
    [Parameter(ParameterSetName = 'ProduceOutputFile', Mandatory=$false)][ValidateSet('NUnitXml', 'LegacyNUnitXML')][string]$OutputFormat='NUnitXml'
  )
  #Test files
  $DefinitionStructureTestFilePath = join-path $PSScriptRoot '\policySet-tests\policySetDefStructure.tests.ps1'
  Write-Verbose "Testing '$definitionFile'..."
  #File Content tests
  If ($PSCmdlet.ParameterSetName -eq 'ProduceOutputFile')
  {
    #Common - File content tests
    $DefinitionStructureTestResult = Invoke-Pester -script @{path = $DefinitionStructureTestFilePath; Parameters=@{path = $path}} -OutputFile $OutputFile -OutputFormat $OutputFormat -PassThru
  } else {
    $DefinitionStructureTestResult = Invoke-Pester -script @{path = $DefinitionStructureTestFilePath; Parameters=@{path = $path}} -PassThru
  }
  if ($DefinitionStructureTestResult.TestResult.Result -ieq 'failed')
  {
    Write-Error "Policy Set Definition Syntax test failed."
  }
}