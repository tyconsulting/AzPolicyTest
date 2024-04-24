---
external help file: AzPolicyTest.psm1-Help.xml
Module Name: AzPolicyTest
online version: https://github.com/tyconsulting/AzPolicyTest/blob/master/help/Test-AzPolicyDefinition.md
schema: 2.0.0
---

# Test-AzPolicyDefinition

## SYNOPSIS
Perform Pester Test to test Azure Policy definitions

## SYNTAX

### NoOutputFile
```
Test-AzPolicyDefinition -path <String> [-ExcludeTags <String[]>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### ProduceOutputFile
```
Test-AzPolicyDefinition -path <String> [-ExcludeTags <String[]>] -OutputFile <String> [-OutputFormat <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

## EXAMPLES

### EXAMPLE 1

```powershell
C:\PS> Test-AzPolicyDefinition -Path "C:\PolicyDefinitionFolder"
```

Test all Azure Policy definitions in a folder and its subfolders and display Pester result on the PowerShell host

### EXAMPLE 2

```powershell
C:\PS> Test-AzPolicyDefinition -Path "C:\PolicyDefinitionFolder\azurepolicy.json" -OutputFile "C:\Temp\MyTestResult.xml"
```

Test a single Azure policy definition and store the test result in a file

### EXAMPLE 3

```powershell
C:\PS> Test-AzPolicyDefinition -Path "C:\PolicyDefinitionFolder\azurepolicy.json" -OutputFile "C:\Temp\MyTestResult.xml" -OutputFormat 'LegacyNUnitXML'
```

Test a single Azure policy definition and store the test result in a file with the 'LegacyNUnitXML' format

### EXAMPLE 4

```powershell
C:\PS> Test-AzPolicyDefinition -Path "C:\PolicyDefinitionFolder\" -OutputFile "C:\Temp\MyTestResult.xml" -ExcludeTags 'ParametersMaxCount', 'ParametersMinCount'
```

Test all Azure Policy definitions in a folder, exclude tests with the `ParametersMaxCount` and `ParametersMinCount` tags and store the test result in a file.
## PARAMETERS

### -path
Specify the file paths for the policy definition files.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -OutputFile
@{Text=}

```yaml
Type: String
Parameter Sets: ProduceOutputFile
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OutputFormat
@{Text=}

```yaml
Type: String
Parameter Sets: ProduceOutputFile
Aliases:
Accepted values: NUnitXml, LegacyNUnitXML

Required: False
Position: Named
Default value: NUnitXml
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExcludeTags
Specify the tags for excluded tests.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String
## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

[Online Version](https://github.com/tyconsulting/AzPolicyTest/blob/master/help/Test-AzPolicyDefinition.md)

