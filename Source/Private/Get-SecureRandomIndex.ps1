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
