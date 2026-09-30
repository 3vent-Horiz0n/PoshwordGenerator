---
external help file: PoshwordGenerator-help.xml
Module Name: PoshwordGenerator
online version: https://github.com/3vent-Horiz0n/PoshwordGenerator
schema: 2.0.0
---

# New-Poshword

## SYNOPSIS
Generates passwords using cryptographic randomness.

## SYNTAX

### Manual (Default)
```powershell
New-Poshword [[-Length] <Int32>] [[-SpecialCharacters] <Int32>]
 [-AllowedSpecialCharacters <String>] [<CommonParameters>]
```

### SecureString
```powershell
New-Poshword [[-Length] <Int32>] [[-SpecialCharacters] <Int32>]
 [-AllowedSpecialCharacters <String>] [-AsSecureString] [<CommonParameters>]
```

### Clipboard
```powershell
New-Poshword [[-Length] <Int32>] [[-SpecialCharacters] <Int32>]
 [-AllowedSpecialCharacters <String>] [-NoOutput] [-ToClipboard] [<CommonParameters>]
```

## DESCRIPTION
Generates a password with the requested length and number of special characters.
Character selection and shuffling use a cryptographic random number generator with uniformly distributed indices.

By default, the function returns an 8-character string with 2 special characters.
The alphanumeric pool excludes uppercase I and O, lowercase l, and the digit 0.
The function does not guarantee that every alphanumeric character category appears in each password.

Each pipeline input supplies an allowed special character pool and produces one password.
With `-ToClipboard`, each password is copied in turn; the clipboard retains only the last password.
With `-ToClipboard -NoOutput`, no passwords are written to the output pipeline.
Clipboard errors terminate the call, including when output is suppressed.

## EXAMPLES

### EXAMPLE 1
```powershell
New-Poshword
```
Generates an 8-character password with 2 special characters.

### EXAMPLE 2
```powershell
New-Poshword -Length 12 -ToClipboard
```
Generates a 12-character password, copies it to the clipboard, and returns it.

### EXAMPLE 3
```powershell
New-Poshword -ToClipboard -NoOutput
```
Copies the password to the clipboard without returning it.
`-NoOutput` alone, or with `-ToClipboard:$false`, throws an error without prompting.

### EXAMPLE 4
```powershell
New-Poshword -SpecialCharacters 4
```
Generates an 8-character password with 4 special characters.

### EXAMPLE 5
```powershell
New-Poshword 14 3 -AsSecureString
```
Returns a 14-character SecureString with 3 special characters. Both positional arguments work in every parameter set.

### EXAMPLE 6
```powershell
'!', '#' | New-Poshword -Length 12 -SpecialCharacters 2
```
Returns two passwords. The first contains two exclamation marks; the second contains two hash characters.

## PARAMETERS

### -AllowedSpecialCharacters
Nonempty character pool used for special character selection. Accepts strings from the pipeline. Characters are selected with replacement; duplicate entries in this pool increase their selection probability.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 
Required: False
Position: Named
Default value: ,.-+#!§$%&/()=?;:_*{}[]\
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -AsSecureString
Returns a System.Security.SecureString. Cannot be combined with ToClipboard or NoOutput.

```yaml
Type: SwitchParameter
Parameter Sets: SecureString
Aliases: 
Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Length
Total password length, from 8 to 99 inclusive.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases: L, Len
Required: False
Position: 1
Default value: 8
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoOutput
Suppresses password output. Requires ToClipboard to be enabled. This dependency is checked before password generation.

```yaml
Type: SwitchParameter
Parameter Sets: Clipboard
Aliases: NO, NoOut
Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -SpecialCharacters
Number of characters drawn from AllowedSpecialCharacters, from 0 to 99 inclusive. Must not exceed Length. If the pool contains letters or digits, those entries also count toward this number.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases: S, SpC, Special
Required: False
Position: 2
Default value: 2
Accept pipeline input: False
Accept wildcard characters: False
```

### -ToClipboard
Copies each generated password to the clipboard. Also returns the password unless NoOutput is enabled. Cannot be combined with AsSecureString.

```yaml
Type: SwitchParameter
Parameter Sets: Clipboard
Aliases: CP, Clip
Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This function supports the PowerShell common parameters, including `-Verbose` and `-ErrorAction`.

## INPUTS

### System.String
Each input defines the allowed special character pool for one password.

## OUTPUTS

### System.String
Returned by default, unless NoOutput is enabled with ToClipboard.

### System.Security.SecureString
Returned when AsSecureString is enabled.

## NOTES
Supports Windows PowerShell 5.1 and PowerShell Core 6+.
The command alias is `npw`.

## RELATED LINKS
[Project repository](https://github.com/3vent-Horiz0n/PoshwordGenerator)
