Param($storage_acc,$storage_container,$blob_container_key)
$StorageContext = New-AzureStorageContext $storage_acc -StorageAccountKey $blob_container_key
$blob = Get-AzureStorageBlobContent -Blob udr-route-30012020.csv -Container $storage_container  -Context $StorageContext 
$contents=$blob.ICloudBlob.DownloadText()
$json= $contents | ConvertFrom-Csv -Delimiter ','
$customroutesobj=New-Object PSObject @{
    "udr_custom_routes"= $json
    
    }
$customroutesjson=$customroutesobj |ConvertTo-Json -depth 100
$customroutesjson=$customroutesjson.ToString().Replace(" ","").Replace("`n","").Replace("`r","").Replace("`t","").Replace("\s","").Trim() 
#Write-Host "##vso[task.setvariable variable=ROUTESJSON;]$($customroutesjson)"
write-host $customroutesjson
Set-Content -Path 'C:\Users\AmarjitSingh\Desktop\PowerShell\ROUTESJSON.auto.tfvars.json'  -Value $customroutesjson
