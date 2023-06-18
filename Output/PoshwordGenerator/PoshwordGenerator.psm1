#Region './Public/New-Poshword.ps1' 0
function New-Poshword {

    <#
    .SYNOPSIS
        Simple password generator.
    .DESCRIPTION
        A simple password generator for manual use or in automation.
    .INPUTS
        None
        
        Pipeline-Input is currently not supported.
    .OUTPUTS
        System.String
        
        New-Password returns a password as string.
    .NOTES
        Supports Windows PowerShell 5.1 and PowerShell Core 6+
    .LINK
        https://github.com/3vent-Horiz0n/PoshwordGenerator
    .EXAMPLE
        New-Password

        Generates a new password with the default of 8 characters (with 2 special characters).
    .EXAMPLE
        New-Password -Length 12 -ToClipboard

        Generates a new password with any 12 characters and copies it to the clipboard.
    .EXAMPLE
        New-Password -ToClipboard -NoOutput

        Generates a new password, copies it to the clipboard and suppresses the Output to the console for privacy.
    .EXAMPLE
        New-Password -Specialcharacters 4

        Generates a new password with 8 characters (default) and 4 special characters.
    .EXAMPLE
        New-Password -ADComplexity

        Generates a new password following AD complexity requirements and with the default length of 8 characters.
    .EXAMPLE
        New-Password -ADComplexity -Length 12

        Generates a new password following AD complexity requirements and with a length of 12 characters.
    #>

    [CmdletBinding(DefaultParameterSetName = 'Manual')]
    [Alias('npw')]

    param (
        # Standard AD password complexity requirement
        [Parameter(
            Mandatory,
            Position = 0,
            ParameterSetName = 'ADComplexity'
        )]
        [Parameter(ParameterSetName = 'SecureString')]
        [Alias("AD", "ADCmplx")]
        [switch] $ADComplexity,

        # Password Length
        [Parameter(
            Position = 0,
            ParameterSetName = 'Manual'
        )]
        [Parameter(
            Position = 1,
            ParameterSetName = 'ADComplexity'
        )]
        [Parameter(ParameterSetName = 'SecureString')]
        [ValidateRange(8, 99)]
        [Alias("L", "Len")]
        [int] $Length = 8,

        # Password Special Character Count
        [Parameter(
            Position = 1,
            ParameterSetName = 'Manual'
        )]
        [Parameter(ParameterSetName = 'SecureString')]
        [ValidateRange(0, 99)]
        [Alias("S", "SpC", "Special")]
        [int] $SpecialCharacters = 2,

        # Option to send Password to Clipboard
        [Parameter(ParameterSetName = 'Manual')]
        [Parameter(ParameterSetName = 'ADComplexity')]
        [Alias("CP", "Clip")]
        [switch] $ToClipboard,

        # Option to suppress output to console
        [Parameter(ParameterSetName = 'Manual')]
        [Parameter(ParameterSetName = 'ADComplexity')]
        [Alias("no", "NoOut")]
        [switch] $NoOutput,

        # Option to set possible special characters
        [Parameter(ParameterSetName = 'Manual')]
        [Parameter(ParameterSetName = 'ADComplexity')]
        [Parameter(ParameterSetName = 'SecureString')]
        [string] $AllowedSpecialCharacters,

        # Generates password as secure string
        [Parameter(ParameterSetName = 'SecureString')]
        [switch] $AsSecureString
    )
    
    begin {
        # Setup Variables
        $Password = New-Object -TypeName System.Collections.ArrayList
        $UpperCaseCharList = [char[]](65..90) | Where-Object { $_ -notin @("I", "O") }
        $LowerCaseCharList = [char[]](97..122) | Where-Object { $_ -notin @("l") }
        $DigitList = 1..9
        if ($AllowedSpecialCharacters) {
            $SpecialCharList = $AllowedSpecialCharacters.ToCharArray()
        }
        else {
            $SpecialCharList = ',.-+#!§$%&/()=?;:_*{}[]\'.ToCharArray()
        }
    }
    
    process {
        if ($ADComplexity) {
            <#
                TODO: If run in an domain environment and no other parameter like length were specified, check the password policy with >>Get-ADDefaultDomainPasswordPolicy<< to get correct settings.
            #>
            $Char = $UpperCaseCharList | Get-Random
            $Password.Add($Char) | Out-Null
            $Char = $LowerCaseCharList | Get-Random
            $Password.Add($Char) | Out-Null
            $Char = $DigitList | Get-Random
            $Password.Add($Char) | Out-Null
            $Char = $SpecialCharList | Get-Random
            $Password.Add($Char) | Out-Null
            for ($i = 0; $i -lt $Length - 4; $i++) {
                $Char = $UpperCaseCharList, $LowerCaseCharList, $DigitList, $SpecialCharList | Get-Random
                $Password.Add($Char) | Out-Null
            }
        }
        else {
            if ($Length -eq $SpecialCharacters) {
                for ($i = 0; $i -lt $Length; $i++) {
                    $Char = $SpecialCharList | Get-Random
                    $Password.Add($Char) | Out-Null
                }
            }
            elseif ($Length -lt $SpecialCharacters) {
                Write-Host "More special characters than password length." -ForegroundColor Red
                continue
            }
            else {
                for ($i = 0; $i -lt $Length - $SpecialCharacters; $i++) {
                    $Char = $UpperCaseCharList, $LowerCaseCharList, $DigitList | Get-Random
                    $Password.Add($Char) | Out-Null
                }
                for ($i = 0; $i -lt $SpecialCharacters; $i++) {
                    $Char = $SpecialCharList | Get-Random
                    $Password.Add($Char) | Out-Null
                }
            }
        }
        $FinalPassword = [System.String]::Join("", ($Password | Sort-Object { Get-Random }))
    }
    
    end {
        if ($ToClipboard) {
            Set-Clipboard -Value $FinalPassword
            if (!$NoOutput) {
                return $FinalPassword
            }
        }
        else {
            return $FinalPassword
        }
    }
}

# New-Alias -Name npw -Value New-Password -Description "Generates new password"
# Export-ModuleMember -Function * -Alias *
#EndRegion './Public/New-Poshword.ps1' 179
