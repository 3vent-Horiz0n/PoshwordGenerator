#Region './Public/New-Poshword.ps1' 0
function New-Poshword {

    <#
    .SYNOPSIS
        Simple password generator.
    .DESCRIPTION
        A simple password generator for manual use or in automation.
    .INPUTS
        System.String
    .OUTPUTS
        System.String
        System.Security.SecureString
    .NOTES
        Supports Windows PowerShell 5.1 and PowerShell Core 6+
    .LINK
        https://github.com/3vent-Horiz0n/PoshwordGenerator
    .EXAMPLE
        New-Poshword

        Generates a new password with the default of 8 characters (with 2 special characters).
    .EXAMPLE
        New-Poshword -Length 12 -ToClipboard

        Generates a new password with any 12 characters and copies it to the clipboard.
    .EXAMPLE
        New-Poshword -ToClipboard -NoOutput

        Generates a new password, copies it to the clipboard and suppresses the Output to the console for privacy.
    .EXAMPLE
        New-Poshword -Specialcharacters 4

        Generates a new password with 8 characters (default) and 4 special characters.
    .EXAMPLE
        New-Poshword -ADComplexity

        Generates a new password following standard Active Directory password complexity requirements and with the default length of 8 characters.
    .EXAMPLE
        New-Poshword -ADComplexity -Length 12

        Generates a new password following standard Active Directory password complexity requirements and with a length of 12 characters.
    #>

    [CmdletBinding(DefaultParameterSetName = 'Manual')]
    [Alias('npw')]

    param (
        # Description                  Standard AD password complexity requirement
        [Parameter(
            Mandatory,
            Position = 0,
            ParameterSetName = 'ADComplexity'
        )]
        [Parameter(
            ParameterSetName = 'SecureString'
        )]
        [Alias('AD', 'ADCmplx')]
        [switch] $ADComplexity,

        # Description                 Option to set possible special characters
        [Parameter(
            ValueFromPipeline,
            ParameterSetName = 'ADComplexity'
        )]
        [Parameter(
            ValueFromPipeline,
            ParameterSetName = 'Manual'
        )]
        [Parameter(
            ValueFromPipeline,
            ParameterSetName = 'SecureString'
        )]
        [string] $AllowedSpecialCharacters = ',.-+#!§$%&/()=?;:_*{}[]\',

        # Description                 Generates password as secure string
        [Parameter(
            ParameterSetName = 'SecureString'
        )]
        [switch] $AsSecureString,

        # Description                 Sets the length of the password.
        [Parameter(
            Position = 1,
            ParameterSetName = 'ADComplexity'
            )]
        [Parameter(
            Position = 0,
            ParameterSetName = 'Manual'
        )]
        [Parameter(
            ParameterSetName = 'SecureString'
        )]
        [ValidateRange(8, 99)]
        [Alias('L', 'Len')]
        [int] $Length = 8,

        # Description                 Suppresses output to console
        [Parameter(
            ParameterSetName = 'ADComplexity'
        )]
        [Parameter(
            ParameterSetName = 'Manual'
        )]
        [Alias('NO', 'NoOut')]
        [switch] $NoOutput,

        # Description                 Password Special Character Count
        [Parameter(
            Position = 1,
            ParameterSetName = 'Manual'
        )]
        [Parameter(
            ParameterSetName = 'SecureString'
        )]
        [ValidateRange(0, 99)]
        [Alias('S', 'SpC', 'Special')]
        [int] $SpecialCharacters = 2,

        # Description                 Option to send Password to Clipboard
        [Parameter(
            ParameterSetName = 'ADComplexity'
        )]
        [Parameter(
            ParameterSetName = 'Manual'
        )]
        [Alias('CP', 'Clip')]
        [switch] $ToClipboard
    )

    begin {
        Write-Verbose "Cmdlet executed using parameter set $($PSCmdlet.ParameterSetName)."
    }
    
    process {
        #region     Setup Variables
        $Password           = [System.Collections.Generic.List[string]]::new()
        $UpperCaseCharList  = [char[]](65..90) | Where-Object { $_ -notin @('I', 'O') }
        $LowerCaseCharList  = [char[]](97..122) | Where-Object { $_ -notin @('l') }
        $DigitList          = 1..9
        $SpecialCharList    = $AllowedSpecialCharacters.ToCharArray()
        #endregion  Setup Variables

        if ($ADComplexity) {
            Write-Verbose -Message 'The switch -ADComplexity has been detected.'
            $Char = $UpperCaseCharList | Get-Random
            $Password.Add($Char)
            $Char = $LowerCaseCharList | Get-Random
            $Password.Add($Char)
            $Char = $DigitList | Get-Random
            $Password.Add($Char)
            $Char = $SpecialCharList | Get-Random
            $Password.Add($Char)
            for ($i = 0; $i -lt $Length - 4; $i++) {
                $Char = $UpperCaseCharList, $LowerCaseCharList, $DigitList, $SpecialCharList | Get-Random
                $Password.Add($Char)
            }
        }
        else {
            if ($Length -eq $SpecialCharacters) {
                for ($i = 0; $i -lt $Length; $i++) {
                    $Char = $SpecialCharList | Get-Random
                    $Password.Add($Char)
                }
            }
            elseif ($Length -lt $SpecialCharacters) {
                Write-Host 'More special characters than password length.' -ForegroundColor Red
                continue
            }
            else {
                for ($i = 0; $i -lt $Length - $SpecialCharacters; $i++) {
                    $Char = $UpperCaseCharList, $LowerCaseCharList, $DigitList | Get-Random
                    $Password.Add($Char)
                }
                for ($i = 0; $i -lt $SpecialCharacters; $i++) {
                    $Char = $SpecialCharList | Get-Random
                    $Password.Add($Char)
                }
            }
        }
        $FinalPassword = [System.String]::Join('', ($Password | Sort-Object { Get-Random }))
    }

    end {
        if ($ToClipboard) {
            Set-Clipboard -Value $FinalPassword
            if (!$NoOutput) {
                return $FinalPassword
            }
        }
        elseif ($AsSecureString) {
            return $FinalPassword | ConvertTo-SecureString -AsPlainText -Force
        }
        else {
            return $FinalPassword
        }
    }
}
#EndRegion './Public/New-Poshword.ps1' 197
