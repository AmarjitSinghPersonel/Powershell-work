#Requires -Version 3
#Requires -Modules Az.Accounts, Az.Storage, Az.Resources

Get-AzVM -ResourceGroupName "RG-RSOODS" -Name "testmachine" -status
$vms = Get-AzVM
$publicIps = Get-AzPublicIpAddress 
$nics = ?{ $_.VirtualMachine -eq "testmachine"} 
$nics



# Define and validate parameters
[CmdletBinding()]
Param(
	    # Optional. Azure Subscription Name, can be passed as a Parameter
	    [parameter(Position=1)]
	    [string]$SubscriptionName = "SUBSCRIPTION NAME",

        [parameter(Position=2)]
        [string]$ResourceName = "cloudeqlab|shan-rg-east-us",
        
        [parameter(Position=3)]
        [string]$storageRG = "cloudeqlab",
        
        [parameter(Position=4)]
        [string]$storageName = "logfilesstoragecloudeq",
        
        [parameter(Position=5)]
        [string]$container = "logfiles",
        
        [parameter(Position=6)]
        [string]$seceret = "54zzF-i96_nOWaH110Tr5_4gBH-hVPMXG5",
        
        [parameter(Position=7)]
        [string]$tenant = "dbd61555-f8c0-4db8-83e3-d55f7565507d",
        
        [parameter(Position=8)]
        [string]$clientID = "1cba879b-4329-4860-af5d-87743b90bd9e",
	    # Folder Path for Output, if not specified defaults to script folder
	    [parameter(Position=9)]
        [string]$OutputFolderPath = "FOLDERPATH",
        # Exmaple: C:\Scripts\

        # Unique file names for CSV files, optional Switch parameter so the script defaults to same file name
	    [parameter(Position=10)]
        [switch]$CSVUniqueFileNames,

        # Ignore Access Warnings, optional Switch parameter to not output Storage Account access information
	    [parameter(Position=11)]
        [switch]$IgnoreAccessWarnings

        
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

    # Write Content to Output File
    if($NoNewLine.IsPresent) {
        Out-File -FilePath $OutputFolderFilePath -Encoding UTF8 -Append -InputObject $Content -NoNewline
    } else {
        Out-File -FilePath $OutputFolderFilePath -Encoding UTF8 -Append -InputObject $Content
    }

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

    if($OutputFolderPath -eq "FOLDERPATH") {
        # OutputFolderPath param not used
        $OutputFolderPath = $ScriptDir
        $script:OutputFolderFilePath = "$($ScriptDir)\azure-get-orphaned-resources_$($FileNameDataTime).log"

    } else {
        # OutputFolderPath param has been set, test it is valid
        if(Test-Path($OutputFolderPath)){
            # Specified folder is valid, use it.
            $script:OutputFolderFilePath = "$OutputFolderPath\azure-get-orphaned-resources_$($FileNameDataTime).log"

        } else {
            # Folder specified is not valid, default to script or user profile folder.
            $OutputFolderPath = $ScriptDir
            $script:OutputFolderFilePath = "$($ScriptDir)\azure-get-orphaned-resources_$($FileNameDataTime).log"

        }
    }

    #CSV Output File Paths, can be unique depending on boolean flag
    if($CSVUniqueFileNames.IsPresent) {
        $script:OutputFileUnmanagedDisksCSV = "$OutputFolderPath\azure-orphaned-Unmanaged-disks_$($FileNameDataTime).csv"
        $script:OutputFileManagedDisksCSV = "$OutputFolderPath\azure-orphaned-Managed-disks_$($FileNameDataTime).csv"
        $script:OutputFileManagedNICCSV = "$OutputFolderPath\azure-orphaned-NIC_$($FileNameDataTime).csv"
        
    } else {
        $script:OutputFileUnmanagedDisksCSV = "$OutputFolderPath\azure-orphaned-Unmanaged-disks.csv"
        $script:OutputFileManagedDisksCSV = "$OutputFolderPath\azure-orphaned-Managed-disks.csv"
        $script:OutputFileManagedNICCSV = "$OutputFolderPath\azure-orphaned-NIC.csv"
    }
}



#######################################
## FUNCTION 3 - Get-AzurePSConnection
#######################################

Function Get-AzurePSConnection {

    [string]$GridViewTile = "Select the Subscription/Tenant ID to IDENTIFY any Unattached Disks"
    
    # Ensure $SubscriptionName Parameter has been Passed or edited in the script Params.
    if($SubscriptionName -eq "SUBSCRIPTION NAME") {

        Try {

            $AzContext = (Get-AzSubscription -ErrorAction Stop | Out-GridView `
            -Title $GridViewTile `
            -PassThru)

            Try {
                Set-AzContext -TenantId $AzContext.TenantID -SubscriptionName $AzContext.Name -ErrorAction Stop -WarningAction Stop
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
                $AzContext = (Get-AzSubscription -ErrorAction Stop | Out-GridView `
                -Title $GridViewTile `
                -PassThru)

                Try {
                    Set-AzContext -TenantId $AzContext.TenantID -SubscriptionName $AzContext.Name -ErrorAction Stop -WarningAction Stop
                } Catch [System.Management.Automation.PSInvalidOperationException] {
                    Write-Error "Error: $($error[0].Exception)"
                    Exit
                }

            } else { # EndIf Not Logged In

                Write-Error "Error: $($error[0].Exception)"
                Exit

            }
        }

    } else { # $SubscriptionName has been specified

        # Check if we are already logged into Azure...
        Try {

            # Set Azure RM Context to -SubscriptionName, On Error Stop, so we can Catch the Error.
            Set-AzContext -SubscriptionName $SubscriptionName -WarningAction Stop -ErrorAction Stop

        } Catch {

            # If not logged into Azure
            if($error[0].Exception.ToString().Contains("Run Login-AzAccount to login.")) {

                # Connect to Azure, as no existing connection.
                Out-ToHostAndFile "No Azure PowerShell Session found"
                Out-ToHostAndFile  "`nPrompting for Azure Credentials and Authenticating..."

                # Login to Azure Resource Manager (ARM), if this fails, stop script.
                try {
                    Login-AzAccount -SubscriptionName $SubscriptionName -ErrorAction Stop
                } catch {

                    # Authenticated with Azure, but does not have access to subscription.
                    if($error[0].Exception.ToString().Contains("does not have access to subscription name")) {

                        Out-ToHostAndFile "Error: Unable to access Azure Subscription: '$($SubscriptionName)', please check this is the correct name and/or that your account has access.`n" "Red"
                        Out-ToHostAndFile "`nDisplaying GUI to select the correct subscription...."

                        Login-AzAccount -ErrorAction Stop

                        $AzContext = (Get-AzSubscription -ErrorAction Stop | Out-GridView `
                        -Title $GridViewTile `
                        -PassThru)

                        Try {
                            Set-AzContext -TenantId $AzContext.TenantID -SubscriptionName $AzContext.Name -ErrorAction Stop -WarningAction Stop
                        } Catch [System.Management.Automation.PSInvalidOperationException] {
                            Out-ToHostAndFile "Error: $($error[0].Exception)" "Red"
                            Exit
                        }
                    }
                }

            # Already logged into Azure, but Subscription does NOT exist.
            } elseif($error[0].Exception.ToString().Contains("Please provide a valid tenant or a valid subscription.")) {

                Out-ToHostAndFile "Error: You are logged into Azure with account: '$((Get-AzContext).Account.id)', but the Subscription: '$($SubscriptionName)' does not exist, or this account does not have access to it.`n" "Red"
                Out-ToHostAndFile "`nDisplaying GUI to select the correct subscription...."

                $AzContext = (Get-AzSubscription -ErrorAction Stop | Out-GridView `
                -Title $GridViewTile `
                -PassThru)

                Try {
                    Set-AzContext -TenantId $AzContext.TenantID -SubscriptionName $AzContext.Name -ErrorAction Stop -WarningAction Stop
                } Catch [System.Management.Automation.PSInvalidOperationException] {
                    Out-ToHostAndFile "Error: $($error[0].Exception)" "Red"
                    Exit
                }

            # Already authenticated with Azure, but does not have access to subscription.
            } elseif($error[0].Exception.ToString().Contains("does not have access to subscription name")) {

                Out-ToHostAndFile "Error: Unable to access Azure Subscription: '$($SubscriptionName)', please check this is the correct name and/or that account '$((Get-AzContext).Account.id)' has access.`n" "Red"
                Exit

            # All other errors.
            } else {

                Out-ToHostAndFile "Error: $($error[0].Exception)" "Red"
                # Exit script
                Exit

            } # EndIf Checking for $error[0] conditions

        } # End Catch

    } # EndIf $SubscriptionName has been set

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
function Export-ReportDataCSV
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

    Write-Output('Uploading File')
    $storageAccount = Get-AzStorageAccount -ResourceGroupName $storageRG -Name $storageName 
    $ctx = $storageAccount.Context    
    Set-AzStorageBlobContent -File $FullFilePath  -Container $container   -Blob $FullFilePath.Substring($FullFilePath.LastIndexOf('\')+1)  -Context $ctx  -Force -Confirm:$False

}

###############################################
## FUNCTION 5 - Get-BlobSpaceUsedInGB
###############################################
function Get-BlobSpaceUsedInGB
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

Function Get-UnattachedUnmanagedDisks {

    Out-ToHostAndFile "Checking for Unattached Unmanaged Disks...."
    Out-ToHostAndFile " "

    $storageAccounts = Get-AzStorageAccount

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

        $context = New-AzStorageContext -StorageAccountName $storageAccount.StorageAccountName -StorageAccountKey $storageKey
        try {
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

        foreach($container in $containers) {

            $blobs = Get-AzStorageBlob -Container $container.Name -Context $context `
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
                    $DiskOutput.Add("Metadata_VMName",$PSItem.ICloudBlob.Metadata['MicrosoftAzureCompute_VMName'])
                    $DiskOutput.Add("Metadata_DiskType",$PSItem.ICloudBlob.Metadata['MicrosoftAzureCompute_DiskType'])

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
 
    } else {

            Out-ToHostAndFile "No Orphaned Unmanaged Disks found" "Green"
            Out-ToHostAndFile " "

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

    $ManagedDisks = @(Get-AzDisk | Where-Object {$_.ResourceGroupName -match $ResourceName -and $PSItem.ManagedBy -eq $Null -and !$PSItem.Name.EndsWith("-ASRReplica")})

    if($ManagedDisks.Count -gt 0) {

        foreach ($Disk in $ManagedDisks) {

            # Add Orphaned Tag
            $tags = @{"VMName"="Orphaned";}
            $resource = Get-AzResource -Name $Disk.Name -ResourceGroup $Disk.ResourceGroupName
            Update-AzTag -ResourceId $resource.id -Tag $tags -Operation Merge    
                          
            #Create New Hash Table for results
            $DiskOutput = [ordered]@{}
            $DiskOutput.Add("ResourceGroupName",$Disk.ResourceGroupName)
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

        }

        Out-ToHostAndFile "Orphaned Managed Disks Count = $($ManagedDisks.Count)`n" "Red"

    } else {

        Out-ToHostAndFile "No Orphaned Managed Disks found" "Green"
        Out-ToHostAndFile " "

    }

}


Function Get-UnattachedNICs {

    Out-ToHostAndFile "Checking for Unattached Network Interfaces...."
    Out-ToHostAndFile " "

    [array]$OrphanedNICs = @()

    $NicList = Get-AzNetworkInterface | Where-Object {$_.ResourceGroupName -match $ResourceName -and $Null -eq $PSItem.VirtualMachine}
    Foreach ($Nic in $NicList)
    {
        $OrphanedNICs += $Nic
        $tags = @{"VMName"="Orphaned";}
        $resource = Get-AzResource -Name $Nic.Name -ResourceGroup $Nic.ResourceGroupName
        Update-AzTag -ResourceId $resource.id -Tag $tags -Operation Merge    

        $NICOutput = [ordered]@{}
        $NICOutput.Add("NICResourceGroup", $Nic.ResourceGroupName)
        $NICOutput.Add("NICName", $Nic.Name)

        #Function to export data as CSV
        Export-ReportDataCSV $NICOutput $OutputFileManagedNICCSV
    }

    if($OrphanedNICs.Count -gt 0) {

        Out-ToHostAndFile "Orphaned Network Interfaces Count = $($OrphanedNICs.Count)`n" "Red"
 
    } else {

            Out-ToHostAndFile "No Orphaned Network Interfaces found" "Green"
            Out-ToHostAndFile " "

        }
    
}


Function Get-Snapshots {
    Write-Output('Snapshot start.')#
    Get-AzResourceGroup  | Where-Object {$_.ResourceGroupName -match $ResourceName } | ForEach-Object { 
        $RG = $_.ResourceGroupName
        Write-Output('Snapshot start.'+$RG )#
        Get-AzResource -ResourceGroupName $_.ResourceGroupName  | ForEach-Object { 
            if ($_.ResourceType -eq "Microsoft.Compute/snapshots")
            {
               # Write-Output('Snapshot start.')
               Write-Output('Snapshot start.'+ $_.ResourceName)
                $snapshot = az snapshot show --resource-group $RG --name $_.ResourceName  --query "creationData.sourceResourceId"
               
                $SSarr = $snapshot -split "/" 
                $diskname = $SSarr[$SSarr.Length-1].substring(0,$SSarr[$SSarr.Length-1].Length-1)
                #Fetching Disk Manged By
                Write-Output('Snapshot start.'+$diskname)
                $connectedDisk = Get-AzResource  -ResourceGroup $RG -Name $diskname
                            if($connectedDisk -ne $null){
                $disk = ($connectedDisk).ManagedBy 
                if($null -eq $disk)
                {
                    $tags = @{"VMName"="Orphaned";}
                    $resource = Get-AzResource -Name $_.ResourceName -ResourceGroup $RG
                    Update-AzTag -ResourceId $resource.id -Tag $tags -Operation Merge
                   # Write-Output('Snapshot - ' + $_.ResourceName)
                     
                     
                }   }
                $SSarr = $null
               # Write-Output('Snapshot end.')
                 
            }
        }
    }
    Write-Output('Snapshot end.')
}

#######################################################
# Start PowerShell Script
#######################################################

az login --service-principal -u $clientID -p $seceret --tenant $tenant

Set-OutputLogFiles

[string]$DateTimeNow = Get-Date -Format "dd/MM/yyyy - HH:mm:ss"
Out-ToHostAndFile "=====================================================================`n"
Out-ToHostAndFile "$($DateTimeNow) - 'Get Orphaned Disks' Script Starting...`n"
Out-ToHostAndFile "====================================================================="
Out-ToHostAndFile " "

Get-AzurePSConnection

#Get-UnattachedManagedDisks

#Get-UnattachedUnmanagedDisks

#Get-UnattachedNICs

Get-Snapshots

[string]$DateTimeNow = Get-Date -Format "dd/MM/yyyy - HH:mm:ss"
Out-ToHostAndFile " "
Out-ToHostAndFile "=====================================================================`n"
Out-ToHostAndFile "$($DateTimeNow) - 'Get Orphaned Disks' Script Complete`n"
Out-ToHostAndFile "=====================================================================`n"

