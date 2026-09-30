# Changelog

## 1.2 - 2026-09-30
### Changed
- Use cryptographic randomness for both character selection and shuffling
- Throw a catchable error when the special character count exceeds the password length.
- Return one password per pipeline input, including SecureString and clipboard modes.
- Require an enabled ToClipboard switch when NoOutput is used, without an interactive switch prompt.
- Support positional length and special character count in every parameter set.
- Run Pester 5 tests in a fresh session, mock clipboard access, and fix test runner output modes.
- Update help for the Clipboard parameter set and remove obsolete ADComplexity documentation.


## 1.1.0 - 2025-12-08
### Added
- Function to securely randomize the array of characters for the password.


## 1.0.0 - 2023-07-27
### Added
- Parameter `$AsSecureString` to generate password as secure string
- ParameterSet 'SecureString'
- Short parameter description in comment based help

### Fixed
- Errors in comment based help
- Conflict with ParameterSets

### Changed
- ArrayList type to Generic.List type

## 0.1.0 - 2023-06-15
- First Version
