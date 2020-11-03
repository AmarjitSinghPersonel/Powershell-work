#Connect-AzAccount
#$paramRG = $null
$paramRG = "tfvmex-mohantest-resources"
Get-AzResourceGroup | Where-Object {if($paramRG -ne $null){$_.ResourceGroupName -eq $paramRG} else { 1 -eq 1 }}| ForEach-Object { 
   $RG = $_.ResourceGroupName
        Get-AzResource -ResourceGroupName $_.ResourceGroupName  | ForEach-Object { 
         if($_.ResourceType -eq "Microsoft.Compute/virtualMachines")
            {
                $vmname = $_.ResourceName 
                
                if($vmname -ne "")
                {
                    Write-Output('VM - ' + $_.ResourceName)
                    $vmtags = @{"VMName"=$vmname;}
                    $resource = Get-AzResource -Name $_.ResourceName -ResourceGroup $RG            
                    Update-AzTag -ResourceId $resource.id -Tag $vmtags -Operation Merge

                }   
             }           
               
          elseif($_.ResourceType -eq "Microsoft.Compute/disks")
                  {
                        $disk = Get-AzResource  -ResourceGroup $RG -Name $_.ResourceName | Select-Object ManagedBy 
                        $diskArr = $disk -split "/"
                        $managedBy = $diskArr[$disk.length-1].substring(0,$diskArr[$disk.Length-1].Length-1)
                        if($managedBy -ne "")
                        {
                            $disktags = @{"VMName"=$managedBy;}
                            $resource = Get-AzResource -Name $_.ResourceName -ResourceGroup $RG
                            Update-AzTag -ResourceId $resource.id -Tag $disktags -Operation Merge
                            Write-Output('Disk - ' + $_.ResourceName)
                        }
                        
                        $diskArr = $null
                   }
        
                   
          elseif ($_.ResourceType -eq "Microsoft.Network/networkInterfaces")
                     {
                            $nic = ((Get-AzNetworkInterface -ResourceGroupName $RG -Name $_.ResourceName | Select-object).VirtualMachineText | ConvertFrom-Json).Id
                            $nicArr = $nic -split "/" 
                            $vmname = $nicArr[$nicArr.Length-1]                
                           
                            if($vmname -ne "")
                            {
                                $nictags = @{"VMName"=$vmname;}
                                $resource = Get-AzResource -Name $_.ResourceName -ResourceGroup $RG
                                Update-AzTag -ResourceId $resource.id -Tag $nictags -Operation Merge    
                                 Write-Output('NIC - ' + $_.ResourceName)
                            }
                            
                            $nicArr = $null
                      }
          elseif($_.ResourceType -eq "Microsoft.Compute/snapshots")
                        {
                            
                            $snapshot = az snapshot show --resource-group $RG --name $_.ResourceName  --query "creationData.sourceResourceId" 
                            $SSarr = $snapshot -split "/" 
                            $vmname = $SSarr[$SSarr.Length-1]  
                            if($vmname -ne "")
                            {
                                $tags = @{"VMName"=$vmname;}
                                $resource = Get-AzResource -Name $_.ResourceName -ResourceGroup $RG
                                Update-AzTag -ResourceId $resource.id -Tag $tags -Operation Merge
                                Write-Output('Snapshot - ' + $_.ResourceName)
                            }
                            
                            $SSarr = $null
                        }                             
        
                           
        }    
    }

    
 #   az logout










#Get-AzResource -Name 'testsnapshot' -ResourceGroup 'TFVMEX-MOHANTEST-RESOURCES' | Select-object * VirtualMachine

#Get-AzNetworkInterface -ResourceGroupName "amarjittesttg748" | Where-Object {$_.ProvisioningState -eq 'Succeeded'}
#
#Get-AzSnapshot -ResourceGroupName 'TFVMEX-MOHANTEST-RESOURCES' -SnapshotName 'testsnapshot' | Select-object *

#Get-AzDisk -ResourceGroupName 'TFVMEX-MOHANTEST-RESOURCES' -DiskName 'AmarjitTestTg_OsDisk_1_85cf05d4b7a04237b4a1e76f19e7aa24' | Select-object *

#az login


#Get-AzureRmSnapshot -ResourceGroupName 'TFVMEX-MOHANTEST-RESOURCES' -SnapshotName 'testsnapshot'


#Get-AzResource  -ResourceGroupName 'TFVMEX-MOHANTEST-RESOURCES' -Name tfvmex-mohantest-NIC | Select-object Id


#$resource = Get-AzResource -Name AppInsight -ResourceGroup 'AppInsight-ishan'
 #$resource.Id

 #$NicList = Get-AzNetworkInterface | Where-Object {$PSItem.VirtualMachine -eq 'AmarjitTestTg'}
 #ec$NicList