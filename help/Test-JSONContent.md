# Test-JSONContent

## SYNOPSIS
Perform Pester Test to validate syntax of JSON files.

## SYNTAX

### NoOutputFile
```
Test-JSONContent -path <String> [<CommonParameters>]
```

### ProduceOutputFile
```
Test-JSONContent -path <String> -OutputFile <String> [-OutputFormat <String>] [<CommonParameters>]
```

## DESCRIPTION


## EXAMPLES

### EXAMPLE 1

```powershell
C:\PS> Test-JSONContent -Path "C:\PolicyDefinitionFolder"
```

Perform JSON Syntax testing on all JSON files in a folder and its subfolders and display Pester result on the PowerShell host

### EXAMPLE 2

```powershell
C:\PS> Test-JSONContent -Path "C:\PolicyDefinitionFolder\azurepolicy.json" -OutputFile "C:\Temp\MyTestResult.xml"
```

Perform JSON Syntax testing on a single Azure Policy definition file store the test result in a file

### EXAMPLE 3

```powershell
C:\PS> Test-JSONContent -Path "C:\PolicySetDefinitionFolder\azurepolicyset.json" -OutputFile "C:\Temp\MyTestResult.xml" -OutputFormat 'LegacyNUnitXML'
```

Perform JSON Syntax testing on a single Azure Policy Initiative definition file store the test result in a file with the 'LegacyNUnitXML' format

### EXAMPLE 4

```powershell
C:\PS> Test-JSONContent -Path "C:\PolicyDefinitionFolder\" -OutputFile "C:\Temp\MyTestResult.xml" -ExcludeTags 'JsonSyntax'
```

Perform JSON Syntax testing on all JSON files in a folder and its subfolders, exclude test with the `JsonSyntax` tag and store the test result in a file.

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
