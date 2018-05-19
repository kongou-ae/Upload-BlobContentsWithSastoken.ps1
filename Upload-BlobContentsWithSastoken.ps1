<#
.SYNOPSIS
	Upload files to blob storage with SAS token.

.DESCRIPTION
	The script will the following methods.

	- Import AzureRM
	- Login Azure Subscription if you don't login.
	- Create temporally container(YYYY-MM-DD) on your blob.
	- Create new SAS token for temporally container.
	- Upload files to temporally container
	- Show you the url to access files.

.PARAMETER storageAccountName
	The storage account name to upload your files.

.PARAMETER targetDir
	The absolute path where the file you want to upload is stored.

.EXAMPLE
	.\Upload-BlobContentsWithSastoken.ps1 -storageAccountName yourstorageaccount -targetDir C:\Users\yourname\Documents\20180519

#>

Param(
  [parameter(mandatory = $true)][String]$storageAccountName,
  [parameter(mandatory = $true)][String]$targetDir
)

# Check module & install module.
if (!(Get-Module -ListAvailable -Name AzureRM)) {
  Write-Host "Please install AzureRM. https://docs.microsoft.com/ja-jp/powershell/azure/install-azurerm-ps#step-2-install-azure-powershell"
}

# Check module. If module don't exist, import module.
if (!(Get-Module -Name AzureRM)) {
  Write-Host "AzureRM isn't installed. Start importing AzureRM"
  Import-Module -Name AzureRM
}

# Login if you don't login.
$content = Get-AzureRmContext
if (!($content.Account)) {
  Write-Output "You must login to Azure."
  Login-AzureRmAccount
}

# Connect storage account.
$ctx = (Get-AzureRmStorageAccount | Where-Object {$_.StorageAccountName -eq $storageAccountName }).Context
$containerName = (Get-date).ToString("yyyy-MMdd-HHmm")

# Create container and SAS token to share files.
$null = New-AzureStorageContainer -Name $containerName -Context $ctx -Permission Off
$sasToken = New-AzureStorageContainerSASToken -Container $containerName -Protocol HttpsOnly -Permission r -ExpiryTime (Get-Date).AddDays(3) -Context $ctx

# Upload all files which is in target dir.
Get-ChildItem $targetDir | ForEach-Object {
  $null = Set-AzureStorageBlobContent -File $_.FullName -Container $containerName -Context $ctx -Force
}

# show the url of file which was uoloaded.
Write-Output "The following files was uploaded to your blob."
Get-AzureStorageBlob -Container $containerName -Context $ctx | ForEach-Object {
  $totalUrl = $_.ICloudBlob.Uri.AbsoluteUri + $sasToken
  Write-Output $totalUrl
}
