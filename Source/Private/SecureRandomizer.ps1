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
