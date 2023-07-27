# Poshword Generator

Poshword Generator is a simple password generator for PowerShell.

<br>

---

<br>

## Functionality

This PowerShell Module creates passwords. Without any parameter it generates 8-figure passwords with 2 special characters. It is possible to change the parameters though.

```powershell
New-Poshword -Length 12 -SpecialCharacters 4
```

With the switch `-ToClipboard` the generated password gets sent to the clipboard in addition to the console output.
There are aliases to to shorten the command:

```powershell
npw 12 4 -clip
```

More examples can be found in the in the PowerShell help with `Get-Help New-Poshword`.

<br>

---

<br>

## Installation

### PSGallery

The module is available on the PowerShell Gallery:

```powershell
Install-Module -Name PoshwordGenerator
```

### Manual

Download this repository and place the folder `PoshwordGenerator` from the Output directory into on of the folders configured on your machine. <br>
You can find the paths configured in the environment variable `$PSModulePath`: <br>

Windows: `$env:PSModulePath -split ';'` <br>

Linux / macOS: `$env:PSModulePath -split ':'`

<br>

---

<br>
