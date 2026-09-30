BeforeAll {
    . "$PSScriptRoot/../Source/Private/Get-SecureRandomIndex.ps1"
    . "$PSScriptRoot/../Source/Private/SecureRandomizer.ps1"
    . "$PSScriptRoot/../Source/Public/New-Poshword.ps1"
}

Describe 'New-Poshword' {
    BeforeEach {
        Mock Set-Clipboard {}
    }

    Context 'Basic Functionality' {
        It 'Should generate a password with default length of 8' {
            $password = New-Poshword
            $password.Length | Should -Be 8
        }

        It 'Should generate a password with custom length' {
            $password = New-Poshword -Length 13
            $password.Length | Should -Be 13
        }

        It 'Should generate a password with minimum length of 8' {
            $password = New-Poshword -Length 8
            $password.Length | Should -Be 8
        }

        It 'Should generate a password with maximum length of 99' {
            $password = New-Poshword -Length 99
            $password.Length | Should -Be 99
        }

        It 'Should return a string output' {
            $password = New-Poshword
            $password | Should -BeOfType [string]
        }

        It 'Should generate different passwords on each call' {
            $password1 = New-Poshword -Length 20
            $password2 = New-Poshword -Length 20
            $password1 | Should -Not -Be $password2
        }
    }

    Context 'Special Characters' {
        It 'Should include default 2 special characters' {
            $password = New-Poshword -Length 20
            $specialChars = ',.-+#!§$%&/()=?;:_*{}[]\'''
            $specialCount = 0
            foreach ($char in $password.ToCharArray()) {
                if ($char -in $specialChars.ToCharArray()) {
                    $specialCount++
                }
            }
            $specialCount | Should -Be 2
        }

        It 'Should include custom number of special characters' {
            $password = New-Poshword -Length 20 -SpecialCharacters 5
            $specialChars = ',.-+#!§$%&/()=?;:_*{}[]\'''
            $specialCount = 0
            foreach ($char in $password.ToCharArray()) {
                if ($char -in $specialChars.ToCharArray()) {
                    $specialCount++
                }
            }
            $specialCount | Should -Be 5
        }

        It 'Should allow custom special characters' {
            $password = New-Poshword -Length 20 -AllowedSpecialCharacters '!@#' -SpecialCharacters 3
            $customChars = '!@#'.ToCharArray()
            $customCount = 0
            foreach ($char in $password.ToCharArray()) {
                if ($char -in $customChars) {
                    $customCount++
                }
            }
            $customCount | Should -Be 3
        }

        It 'Should fail when special characters exceed password length' {
            { New-Poshword -Length 8 -SpecialCharacters 9 } |
                Should -Throw -ExceptionType ([System.ArgumentException]) -ExpectedMessage '*SpecialCharacters*Length*'
        }

        It 'Should support password with special characters equal to length' {
            $password = New-Poshword -Length 8 -SpecialCharacters 8
            $password.Length | Should -Be 8
        }
    }

    Context 'Clipboard Functionality' {
        It 'Should copy password to clipboard' {
            $password = New-Poshword -ToClipboard
            Should -Invoke Set-Clipboard -Times 1 -Exactly -ParameterFilter { $Value -ceq $password }
        }

        It 'Should suppress output when -NoOutput is used with -ToClipboard' {
            $result = New-Poshword -ToClipboard -NoOutput
            $result | Should -BeNullOrEmpty
            Should -Invoke Set-Clipboard -Times 1 -Exactly -ParameterFilter { (-join $Value).Length -eq 8 }
        }

        It 'Should return password when -ToClipboard without -NoOutput' {
            $password = New-Poshword -ToClipboard
            $password | Should -Not -BeNullOrEmpty
            $password | Should -BeOfType [string]
        }

        It 'Should reject NoOutput without an enabled clipboard switch' -TestCases @(
            @{ Parameters = @{ NoOutput = $true } }
            @{ Parameters = @{ NoOutput = $true; ToClipboard = $false } }
        ) {
            param($Parameters)
            { New-Poshword @Parameters } | Should -Throw -ExpectedMessage '*NoOutput*ToClipboard*'
            Should -Invoke Set-Clipboard -Times 0 -Exactly
        }

        It 'Should report a clipboard failure even when output is suppressed' {
            Mock Set-Clipboard { Write-Error 'Clipboard unavailable' }
            { New-Poshword -ToClipboard -NoOutput } | Should -Throw '*Clipboard unavailable*'
        }
    }

    Context 'SecureString Output' {
        It 'Should return SecureString when -AsSecureString is used' {
            $password = New-Poshword -AsSecureString
            $password | Should -BeOfType [System.Security.SecureString]
        }

        It 'Should generate correct length password as SecureString' {
            $securePassword = New-Poshword -Length 12 -AsSecureString
            $securePassword | Should -BeOfType [System.Security.SecureString]
            
            # Verify the length by converting back
            $plainPassword = [System.Net.NetworkCredential]::new('', $securePassword).Password
            $plainPassword.Length | Should -Be 12
        }
    }

    Context 'Parameter Validation' {
        It 'Should reject length below 8' {
            { New-Poshword -Length 7 } | Should -Throw
        }

        It 'Should reject length above 99' {
            { New-Poshword -Length 100 } | Should -Throw
        }

        It 'Should reject negative special character count' {
            { New-Poshword -SpecialCharacters -1 } | Should -Throw
        }

        It 'Should reject special character counts above 99' {
            { New-Poshword -SpecialCharacters 100 } | Should -Throw
        }

        It 'Should reject an empty or null special character pool' -TestCases @(
            @{ Pool = '' }
            @{ Pool = $null }
        ) {
            param($Pool)
            { New-Poshword -AllowedSpecialCharacters $Pool } | Should -Throw
        }

        It 'Should let the caller catch invalid counts and continue' {
            $events = [System.Collections.Generic.List[string]]::new()
            & {
                try {
                    New-Poshword -Length 8 -SpecialCharacters 9
                }
                catch [System.ArgumentException] {
                    $events.Add('caught')
                }
                $events.Add('continued')
            }
            ($events -join ',') | Should -Be 'caught,continued'
        }

        It 'Should accept special character count of 0' {
            $password = New-Poshword -Length 10 -SpecialCharacters 0
            $password.Length | Should -Be 10
        }

        It 'Should accept special character count of 99' {
            $password = New-Poshword -Length 99 -SpecialCharacters 99
            $password.Length | Should -Be 99
        }
    }

    Context 'Aliases' {
        It 'Should work with alias -L for -Length' {
            $password = New-Poshword -L 12
            $password.Length | Should -Be 12
        }

        It 'Should work with alias -S for -SpecialCharacters' {
            $password = New-Poshword -Length 20 -S 5
            $specialChars = ',.-+#!§$%&/()=?;:_*{}[]\'''
            $specialCount = 0
            foreach ($char in $password.ToCharArray()) {
                if ($char -in $specialChars.ToCharArray()) {
                    $specialCount++
                }
            }
            $specialCount | Should -Be 5
        }

        It 'Should work with alias npw' {
            $password = npw -Length 10
            $password.Length | Should -Be 10
        }

        It 'Should work with alias -CP for -ToClipboard' {
            $password = New-Poshword -CP
            Should -Invoke Set-Clipboard -Times 1 -Exactly -ParameterFilter { $Value -ceq $password }
        }
    }

    Context 'Character Composition' {
        It 'Should contain only valid characters (not i or o in uppercase)' {
            for ($i = 0; $i -lt 10; $i++) {
                $password = New-Poshword -Length 50
                $password | Should -Not -MatchExactly '[IO]'
            }
        }

        It 'Should contain only valid characters (not L in lowercase)' {
            for ($i = 0; $i -lt 10; $i++) {
                $password = New-Poshword -Length 50
                $password | Should -Not -MatchExactly 'l'
            }
        }

        It 'Should contain only printable ASCII or special characters' {
            $password = New-Poshword -Length 50
            $password | Should -Match '^[A-HJ-NP-Za-km-z1-9,.\-+#!§$%&/()=?;:_*{}\[\]\\]+$'
        }
    }

    Context 'Parameter Set Behavior' {
        It 'Should work with no parameters' {
            $password = New-Poshword
            $password | Should -Not -BeNullOrEmpty
        }

        It 'Should work with only -Length parameter' {
            $password = New-Poshword -Length 15
            $password.Length | Should -Be 15
        }

        It 'Should work with -AsSecureString parameter' {
            $password = New-Poshword -AsSecureString
            $password | Should -BeOfType [System.Security.SecureString]
        }

        It 'Should accept both positional arguments in every parameter set' -TestCases @(
            @{ Parameters = @{} }
            @{ Parameters = @{ AsSecureString = $true } }
            @{ Parameters = @{ ToClipboard = $true } }
        ) {
            param($Parameters)
            $password = New-Poshword 14 3 -AllowedSpecialCharacters '!' @Parameters
            if ($password -is [System.Security.SecureString]) {
                $password = [System.Net.NetworkCredential]::new('', $password).Password
            }
            $password.Length | Should -Be 14
            @($password.ToCharArray() | Where-Object { $_ -eq '!' }).Count | Should -Be 3
        }

        It 'Should reject SecureString combined with clipboard parameters' -TestCases @(
            @{ Parameters = @{ AsSecureString = $true; ToClipboard = $true } }
            @{ Parameters = @{ AsSecureString = $true; NoOutput = $true } }
        ) {
            param($Parameters)
            { New-Poshword @Parameters } | Should -Throw -ExceptionType ([System.Management.Automation.ParameterBindingException])
        }
    }

    Context 'Pipeline input' {
        It 'Should return one password per input using the corresponding character pool' {
            $passwords = @('!', '#' | New-Poshword -Length 8 -SpecialCharacters 8)
            $passwords.Count | Should -Be 2
            $passwords[0] | Should -Be '!!!!!!!!'
            $passwords[1] | Should -Be '########'
        }

        It 'Should return one SecureString per input' {
            $passwords = @('!', '#' | New-Poshword -Length 8 -SpecialCharacters 8 -AsSecureString)
            $passwords.Count | Should -Be 2
            foreach ($password in $passwords) {
                $password | Should -BeOfType [System.Security.SecureString]
            }
            [System.Net.NetworkCredential]::new('', $passwords[0]).Password | Should -Be '!!!!!!!!'
            [System.Net.NetworkCredential]::new('', $passwords[1]).Password | Should -Be '########'
        }

        It 'Should copy each pipeline password and honor NoOutput' -TestCases @(
            @{ SuppressOutput = $false }
            @{ SuppressOutput = $true }
        ) {
            param($SuppressOutput)
            $passwords = @('!', '#' | New-Poshword -Length 8 -SpecialCharacters 8 -ToClipboard -NoOutput:$SuppressOutput)
            $passwords.Count | Should -Be $(if ($SuppressOutput) { 0 } else { 2 })
            Should -Invoke Set-Clipboard -Times 2 -Exactly
            Should -Invoke Set-Clipboard -Times 1 -Exactly -ParameterFilter { $Value -eq '!!!!!!!!' }
            Should -Invoke Set-Clipboard -Times 1 -Exactly -ParameterFilter { $Value -eq '########' }
        }

        It 'Should not generate a password for an empty pipeline' {
            @(@() | New-Poshword).Count | Should -Be 0
        }
    }

    Context 'Randomness' {
        It 'Should generate passwords without Get-Random' {
            Mock Get-Random { throw 'Get-Random must not be used for password generation.' }
            (New-Poshword -Length 20 -SpecialCharacters 4).Length | Should -Be 20
            Should -Invoke Get-Random -Times 0 -Exactly
        }
    }

    Context 'Edge Cases' {
        It 'Should generate password with length 8 and 0 special characters' {
            $password = New-Poshword -Length 8 -SpecialCharacters 0
            $password.Length | Should -Be 8
        }

        It 'Should generate password with very long length' {
            $password = New-Poshword -Length 99
            $password.Length | Should -Be 99
        }

        It 'Should handle multiple special characters at maximum' {
            $password = New-Poshword -Length 99 -SpecialCharacters 99
            $password.Length | Should -Be 99
        }
    }
}
