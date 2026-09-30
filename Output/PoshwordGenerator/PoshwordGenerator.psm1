#Region './Private/Get-SecureRandomIndex.ps1' -1

function Get-SecureRandomIndex {
    param (
        [Parameter(Mandatory)]
        [System.Security.Cryptography.RandomNumberGenerator] $RandomNumberGenerator,

        [Parameter(Mandatory)]
        [ValidateRange(1, [int]::MaxValue)]
        [int] $ExclusiveMaximum
    )

    # Reject the incomplete interval to avoid modulo bias. GetBytes is available
    # on .NET Framework as well as .NET, including Windows PowerShell 5.1.
    $bytes = [byte[]]::new(4)
    $range = [uint64]4294967296
    $limit = $range - ($range % [uint64]$ExclusiveMaximum)
    do {
        $RandomNumberGenerator.GetBytes($bytes)
        $value = [uint64][BitConverter]::ToUInt32($bytes, 0)
    } while ($value -ge $limit)

    return [int]($value % [uint64]$ExclusiveMaximum)
}
#EndRegion './Private/Get-SecureRandomIndex.ps1' 23
#Region './Private/SecureRandomizer.ps1' -1

function SecureRandomizer {
    # Implementation of the Fisher-Yates shuffle algorithm using the .Net cryptographic random number generator
    param (
        [char[]] $array,
        [System.Security.Cryptography.RandomNumberGenerator] $RandomNumberGenerator
    )

    $ownsGenerator = $null -eq $RandomNumberGenerator
    if ($ownsGenerator) {
        $RandomNumberGenerator = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    }

    try {
        # Fisher-Yates shuffle with uniformly distributed indices.
        for ($i = $array.Length - 1; $i -gt 0; $i--) {
            $j = Get-SecureRandomIndex -RandomNumberGenerator $RandomNumberGenerator -ExclusiveMaximum ($i + 1)
            $temp = $array[$i]
            $array[$i] = $array[$j]
            $array[$j] = $temp
        }
    }
    finally {
        if ($ownsGenerator) {
            $RandomNumberGenerator.Dispose()
        }
    }

    return $array
}
#EndRegion './Private/SecureRandomizer.ps1' 30
#Region './Public/New-Poshword.ps1' -1

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
#EndRegion './Public/New-Poshword.ps1' 149
