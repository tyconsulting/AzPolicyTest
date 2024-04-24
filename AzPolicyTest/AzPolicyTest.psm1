# .EXTERNALHELP AzPolicyTest.psm1-Help.xml
Function Test-JSONContent {
  [CmdLetBinding()]
  Param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ProduceOutputFile', HelpMessage = 'Specify the file paths for the policy definition files.')]
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'NoOutputFile', HelpMessage = 'Specify the file paths for the policy definition files.')]
    [String]$path,

    [Parameter(ParameterSetName = 'ProduceOutputFile', Mandatory = $true)][ValidateNotNullOrEmpty()][string]$OutputFile,
    [Parameter(ParameterSetName = 'ProduceOutputFile', Mandatory = $false)][ValidateSet('NUnitXml', 'LegacyNUnitXML')][string]$OutputFormat = 'NUnitXml'
  )
  #Test files
  $FileContentTestFilePath = Join-Path $PSScriptRoot 'fileContent.tests.ps1'
  Write-Verbose "JSON Content Pester Test file Path: '$DefinitionStructureTestFilePath'" -verbose
  $testContainerData = @{
    path = $path
  }
  $config = @{
    Run = @{
      Container = New-PesterContainer -Path $FileContentTestFilePath -Data $testContainerData
      PassThru = $true
    }
    TestResult = @{
      TestSuiteName = 'Json Content Tests'
      Enabled = $true
    }
    Output     = @{
      Verbosity = 'Detailed'
    }
    Should = @{
        ErrorAction = 'Continue'
    }
  }
  #File Content tests
  If ($PSCmdlet.ParameterSetName -eq 'ProduceOutputFile') {
    $config.TestResult.Add('OutputFormat', $OutputFormat)
    $config.TestResult.Add('OutputPath', $OutputFile)
  }

  Invoke-Pester -Configuration $config
}

# .EXTERNALHELP AzPolicyTest.psm1-Help.xml
Function Test-AzPolicyDefinition {
  [CmdLetBinding()]
  Param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ProduceOutputFile', HelpMessage = 'Specify the file paths for the policy definition files.')]
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'NoOutputFile', HelpMessage = 'Specify the file paths for the policy definition files.')]
    [String]$path,

    [Parameter(ParameterSetName = 'ProduceOutputFile', Mandatory = $true)][ValidateNotNullOrEmpty()][string]$OutputFile,
    [Parameter(ParameterSetName = 'ProduceOutputFile', Mandatory = $false)][ValidateSet('NUnitXml', 'LegacyNUnitXML')][string]$OutputFormat = 'NUnitXml'
  )
  #Test files
  $DefinitionStructureTestFilePath = join-path $PSScriptRoot 'policyDefStructure.tests.ps1'
  Write-Verbose "Policy Definition Pester Test file Path: '$DefinitionStructureTestFilePath'" -verbose

  $testContainerData = @{
    path = $path
  }
  $config = @{
    Run = @{
      Container = New-PesterContainer -Path $DefinitionStructureTestFilePath -Data $testContainerData
      PassThru = $true
    }
    TestResult = @{
      TestSuiteName = 'Policy Definition Tests'
      Enabled = $true
    }
    Output     = @{
      Verbosity = 'Detailed'
    }
    Should = @{
      ErrorAction = 'Continue'
    }
  }

  #File Content tests
  If ($PSCmdlet.ParameterSetName -eq 'ProduceOutputFile') {
    #Common - File content tests
    $config.TestResult.Add('OutputFormat', $OutputFormat)
    $config.TestResult.Add('OutputPath', $OutputFile)
  }

  Invoke-Pester -Configuration $config
}

# .EXTERNALHELP AzPolicyTest.psm1-Help.xml
Function Test-AzPolicySetDefinition {
  [CmdLetBinding()]
  Param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ProduceOutputFile', HelpMessage = 'Specify the file paths for the policy definition files.')]
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'NoOutputFile', HelpMessage = 'Specify the file paths for the policy definition files.')]
    [String]$path,

    [Parameter(ParameterSetName = 'ProduceOutputFile', Mandatory = $true)][ValidateNotNullOrEmpty()][string]$OutputFile,
    [Parameter(ParameterSetName = 'ProduceOutputFile', Mandatory = $false)][ValidateSet('NUnitXml', 'LegacyNUnitXML')][string]$OutputFormat = 'NUnitXml'
  )
  #Test files
  $DefinitionStructureTestFilePath = join-path $PSScriptRoot 'policySetDefStructure.tests.ps1'
  Write-Verbose "Policy Initiative Pester Test file Path: '$DefinitionStructureTestFilePath'" -verbose

  $testContainerData = @{
    path = $path
  }
  $config = @{
    Run = @{
      Container = New-PesterContainer -Path $DefinitionStructureTestFilePath -Data $testContainerData
      PassThru = $true
    }
    TestResult = @{
      TestSuiteName = 'Policy Initiative Tests'
      Enabled = $true
    }
    Output     = @{
      Verbosity = 'Detailed'
    }
    Should = @{
      ErrorAction = 'Continue'
    }
  }

  #File Content tests
  If ($PSCmdlet.ParameterSetName -eq 'ProduceOutputFile') {
    #Common - File content tests
    $config.TestResult.Add('OutputFormat', $OutputFormat)
    $config.TestResult.Add('OutputPath', $OutputFile)
  }

  Invoke-Pester -Configuration $config
}

Function GetRelativeFilepath {
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory = $true)]
    [String]$path,

    [Parameter(Mandatory = $true)]
    [String]$relativeBasePath
  )
  $relativePath = Resolve-Path -Path $path -RelativeBasePath $relativeBasePath -Relative
  $relativePath
}

Function GetGitRoot {
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, HelpMessage = 'Specify the folder path.')]
    [ValidateScript({Test-Path $_ -PathType Container})]
    [String]$path
  )
  #store the current Directory in a variable
  $currentDir = $pwd

  #Change the working directory to the specified path
  Set-Location $path

  #Check if the current directory is inside a git repository
  try {
    $isGitRepo = Invoke-Expression 'git rev-parse --is-inside-work-tree 2>&1' -ErrorAction SilentlyContinue
  } catch {
    $isGitRepo = 'false'
  }
  if ($isGitRepo -eq 'true') {
    #Get the root directory of the git repository
    $gitRootDir = Invoke-expression 'git rev-parse --show-toplevel 2>&1' -ErrorAction SilentlyContinue
    if (Test-Path $gitRootDir) {
      $gitRootDir = Convert-Path $gitRootDir
    }
  } else {
    Write-Warning "The specified path '$path' is not inside a git repository or git command tool is not installed."
  }

  #Change the working directory back to the original directory
  Set-Location $currentDir
  $gitRootDir
}