start-process PowerShell -verb runAs
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll  

Start-Process powershell.exe -Verb RunAs  -ArgumentList ('-noprofile -noexit -file C:\Users\AmarjitSingh\Desktop\PowerShell\Untitled8.ps1')

RunAs /user:Administrator Install-WindowsUpdate -MicrosoftUpdate -AcceptAll  

net user Administrator

 az image copy --source-resource-group 'imagerg' --source-object-name '0.24558.5148' --target-location 'westus' --target-resource-group 'imagerg'

 az sig image-version create --gallery-image-version 1.0.1 --gallery-name myGallery --gallery-image-definition myImageDefinition  --target-regions "southcentralus=1" "eastus=1" "westus=1" --replica-count 1 --managed-image "/subscriptions/39a939fd-de7a-45d8-91a6-a9e868096197/resourceGroups/myGalleryRG/providers/Microsoft.Compute/galleries/myGallery/images/myImageDefinition/versions/1.0.0" --resource-group myGalleryRG


 $region1 = @{Name='West Europe';ReplicaCount=1}

$region2 = @{Name='South Central US';ReplicaCount=2}

$targetRegions = @($region1,$region2)

 New-AzGalleryImageVersion -GalleryImageDefinitionName myImageDefinition  -GalleryImageVersionName '1.0.2' -GalleryName myGallery  -ResourceGroupName imagerg  -Location eastus  -TargetRegion $targetRegions  -Source "/subscriptions/39a939fd-de7a-45d8-91a6-a9e868096197/resourceGroups/myGalleryRG/providers/Microsoft.Compute/galleries/myGallery/images/myImageDefinition/versions/1.0.0"  -PublishingProfileEndOfLifeDate '2020-01-01'  -asJob