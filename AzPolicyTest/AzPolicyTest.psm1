# .EXTERNALHELP AzPolicyTest-help.xml
Function Test-JSONContent {
  [CmdLetBinding()]
  Param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ProduceOutputFile', HelpMessage = 'Specify the file paths for the policy definition files.')]
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'NoOutputFile', HelpMessage = 'Specify the file paths for the policy definition files.')]
    [String] $Path,

    [Parameter(Mandatory = $false, ParameterSetName = 'ProduceOutputFile', HelpMessage = 'Specify the excluded file paths for the policy definition files.')]
    [Parameter(Mandatory = $false, ParameterSetName = 'NoOutputFile', HelpMessage = 'Specify the excluded file paths for the policy definition files.')]
    [String[]] $ExcludePath,

    [Parameter(Mandatory = $false, ParameterSetName = 'ProduceOutputFile', HelpMessage = 'Specify the tags for excluded tests.')]
    [Parameter(Mandatory = $false, ParameterSetName = 'NoOutputFile', HelpMessage = 'Specify the tags for excluded tests.')]
    [String[]] $ExcludeTags = @(),

    [Parameter(ParameterSetName = 'ProduceOutputFile', Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $OutputFile,

    [Parameter(ParameterSetName = 'ProduceOutputFile', Mandatory = $false)]
    [ValidateSet('NUnitXml', 'LegacyNUnitXML')]
    [string] $OutputFormat = 'NUnitXml'
  )

  Begin {
    # Test files
    $FileContentTestFilePath = Join-Path $PSScriptRoot 'fileContent.tests.ps1'
    Write-Verbose "JSON Content Pester Test file Path: '$DefinitionStructureTestFilePath'" -verbose
  }

  Process {
    $testContainerData = @{
      path        = $Path
      excludePath = $ExcludePath
    }

    # Create Pester configuration
    $container = New-PesterContainer -Path $FileContentTestFilePath -Data $testContainerData
    $config = New-PesterConfiguration
    $config.Run.Container = $container
    $config.Run.PassThru = $true
    $config.Output.verbosity = 'Detailed'
    $config.TestResult.Enabled = $true
    $config.TestResult.TestSuiteName = 'Json Content Tests'
    $config.should.ErrorAction = 'Continue'

    # Configure Pester test result output based on parameter set name
    if ($PSCmdlet.ParameterSetName -eq 'ProduceOutputFile') {
      $config.TestResult.OutputFormat = $OutputFormat
      $config.TestResult.OutputPath = $OutputFile
    } else {
      $config.TestResult.Enabled = $false
    }

    # Configure Pester to exclude tags if present
    if ($ExcludeTags.count -gt 0) {
      $config.Filter.ExcludeTag = $ExcludeTags
    }

    # Invoke Pester
    Invoke-Pester -Configuration $config
  }
}

# .EXTERNALHELP AzPolicyTest-help.xml
Function Test-AzPolicyDefinition {
  [CmdLetBinding()]
  Param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ProduceOutputFile', HelpMessage = 'Specify the file paths for the policy definition files.')]
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'NoOutputFile', HelpMessage = 'Specify the file paths for the policy definition files.')]
    [String] $Path,

    [Parameter(Mandatory = $false, ParameterSetName = 'ProduceOutputFile', HelpMessage = 'Specify the excluded file paths for the policy definition files.')]
    [Parameter(Mandatory = $false, ParameterSetName = 'NoOutputFile', HelpMessage = 'Specify the excluded file paths for the policy definition files.')]
    [String[]] $ExcludePath,

    [Parameter(Mandatory = $false, ParameterSetName = 'ProduceOutputFile', HelpMessage = 'Specify the tags for excluded tests.')]
    [Parameter(Mandatory = $false, ParameterSetName = 'NoOutputFile', HelpMessage = 'Specify the tags for excluded tests.')]
    [String[]] $ExcludeTags = @(),

    [Parameter(ParameterSetName = 'ProduceOutputFile', Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $OutputFile,

    [Parameter(ParameterSetName = 'ProduceOutputFile', Mandatory = $false)]
    [ValidateSet('NUnitXml', 'LegacyNUnitXML')]
    [string] $OutputFormat = 'NUnitXml'
  )

  Begin {
    # Test files
    $DefinitionStructureTestFilePath = join-path $PSScriptRoot 'policyDefStructure.tests.ps1'
    Write-Verbose "Policy Definition Pester Test file Path: '$DefinitionStructureTestFilePath'" -verbose
  }

  Process {
    $testContainerData = @{
      path        = $Path
      excludePath = $ExcludePath
    }

    # Create Pester configuration
    $container = New-PesterContainer -Path $DefinitionStructureTestFilePath -Data $testContainerData
    $config = New-PesterConfiguration
    $config.Run.Container = $container
    $config.Run.PassThru = $true
    $config.Output.verbosity = 'Detailed'
    $config.TestResult.Enabled = $true
    $config.TestResult.TestSuiteName = 'Policy Definition Tests'
    $config.should.ErrorAction = 'Continue'

    # Configure Pester test result output based on parameter set name
    if ($PSCmdlet.ParameterSetName -eq 'ProduceOutputFile') {
      $config.TestResult.OutputFormat = $OutputFormat
      $config.TestResult.OutputPath = $OutputFile
    } else {
      $config.TestResult.Enabled = $false
    }

    # Configure Pester to exclude tags if present
    if ($ExcludeTags.count -gt 0) {
      $config.Filter.ExcludeTag = $ExcludeTags
    }

    # Invoke Pester
    Invoke-Pester -Configuration $config
  }
}

# .EXTERNALHELP AzPolicyTest-help.xml
Function Test-AzPolicySetDefinition {
  [CmdLetBinding()]
  Param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ProduceOutputFile', HelpMessage = 'Specify the file paths for the policy set definition files.')]
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'NoOutputFile', HelpMessage = 'Specify the file paths for the policy set definition files.')]
    [String] $Path,

    [Parameter(Mandatory = $false, ParameterSetName = 'ProduceOutputFile', HelpMessage = 'Specify the excluded file paths for the policy set definition files.')]
    [Parameter(Mandatory = $false, ParameterSetName = 'NoOutputFile', HelpMessage = 'Specify the excluded file paths for the policy set definition files.')]
    [String[]] $ExcludePath,

    [Parameter(Mandatory = $false, ParameterSetName = 'ProduceOutputFile', HelpMessage = 'Specify the tags for excluded tests.')]
    [Parameter(Mandatory = $false, ParameterSetName = 'NoOutputFile', HelpMessage = 'Specify the tags for excluded tests.')]
    [String[]] $ExcludeTags = @(),

    [Parameter(ParameterSetName = 'ProduceOutputFile', Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $OutputFile,

    [Parameter(ParameterSetName = 'ProduceOutputFile', Mandatory = $false)]
    [ValidateSet('NUnitXml', 'LegacyNUnitXML')]
    [string] $OutputFormat = 'NUnitXml'
  )

  Begin {
    # Test files
    $DefinitionStructureTestFilePath = join-path $PSScriptRoot 'policySetDefStructure.tests.ps1'
    Write-Verbose "Policy Initiative Pester Test file Path: '$DefinitionStructureTestFilePath'" -verbose
  }

  Process {
    $testContainerData = @{
      path        = $Path
      excludePath = $ExcludePath
    }

    # Create Pester configuration
    $container = New-PesterContainer -Path $DefinitionStructureTestFilePath -Data $testContainerData
    $config = New-PesterConfiguration
    $config.Run.Container = $container
    $config.Run.PassThru = $true
    $config.Output.verbosity = 'Detailed'
    $config.TestResult.Enabled = $true
    $config.TestResult.TestSuiteName = 'JPolicy Initiative Tests'
    $config.should.ErrorAction = 'Continue'

    # Configure Pester test result output based on parameter set name
    if ($PSCmdlet.ParameterSetName -eq 'ProduceOutputFile') {
      $config.TestResult.OutputFormat = $OutputFormat
      $config.TestResult.OutputPath = $OutputFile
    } else {
      $config.TestResult.Enabled = $false
    }

    # Configure Pester to exclude tags if present
    if ($ExcludeTags.count -gt 0) {
      $config.Filter.ExcludeTag = $ExcludeTags
    }

    # Invoke Pester
    Invoke-Pester -Configuration $config
  }
}

Function GetRelativeFilePath {
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ })]
    [String] $Path
  )
  # Try to get git root directory
  if ((Get-Item $Path).PSIsContainer) {
    $gitRoot = GetGitRoot -path $Path
  } else {
    $gitRoot = GetGitRoot -path (Get-Item $Path).Directory
  }
  if ($gitRoot) {
    $relativePath = Resolve-Path -Path $Path -RelativeBasePath $gitRoot -Relative
  } else {
    $relativePath = $Path
  }
  $relativePath
}

Function GetGitRoot {
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, HelpMessage = 'Specify the folder path.')]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [String] $Path
  )

  Begin {
    # Store the current Directory in a variable
    $currentDir = [string] $pwd
  }

  Process {
    # Change the working directory to the specified path
    Set-Location -Path $Path

    # Check if the current directory is inside a git repository
    try {
      $isGitRepo = [string](& 'git' 'rev-parse' '--is-inside-work-tree' 2>$null)
    } catch {
      $isGitRepo = [string] 'false'
    }
    if ($isGitRepo -eq 'true') {
      # Get the root directory of the git repository
      $gitRootDir = [string](& 'git' 'rev-parse' '--show-toplevel' 2>&1)
      if (Test-Path -PathType 'Container' -Path $gitRootDir) {
        $gitRootDir = Convert-Path $gitRootDir
      }
    } else {
      Write-Verbose "The specified path '$Path' is not inside a git repository or git command tool is not installed."
    }

    # Change the working directory back to the original directory
    Set-Location -Path $currentDir
    $gitRootDir
  }
}

Function GetKnownLimitations {
  $file = Join-Path $PSScriptRoot 'AzPolicyTest.limitations.jsonc'
  if (Test-Path $file) {
    $content = Get-Content $file -Raw | ConvertFrom-Json -AsHashtable -Depth 5
    return $content
  } else {
    Write-Verbose "Limitations file not found: $file"
    return $null
  }
}
