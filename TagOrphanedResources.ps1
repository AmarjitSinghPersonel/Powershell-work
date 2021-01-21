
# Define and validate parameters
[CmdletBinding()]
Param(
	    # Optional. Azure Subscription Name, can be passed as a Parameter
	    $txt ="new annd"
  $txt | Out-File -FilePath /Process.txt 
        
        #[Parameter(Mandatory=$true)]
        [parameter(Position=1)]
        [string]$paramRG = "linuxhardeninig",
        
        [parameter(Position=2)]
        [string]$storageRG = "cloudeqlab",
        
        [parameter(Position=3)]
        [string]$storageName = "amrstore",
        
        [parameter(Position=4)]
        [string]$container = "logfiles",

        [parameter(Position=5)]
        [string]$isChkUnmanagedDisk = $true,
        # Folder Path for Output, if not specified defaults to script folder
	    [parameter(Position=6)]
        [string]$OutputFolderPath = "FOLDERPATH"
        # Exmaple: C:\Scripts\
        
	)
# Set strict mode to identify typographical errors
Set-StrictMode -Version Latest



##########################################################################################################


###################################
## FUNCTION 1 - Out-ToHostAndFile
###################################
# Function used to create a transcript of output, this is in addition to CSVs.
###################################
Function Out-ToHostAndFile {

    Param(
	    # Azure Subscription Name, can be passed as a Parametery or edit variable below
	    [parameter(Position=0,Mandatory=$True)]
	    [string]$Content,

        [parameter(Position=1)]
        [string]$FontColour,

        [parameter(Position=2)]
        [switch]$NoNewLine
    )

    if([string]::IsNullOrWhiteSpace($FontColour)){
        $FontColour = "White"
    }

    if($NoNewLine.IsPresent) {
        Write-Host $Content -ForegroundColor $FontColour -NoNewline
    } else {
        Write-Host $Content -ForegroundColor $FontColour
    }
 }

#######################################
## FUNCTION 2 - Set-OutputLogFiles
#######################################
# Generate unique log file names
#######################################
Function Set-OutputLogFiles {

    [string]$FileNameDataTime = Get-Date -Format "yy-MM-dd_HHmmss"

    # Default to script folder, or user profile folder.
    if([string]::IsNullOrWhiteSpace($script:MyInvocation.MyCommand.Path)){
        $ScriptDir = "."
    } else {
        $ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path
    }
    $OutputFolderPath=$ScriptDir
    #CSV Output File Paths, can be unique depending on boolean flag
 
    $script:OutputFileUnmanagedDisksCSV = "$OutputFolderPath\unmanagedOrphaneddisks$($FileNameDataTime).csv"
    $script:OutputFileManagedDisksCSV = "$OutputFolderPath\managedDisks_$($FileNameDataTime).csv"
    $script:OutputFileManagedNICCSV = "$OutputFolderPath\orphanedNIC_$($FileNameDataTime).csv"
    $script:OutputFileOrphanedSnapshotCSV = "$OutputFolderPath\orphanedSnapshot_$($FileNameDataTime).csv"
    $script:OutputFileERRORLOGS = "$OutputFolderPath\errorLogs_$($FileNameDataTime).csv"
        
    
}

#######################################
## FUNCTION 3 - Get-AzurePSConnection
#######################################

Function Get-AzurePSConnection {    
    # Ensure $SubscriptionName Parameter has been Passed or edited in the script Params.
    Try {
            $AzContext = (Get-AzContext -ErrorAction Stop )

            Try {
                Set-AzContext -TenantId $AzContext.Subscription.TenantID -SubscriptionName $AzContext.Subscription.name -ErrorAction Stop -WarningAction Stop
            } Catch [System.Management.Automation.PSInvalidOperationException] {
                Write-Error "Error: $($error[0].Exception)"
                Exit
            }

        } Catch {

            # If not logged into Azure
            if($error[0].Exception.ToString().Contains("Run Login-AzAccount to login.")) {

                # Login to Azure
                Login-AzAccount -ErrorAction Stop

                # Show Out-GridView for a pick list of Tenants / Subscriptions
                $AzContext = (Get-AzContext -ErrorAction Stop )

                Try {
                    Set-AzContext -TenantId $AzContext.Subscription.TenantID -SubscriptionName $AzContext.Subscription.name -ErrorAction Stop -WarningAction Stop
                } Catch [System.Management.Automation.PSInvalidOperationException] {
                    Write-Error "Error: $($error[0].Exception)"
                    Exit
                }

            } else { # EndIf Not Logged In

                Write-Error "Error: $($error[0].Exception)"
                Exit

            }
        }    

    $Script:ActiveSubscriptionName = (Get-AzContext).Subscription.Name
    $Script:ActiveSubscriptionID = (Get-AzContext).Subscription.Id

    # Successfully logged into Az
    Out-ToHostAndFile "SUCCESS: " "Green" -nonewline; `
    Out-ToHostAndFile "Logged into Azure using Account ID: " -NoNewline; `
    Out-ToHostAndFile (Get-AzContext).Account.Id "Green"
    Out-ToHostAndFile " "
    Out-ToHostAndFile "Subscription Name: " -NoNewline; `
    Out-ToHostAndFile $Script:ActiveSubscriptionName "Green"
    Out-ToHostAndFile "Subscription ID: " -NoNewline; `
    Out-ToHostAndFile $Script:ActiveSubscriptionID "Green"
    Out-ToHostAndFile " "

} # End of function Login-To-Azure


###############################################
## FUNCTION 4 - Export-ReportDataCSV
###############################################
Function Export-ReportDataCSV
{
    param (
        [Parameter(Position=0,Mandatory=$true)]
        $HashtableOfData,

        [Parameter(Position=1,Mandatory=$true)]
        $FullFilePath
    )

	# Create an empty Array to hold Hash Table
	$Data = @()
	$Row = New-Object PSObject
	$HashtableOfData.GetEnumerator() | ForEach-Object {
		# Loop Hash Table and add to PSObject
		$Row | Add-Member NoteProperty -Name $_.Name -Value $_.Value
    }

    # Add Subscription Name and ID to CSV File for Reporting
    $Row | Add-Member NoteProperty -Name "Subscription Name" -Value $Script:ActiveSubscriptionName
    $Row | Add-Member NoteProperty -Name "Subscription ID" -Value $Script:ActiveSubscriptionID

	# Assign PSObject to Array
	$Data = $Row

	# Export Array to CSV
    $Data | Export-CSV -Path $FullFilePath -Encoding UTF8 -NoTypeInformation -Append -Force

}
Function uploadFiles
{
   
    param (
        [Parameter(Position=0,Mandatory=$true)]
        $FullFilePath
        )
        try {
            if( $null -ne $FullFilePath -or "" -ne $FullFilePath)
            {
                if(Test-Path $FullFilePath){          
                            Out-ToHostAndFile "Uploading File"
                            $storageAccount = Get-AzStorageAccount -ResourceGroupName $storageRG -Name $storageName 
                            $ctx = $storageAccount.Context    
                            Set-AzStorageBlobContent -File $FullFilePath  -Container $container   -Blob $FullFilePath.Substring($FullFilePath.LastIndexOf('\')+1)  -Context $ctx  -Force -Confirm:$False | Out-Null
                            Out-ToHostAndFile "Upload complete"           
                }
                    
            }
        }
        catch {
            Out-ToHostAndFile "Upload Failed"
            Out-ToHostAndFile $_.Exception.Message         
        }
    
}
###############################################
## FUNCTION 5 - Get-BlobSpaceUsedInGB
###############################################
Function Get-BlobSpaceUsedInGB
{
    param (
        [Parameter(Mandatory=$true)]
        [Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageBlob]$Blob
        )

    # Base + blob name
    $blobSizeInBytes = 124 + $Blob.Name.Length * 2

    # Get size of metadata
    $metadataEnumerator = $Blob.ICloudBlob.Metadata.GetEnumerator()
    while ($metadataEnumerator.MoveNext())
    {
        $blobSizeInBytes += 3 + $metadataEnumerator.Current.Key.Length + $metadataEnumerator.Current.Value.Length
    }

    if ($Blob.BlobType -eq [Microsoft.WindowsAzure.Storage.Blob.BlobType]::BlockBlob) 
    {
        try {
            #BlockBlob 
            $blobSizeInBytes += 8
            $Blob.ICloudBlob.DownloadBlockList() | ForEach-Object { $blobSizeInBytes += $_.Length + $_.Name.Length }
        } catch {
            #Error, unable to determine Block Blob used space
            Out-ToHostAndFile "Info: " "Yellow" -NoNewLine
            Out-ToHostAndFile "Unable to determine the Used Space inside Block Blob: $($Blob)"
            Out-ToHostAndFile " "
            return "Unknown"
        }
    } else { 
        try {
            #Page Blob
            $Blob.ICloudBlob.GetPageRanges() | ForEach-Object { $blobSizeInBytes += 12 + $_.EndOffset - $_.StartOffset }
        } catch {
            # Error, unable to determine Page Blob used space
            Out-ToHostAndFile "Info: " "Yellow" -NoNewLine
            Out-ToHostAndFile "Unable to determine the Used Space inside Page Blob: $($Blob)"
            Out-ToHostAndFile " "
            return "Unknown"
        }
    }

    # Return the BlobSize in GB
    return ([math]::Round($blobSizeInBytes / 1024 / 1024 / 1024))
}

 
###############################################
## FUNCTION 6 - Get-UnattachedUnmanagedDisks
###############################################
Function ErrorLogs
    {
        Param(
            [parameter(Position=1)]
            [string]$vmname,
    
            [parameter(Position=2)]
            [string]$RG
        )
       
        $ExceptionData = [ordered]@{}
        $ExceptionData.Add("Error Message",$_.Exception.Message)
        $ExceptionData.Add("Error in Line",$_.InvocationInfo.Line)
        $ExceptionData.Add("Error in Line Number",$_.InvocationInfo.ScriptLineNumber) 
        $ExceptionData.Add("Resource Name",$vmname)
        $ExceptionData.Add("ResourceGroup",$RG)
        
        $ExceptionData.GetEnumerator() | Sort-Object -Property Name -Descending | ForEach-Object {
        $line = "`t{0} = {1}" -f $_.key, $_.value
            Out-ToHostAndFile $line
        }
        Out-ToHostAndFile " "
        #Function to export data as CSV
        Export-ReportDataCSV $ExceptionData $OutputFileERRORLOGS   
        
    }
Function Get-UnattachedUnmanagedDisks {
   try {    
    Out-ToHostAndFile "Checking for Unattached Unmanaged Disks...."
    Out-ToHostAndFile " "
    $storageAccounts = Get-AzStorageAccount | Where-Object {$_.ResourceGroupName -match $paramRG}
    [array]$OrphanedDisks = @()
    foreach($storageAccount in $storageAccounts){
       
        try {
            $storageKey = (Get-AzStorageAccountKey -ResourceGroupName $storageAccount.ResourceGroupName -Name $storageAccount.StorageAccountName -ErrorAction Stop)[0].Value
        } catch {
            # Check switch to ignore these Storage Account Access Warnings
            if(!$IgnoreAccessWarnings.IsPresent) {
                # If there is a lock on the storage account, this can cause an error, skip these.
                if($error[0].Exception.ToString().Contains("Please remove the lock and try again")) {
                    Out-ToHostAndFile "Info: " "Yellow" -NoNewLine
                    Out-ToHostAndFile "Unable to obtain Storage Account Key for Storage Account below due to Read Only Lock:"
                    Out-ToHostAndFile "Storage Account: $($storageAccount.StorageAccountName) - Resource Group: $($storageAccount.ResourceGroupName) - Read Only Lock Present: True"
                    Out-ToHostAndFile " "
                } elseif($error[0].Exception.ToString().Contains("does not have authorization to perform action")) {
                    Out-ToHostAndFile "Info: " "Yellow" -NoNewLine
                    Out-ToHostAndFile "Unable to obtain Storage Account Key for Storage Account below due lack of permissions:"
                    Out-ToHostAndFile "Storage Account: $($storageAccount.StorageAccountName) - Resource Group: $($storageAccount.ResourceGroupName)"
                    Out-ToHostAndFile " "
                }
            }
            # Skip this Storage Account, move to next item in For-Each Loop
            Continue
        }
    try {
            $context = New-AzStorageContext -StorageAccountName $storageAccount.StorageAccountName -StorageAccountKey $storageKey
            $containers = Get-AzStorageContainer -Context $context -ErrorAction Stop
        } catch {
            Out-ToHostAndFile "Error: " "Red" -NoNewLine
            if($error[0].Exception.ToString().Contains("This request is not authorized to perform this operation")) {
                # Error: The remote server returned an error: (403) Forbidden.
                Out-ToHostAndFile "Unable to access the Containers in the Storage Account below, Error 403 Forbidden (not authorized)."
                Out-ToHostAndFile "Storage Account: $($storageAccount.StorageAccountName) - Resource Group: $($storageAccount.ResourceGroupName)"
            } else {
                Out-ToHostAndFile "Storage Account: $($storageAccount.StorageAccountName) - Resource Group: $($storageAccount.ResourceGroupName)"
                Out-ToHostAndFile "$($error[0].Exception)"
            }
            Out-ToHostAndFile " "
            # Skip this Storage Account, move to next item in For-Each Loop
            Continue
        }

        foreach($cnt in $containers) {

            $blobs = Get-AzStorageBlob -Container $cnt.Name -Context $context `
            -Blob *.vhd | Where-Object { $_.BlobType -eq 'PageBlob' }

            #Fetch all the Page blobs with extension .vhd as only Page blobs can be attached as disk to Azure VMs
            $blobs | ForEach-Object { 

                #If a Page blob is not attached as disk then LeaseStatus will be unlocked
                if($PSItem.ICloudBlob.Properties.LeaseStatus -eq 'Unlocked') {

                    #Add each Disk to an array
                    $OrphanedDisks += $PSItem
                    #Function to get Used Space
                    $BlobUsedDiskSpace = Get-BlobSpaceUsedInGB $PSItem

                    #Create New Hash Table for results
                    $DiskOutput = [ordered]@{}
                    $DiskOutput.Add("StorageAccountResourceGroup",$storageAccount.ResourceGroupName)
                    $DiskOutput.Add("StorageAccountName",$storageAccount.StorageAccountName)
                    $DiskOutput.Add("StorageAccountType",$storageAccount.Sku.Tier)
                    $DiskOutput.Add("StorageAccountLocation",$storageAccount.Location)
                    $DiskOutput.Add("DiskName",$PSItem.Name)
                    $DiskOutput.Add("DiskSizeGB",[math]::Round($PSItem.ICloudBlob.Properties.Length / 1024 / 1024 / 1024))
                    $DiskOutput.Add("DiskSpaceUsedGB",$BlobUsedDiskSpace)
                    $DiskOutput.Add("LastModified",$PSItem.ICloudBlob.Properties.LastModified)
                    $DiskOutput.Add("DiskUri",$PSItem.ICloudBlob.Uri.AbsoluteUri)
                   
                    $DiskOutput.GetEnumerator() | Sort-Object -Property Name -Descending | ForEach-Object {
                        $line = "`t{0} = {1}" -f $_.key, $_.value
                        Out-ToHostAndFile $line
                    }
                    Out-ToHostAndFile " "

                    #Function to export data as CSV
                    Export-ReportDataCSV $DiskOutput $OutputFileUnmanagedDisksCSV
                }

            }

        }
     
    }
    if($OrphanedDisks.Count -gt 0) {
        Out-ToHostAndFile "Orphaned Unmanaged Disks Count = $($OrphanedDisks.Count)`n" "Red"
        UploadFiles $OutputFileUnmanagedDisksCSV
    } else {
            Out-ToHostAndFile "No Orphaned Unmanaged Disks found" "Green"
            Out-ToHostAndFile " "
        }
   
}
catch {        
        ErrorLogs "Error while get storage context" $paramRG   
    }
  
}

#############################################
## FUNCTION 7 - Get-UnattachedManagedDisks
#############################################
Function Get-UnattachedManagedDisks {
    Out-ToHostAndFile "Checking for Unattached Managed Disks...."
    Out-ToHostAndFile " "

    # ManagedBy property stores the Id of the VM to which Managed Disk is attached to
    # If ManagedBy property is $null then it means that the Managed Disk is not attached to a VM

    # Additional check added for Azure Site Recovery (ASR): If the Disk Name ends in "-ASRReplica" it is highly likely
    # the disk is a DR replica, this check excludes those disks from processing. 

    $ManagedDisks = @(Get-AzDisk | Where-Object {$_.ResourceGroupName -match $paramRG -and $PSItem.ManagedBy -eq $Null -and !$PSItem.Name.EndsWith("-ASRReplica")})
    if($ManagedDisks.Count -gt 0) {  
            
        foreach ($Disk in $ManagedDisks) {
            try {
                Out-ToHostAndFile "Managed Disk Start"
                    
                # Add Orphaned Tag
                $tags = @{"VMName"="Orphaned";}
                $resource = Get-AzResource -Name $Disk.Name -ResourceGroup $Disk.ResourceGroupName -ResourceType "Microsoft.Compute/disks"
                Update-AzTag -ResourceId $resource.id -Tag $tags -Operation Merge    
               
                #Create New Hash Table for results
                $DiskOutput = [ordered]@{}
                $DiskOutput.Add("DiskResourceGroupName",$Disk.ResourceGroupName)
                $DiskOutput.Add("Name",$Disk.Name)
                $DiskOutput.Add("DiskType",$Disk.Sku.Tier)
                $DiskOutput.Add("OSType",$Disk.OSType)
                $DiskOutput.Add("DiskSizeGB",$Disk.DiskSizeGB)
                $DiskOutput.Add("TimeCreated",$Disk.TimeCreated)
                $DiskOutput.Add("ID",$Disk.Id)
                $DiskOutput.Add("Location",$Disk.Location)

                $DiskOutput.GetEnumerator() | Sort-Object -Property Name -Descending | ForEach-Object {
                    $line = "`t{0} = {1}" -f $_.key, $_.value
                    Out-ToHostAndFile $line
                }
                Out-ToHostAndFile " "
                #Function to export data as CSV
                Export-ReportDataCSV $DiskOutput $OutputFileManagedDisksCSV
                Out-ToHostAndFile "Managed Disk End"                
            }
            catch {
                ErrorLogs $Disk.Name $Disk.ResourceGroupName
            }               
        }        
        Out-ToHostAndFile "Orphaned Managed Disks Count = $($ManagedDisks.Count)`n" "Red"
        UploadFiles $OutputFileManagedDisksCSV
    } 
    else {
        Out-ToHostAndFile "No Orphaned Managed Disks found" "Green"
        Out-ToHostAndFile " "
    }    
 }

Function Get-UnattachedNICs {
    Out-ToHostAndFile "Checking for Unattached Network Interfaces...."
    Out-ToHostAndFile " "
    [array]$OrphanedNICs = @()
    
    $NicList = Get-AzNetworkInterface | Where-Object {$_.ResourceGroupName -match $paramRG -and $Null -eq $PSItem.VirtualMachine}
    Foreach ($Nic in $NicList)
    {
        try {
            Out-ToHostAndFile "Unattached NIC Start"
            
            $OrphanedNICs += $Nic
            $tags = @{"VMName"="Orphaned";}
            $resource = Get-AzResource -Name $Nic.Name -ResourceGroup $Nic.ResourceGroupName -ResourceType "Microsoft.Network/networkInterfaces"
            Update-AzTag -ResourceId $resource.id -Tag $tags -Operation Merge    

            $NICOutput = [ordered]@{}
            $NICOutput.Add("NICResourceGroup", $Nic.ResourceGroupName)
            $NICOutput.Add("NICName", $Nic.Name)

            #Function to export data as CSV
            Export-ReportDataCSV $NICOutput $OutputFileManagedNICCSV
            Out-ToHostAndFile "Unattached NIC End"           
        }
        catch {
            ErrorLogs $Nic.Name $Nic.ResourceGroupName                  
        }
        
    }      
    if($OrphanedNICs.Count -gt 0) {
        Out-ToHostAndFile "Orphaned Network Interfaces Count = $($OrphanedNICs.Count)`n" "Red"
        UploadFiles $OutputFileManagedNICCSV  
         }
    else {
            Out-ToHostAndFile "No Orphaned Network Interfaces found" "Green"
            Out-ToHostAndFile " "
        }    

 }
Function Get-Snapshots {   
$boolSnapExist=$false
    Get-AzResourceGroup  | Where-Object {$_.ResourceGroupName -match $paramRG } | ForEach-Object { 
        $RG = $_.ResourceGroupName
        
        Get-AzSnapshot -ResourceGroupName $_.ResourceGroupName  | ForEach-Object { 
              try {
                Out-ToHostAndFile "Snapshot start."
                $snapShotName = $_.Name
                $SSarr =  $_.creationdata.sourceresourceid -split "/" 
                $diskname = $SSarr[$SSarr.Length-1]
        
                #Fetching Disk Manged By
                #Looping through disk because disk linked to snapshot could exist in diffrent RG
                Get-AzDisk | Where-Object {$_.Name -eq $diskname -and $_.ResourceGroupName -match $paramRG } | ForEach-Object {
                  try{
                     if($null -eq $_.ManagedBy)
                    {
                        $tags = @{"VMName"="Orphaned";}                        
                        $resource = Get-AzSnapshot -Name $snapShotName -ResourceGroup $RG 
                        Update-AzTag -ResourceId $resource.id -Tag $tags -Operation Merge | Out-null
                        
                        $SSOutput = [ordered]@{}
                        $SSOutput.Add("Name",$_.Name)
                        $SSOutput.Add("AttachedTo","")
                        $SSOutput.Add("SnapshotResourceGroup",$RG)
                        $SSOutput.Add("Location",$resource.Location)                                                    
                        $SSOutput.GetEnumerator() | Sort-Object -Property Name -Descending | ForEach-Object {
                        $line = "`t{0} = {1}" -f $_.key, $_.value
                            Out-ToHostAndFile $line
                        }
                        Out-ToHostAndFile " "
                        #Function to export data as CSV
                        Export-ReportDataCSV $SSOutput $OutputFileOrphanedSnapshotCSV 
                                                 
                   }
                   else
                    {                        
                        $vmArr = $_.ManagedBy -split "/" 
                        $vm = $vmArr[$vmArr.Length-1]
                         
                        $tags = @{"VMName"=$vm;}
                        $resource = Get-AzSnapshot -Name $snapShotName  -ResourceGroup $RG
                        Update-AzTag -ResourceId $resource.id -Tag $tags -Operation Merge | Out-null
                        
                        $SSOutput = [ordered]@{}
                        $SSOutput.Add("Name",$snapShotName)
                        $SSOutput.Add("AttachedTo",$vm)
                        $SSOutput.Add("Location",$resource.Location)                                
                    
                        $SSOutput.GetEnumerator() | Sort-Object -Property Name -Descending | ForEach-Object {
                        $line = "`t{0} = {1}" -f $_.key, $_.value
                            Out-ToHostAndFile $line
                        }
                        Out-ToHostAndFile " "

                        #Function to export data as CSV
                        Export-ReportDataCSV $SSOutput $OutputFileOrphanedSnapshotCSV 
                        
                   }
                   $boolSnapExist=$true   
                  }
                  catch{
                        ErrorLogs $snapShotName $RG
                    }                
                 }
                $SSarr = $null
                Out-ToHostAndFile "Snapshot end."               
              }
              catch {                
                ErrorLogs $diskname $RG               
              }                
      }
              
         if($boolSnapExist -eq $true){
            UploadFiles $OutputFileOrphanedSnapshotCSV         
         }
         
    }
    
}
  

#######################################################
# Start PowerShell Script
#######################################################

if($null -eq $paramRG -or "" -eq $paramRG){
    Throw "The parameter(paramRG) is requried."
}
if("*" -eq $paramRG){
    $paramRG = ""
}

Set-OutputLogFiles

[string]$DateTimeNow = Get-Date -Format "dd/MM/yyyy - HH:mm:ss"
Out-ToHostAndFile "=====================================================================`n"
Out-ToHostAndFile "$($DateTimeNow) - 'Get Orphaned Disks' Script Starting...`n"
Out-ToHostAndFile "====================================================================="
Out-ToHostAndFile " "

Get-AzurePSConnection

Get-UnattachedManagedDisks
if($Script:isChkUnmanagedDisk -eq $true){
    Get-UnattachedUnmanagedDisks
}

Get-UnattachedNICs

Get-Snapshots
if(Test-Path $script:OutputFileERRORLOGS){          
    UploadFiles $OutputFileERRORLOGS
}

[string]$DateTimeNow = Get-Date -Format "dd/MM/yyyy - HH:mm:ss"
Out-ToHostAndFile " "
Out-ToHostAndFile "=====================================================================`n"
Out-ToHostAndFile "$($DateTimeNow) - 'Get Orphaned Disks' Script Complete`n"
Out-ToHostAndFile "=====================================================================`n"

