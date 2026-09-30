BeforeAll {
    . "$PSScriptRoot/../Source/Private/Get-SecureRandomIndex.ps1"
    . "$PSScriptRoot/../Source/Private/SecureRandomizer.ps1"

    if (-not ('PoshwordTests.SequenceRandom' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Security.Cryptography;

namespace PoshwordTests {
    public sealed class SequenceRandom : RandomNumberGenerator {
        private readonly uint[] values;
        public int Calls { get; private set; }
        public bool IsDisposed { get; private set; }

        public SequenceRandom(uint[] values) { this.values = values; }

        public override void GetBytes(byte[] data) {
            if (IsDisposed) throw new ObjectDisposedException("SequenceRandom");
            if (Calls >= values.Length) throw new InvalidOperationException("Sequence exhausted");
            byte[] bytes = BitConverter.GetBytes(values[Calls++]);
            Array.Copy(bytes, data, data.Length);
        }

        protected override void Dispose(bool disposing) {
            IsDisposed = true;
            base.Dispose(disposing);
        }
    }
}
'@
    }
}

Describe 'Get-SecureRandomIndex' {
    It 'Should reject the incomplete interval before mapping into the requested range' {
        $rng = [PoshwordTests.SequenceRandom]::new([uint32[]]@([uint32]::MaxValue, 4))
        try {
            Get-SecureRandomIndex -RandomNumberGenerator $rng -ExclusiveMaximum 3 | Should -Be 1
            $rng.Calls | Should -Be 2
        }
        finally { $rng.Dispose() }
    }

    It 'Should include the upper endpoint when the range divides the sample space' {
        $rng = [PoshwordTests.SequenceRandom]::new([uint32[]]@([uint32]::MaxValue))
        try {
            Get-SecureRandomIndex -RandomNumberGenerator $rng -ExclusiveMaximum 256 | Should -Be 255
            $rng.Calls | Should -Be 1
        }
        finally { $rng.Dispose() }
    }

    It 'Should support a character pool containing just one character' {
        $rng = [PoshwordTests.SequenceRandom]::new([uint32[]]@([uint32]::MaxValue))
        try {
            Get-SecureRandomIndex -RandomNumberGenerator $rng -ExclusiveMaximum 1 | Should -Be 0
        }
        finally { $rng.Dispose() }
    }
}

Describe 'SecureRandomizer' {
    It 'Should preserve all characters and their multiplicities' {
        $inputCharacters = 'aabb!12'.ToCharArray()
        $result = @(SecureRandomizer -array $inputCharacters.Clone())
        $result.Count | Should -Be 7
        (-join ($result | Sort-Object)) | Should -Be (-join ('aabb!12'.ToCharArray() | Sort-Object))
    }

    It 'Should leave a supplied generator usable by its owner' {
        $rng = [PoshwordTests.SequenceRandom]::new([uint32[]]@(0, 1))
        try {
            (-join (SecureRandomizer -array 'ab'.ToCharArray() -RandomNumberGenerator $rng)) | Should -Be 'ba'
            $rng.IsDisposed | Should -BeFalse
            Get-SecureRandomIndex -RandomNumberGenerator $rng -ExclusiveMaximum 2 | Should -Be 1
        }
        finally { $rng.Dispose() }
    }
}
