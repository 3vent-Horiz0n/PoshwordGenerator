function New-Poshword {
    <#
    .SYNOPSIS
        Simple password generator.
    .DESCRIPTION
        Generates passwords using cryptographic randomness for character selection and shuffling.
        Returns one password per pipeline input. Each input defines the allowed special characters.
    .PARAMETER AllowedSpecialCharacters
        Nonempty character pool used for special characters. Accepts strings from the pipeline.
    .PARAMETER AsSecureString
        Returns a SecureString. Cannot be combined with ToClipboard or NoOutput.
    .PARAMETER Length
        Password length from 8 to 99. Defaults to 8.
    .PARAMETER NoOutput
        Suppresses password output. Requires ToClipboard to be enabled.
    .PARAMETER SpecialCharacters
        Number of characters drawn from AllowedSpecialCharacters, from 0 to Length. Defaults to 2.
    .PARAMETER ToClipboard
        Copies each password to the clipboard. Only the last password remains after pipeline input.
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
        New-Poshword 14 3 -AsSecureString

        Generates a 14-character SecureString with 3 special characters.
    .EXAMPLE
        '!', '#' | New-Poshword -Length 12 -SpecialCharacters 2

        Generates two passwords, using the respective input as the special character pool.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Manual')]
    [Alias('npw')]
    [OutputType([string], [System.Security.SecureString])]

    param (
        # Description: Option to set possible special characters
        [Parameter(ValueFromPipeline, ParameterSetName = 'Manual')]
        [Parameter(ValueFromPipeline, ParameterSetName = 'SecureString')]
        [Parameter(ValueFromPipeline, ParameterSetName = 'Clipboard')]
        [ValidateNotNullOrEmpty()]
        [string] $AllowedSpecialCharacters = ',.-+#!§$%&/()=?;:_*{}[]\',

        # Description: Generates password as secure string
        [Parameter(ParameterSetName = 'SecureString')]
        [switch] $AsSecureString,

        # Description: Sets the length of the password.
        [Parameter(Position = 0, ParameterSetName = 'Manual')]
        [Parameter(Position = 0, ParameterSetName = 'SecureString')]
        [Parameter(Position = 0, ParameterSetName = 'Clipboard')]
        [ValidateRange(8, 99)]
        [Alias('L', 'Len')]
        [int] $Length = 8,

        # Description: Suppresses output to console
        [Parameter(ParameterSetName = 'Clipboard')]
        [Alias('NO', 'NoOut')]
        [switch] $NoOutput,

        # Description: Password Special Character Count
        [Parameter(Position = 1, ParameterSetName = 'Manual')]
        [Parameter(Position = 1, ParameterSetName = 'SecureString')]
        [Parameter(Position = 1, ParameterSetName = 'Clipboard')]
        [ValidateRange(0, 99)]
        [Alias('S', 'SpC', 'Special')]
        [int] $SpecialCharacters = 2,

        # Description: Option to send Password to Clipboard
        [Parameter(ParameterSetName = 'Clipboard')]
        [Alias('CP', 'Clip')]
        [switch] $ToClipboard
    )

    begin {
        if ($NoOutput -and -not $ToClipboard) {
            throw [System.Management.Automation.ParameterBindingException]::new(
                'The -NoOutput parameter requires -ToClipboard to be enabled.'
            )
        }

        if ($SpecialCharacters -gt $Length) {
            throw [System.ArgumentException]::new(
                'SpecialCharacters must not exceed Length.', 'SpecialCharacters'
            )
        }

        Write-Verbose "Cmdlet executed using parameter set $($PSCmdlet.ParameterSetName)."
        $AlphaNumericCharList = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz123456789'.ToCharArray()
    }

    process {
        $Password = [System.Collections.Generic.List[char]]::new()
        $SpecialCharList = $AllowedSpecialCharacters.ToCharArray()
        $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()

        try {
            for ($i = 0; $i -lt $Length - $SpecialCharacters; $i++) {
                $index = Get-SecureRandomIndex -RandomNumberGenerator $rng -ExclusiveMaximum $AlphaNumericCharList.Length
                $Password.Add($AlphaNumericCharList[$index])
            }
            for ($i = 0; $i -lt $SpecialCharacters; $i++) {
                $index = Get-SecureRandomIndex -RandomNumberGenerator $rng -ExclusiveMaximum $SpecialCharList.Length
                $Password.Add($SpecialCharList[$index])
            }

            $FinalPassword = -join (SecureRandomizer -array $Password.ToArray() -RandomNumberGenerator $rng)
        }
        finally {
            $rng.Dispose()
        }

        if ($ToClipboard) {
            Set-Clipboard -Value $FinalPassword -ErrorAction Stop
            if (!$NoOutput) {
                $FinalPassword
            }
        }
        elseif ($AsSecureString) {
            $FinalPassword | ConvertTo-SecureString -AsPlainText -Force
        }
        else {
            $FinalPassword
        }
    }
}
