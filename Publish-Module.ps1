$ModulePath = "$PSScriptRoot\Output\PoshwordGenerator"

Publish-Module -Path $ModulePath -NuGetApiKey $Env:APIKEY -Repository PSGallery
