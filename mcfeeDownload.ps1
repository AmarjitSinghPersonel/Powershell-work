#Invoke-WebRequest https://tfvmexamarnewresourcedia.blob.core.windows.net/mcfee/file.exe -OutFile C:\Users\AmarjitSingh\file1.exe

#Get-AzureStorageBlobContent -Container "mcfee" -Blob "file.exe" -Destination "C:\test\"
#$context = (Get-AzStorageAccount -ResourceGroupName 'tfvmex-Amar-New-resource' -AccountName 'tfvmexamarnewresourcedia').context

$connection_string = 'DefaultEndpointsProtocol=https;AccountName=tfvmexamarnewresourcedia;AccountKey=4NjhTSjXta/ZoD5C3gCAaXrgEM89luPpmICYv6ED9d+jxugJa3EMJVAtZjIrBim8+tSZWeVqtj5v2ZFhQQHkSg==;EndpointSuffix=core.windows.net'  
$storage_account = New-AzureStorageContext -ConnectionString $connection_string 
$now=get-date
$sasToken = New-AzureStorageContainerSASToken -Name 'tfvmexamarnewresourcedia'  -Context $storage_account -Permission rwl -StartTime $now.AddHours(-1) -ExpiryTime $now.AddMonths(1)
Write-Output $sasToken 
$uri = 'https://amarjitsstorage.blob.core.windows.net/?'+ $sasToken


#$connection_string = 'DefaultEndpointsProtocol=https;AccountName=tfvmexamarnewresourcedia;AccountKey='+ $sasToken  +';EndpointSuffix=core.windows.net;'
$storage_account = New-AzureStorageContext -ConnectionString $uri 
$container_name = 'mcfee'  
$blobs = Get-AzureStorageBlob -Container $container_name -Context $storage_account 
$destination_path   = 'C:\Users\AmarjitSingh\Desktop'
foreach ($blob in $blobs)  
{  
   New-Item -ItemType Directory -Force -Path $destination_path  
   Get-AzureStorageBlobContent -Container $container_name -Blob $blob.Name -Destination $destination_path -Context $storage_account 
} 

$Source = "C:\Sep32\Sep.msi"
$Args = "/i $Source /quiet/s/n"

Install-Module -Name AzureRM -AllowClobber -Force


 '/qn/qb!/qb' 

Start-Process -Wait -FilePath "C:\Users\AmarjitSingh\Downloads\OneDrive_1_9-11-2020 (1)\10.7.0 - Sep 2020 - with Azure Agent\Endpoint Security Platform 10.7.0 Build 2000 Package #4 (AAA-LICENSED-RELEASE-UPDATE 4)\10268045E98F363DFramePkg5.6.6-PROD\FramePkg5.6.6-PROD.exe" -ArgumentList 'INSTALL=AGENT /SILENT'  

Start-Process -Wait -FilePath "C:\Users\AmarjitSingh\Downloads\OneDrive_1_9-11-2020 (1)\10.7.0 - Sep 2020 - with Azure Agent\setupEP.exe"'/q/qb!/qb'    


Expand-Archive -LiteralPath 'C:\Users\AmarjitSingh\Downloads\mcaFeezip.Zip' -DestinationPath 'C:\Users\AmarjitSingh\Downloads\mcaFeezip'



Start-Process -Wait -FilePath ./'setupEP.exe'  'ADDLOCAL="tp"' "/qn" -passthru


Set-Location "C:\Users\AmarjitSingh\Downloads\mcaFeezip\mcfeezip\10.7.0 - Sep 2020 - with Azure Agent" 
./"setupEP.exe" 'ADDLOCAL="tp"' "/qn"