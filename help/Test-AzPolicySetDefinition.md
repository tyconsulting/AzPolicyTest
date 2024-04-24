# Test-AzPolicySetDefinition

## SYNOPSIS
Perform Pester Test to test Azure Policy Initiative (aka. policy set) definitions

## SYNTAX

### NoOutputFile
```
Test-AzPolicySetDefinition -path <String> [<CommonParameters>]
```

### ProduceOutputFile
```
Test-AzPolicySetDefinition -path <String> -OutputFile <String> [-OutputFormat <String>] [<CommonParameters>]
```

## DESCRIPTION


## EXAMPLES

### EXAMPLE 1

```powershell
C:\PS> Test-AzPolicySetDefinition -Path "C:\PolicySetDefinitionFolder"
```

Test all Azure Policy Initiative definitions in a folder and its subfolders and display Pester result on the PowerShell host

### EXAMPLE 2

```powershell
C:\PS> Test-AzPolicySetDefinition -Path "C:\PolicySetDefinitionFolder\azurepolicyset.json" -OutputFile "C:\Temp\MyTestResult.xml"
```

Test a single Azure policy Initiative  definition and store the test result in a file

### EXAMPLE 3

```powershell
C:\PS> Test-AzPolicySetDefinition -Path "C:\PolicySetDefinitionFolder\azurepolicyset.json" -OutputFile "C:\Temp\MyTestResult.xml" -OutputFormat 'LegacyNUnitXML'
```

Test a single Azure policy Initiative definition and store the test result in a file with the 'LegacyNUnitXML' format

### EXAMPLE 4

```powershell
C:\PS> Test-AzPolicySetDefinition -Path "C:\PolicyDefinitionFolder\" -OutputFile "C:\Temp\MyTestResult.xml" -ExcludeTags 'ParametersMaxCount', 'ParametersMinCount'
```

Test all Azure Policy initiative definitions in a folder, exclude tests with the `ParametersMaxCount` and `ParametersMinCount` tags and store the test result in a file.

## PARAMETERS

### path
Specify the file paths for the policy definition files.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: true
Position: named
Default Value:
Pipeline Input: True (ByValue)
```

### ExcludeTags
Specify the tags for excluded tests.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: false
Position: named
Default Value: @()
Pipeline Input: false
```

### OutputFile


```yaml
Type: String
Parameter Sets: ProduceOutputFile
Aliases:

Required: true
Position: named
Default Value:
Pipeline Input: false
```

### OutputFormat


```yaml
Type: String
Parameter Sets: ProduceOutputFile
Aliases:

Required: false
Position: named
Default Value: NUnitXml
Accepted Values: NUnitXml
                 LegacyNUnitXML
Pipeline Input: False
```

### \<CommonParameters\>
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String


## OUTPUTS

### System.Object


## NOTES

## RELATED LINKS
