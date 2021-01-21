
[CmdletBinding()]
Param(
	    # Optional. Azure Subscription Name, can be passed as a Parameter
	    [parameter(Position=1)]
	    [string]$SubscriptionName = "SUBSCRIPTION NAME",
        
        #[Parameter(Mandatory=$true)]
        [parameter(Position=2)]
        [string]$paramRG = "RG-RSOODS",
        
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

	)Function Out-ToHostAndFile {

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

    Out-ToHostAndFile "SUCCESS: " "Green" -nonewline; `
    Out-ToHostAndFile "Logged into Azure using Account ID: " -NoNewline; `
    Out-ToHostAndFile (Get-AzContext).Account.Id "Green"
    Out-ToHostAndFile " "
    Out-ToHostAndFile "Subscription Name: " -NoNewline; `
    Out-ToHostAndFile $Script:ActiveSubscriptionName "Green"
    Out-ToHostAndFile "Subscription ID: " -NoNewline; `
    Out-ToHostAndFile $Script:ActiveSubscriptionID "Green"
    Out-ToHostAndFile " "

}
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
        $script:OutputFolderFilePath = "$($ScriptDir)\AddVMNameTagsToResources_$($FileNameDataTime).log"

    } else {
        # OutputFolderPath param has been set, test it is valid
        if(Test-Path($OutputFolderPath)){
            # Specified folder is valid, use it.
            $script:OutputFolderFilePath = "$OutputFolderPath\AddVMNameTagsToResources_$($FileNameDataTime).log"

        } else {
            # Folder specified is not valid, default to script or user profile folder.
            $OutputFolderPath = $ScriptDir
            $script:OutputFolderFilePath = "$($ScriptDir)\AddVMNameTagsToResources_$($FileNameDataTime).log"

        }
    }

    #CSV Output File Paths, can be unique depending on boolean flag
    if($CSVUniqueFileNames.IsPresent) {
        $script:OutputFileDisksCSV = "$OutputFolderPath\azure-disks_$($FileNameDataTime).csv"
        $script:OutputFileVM = "$OutputFolderPath\azure-VM_$($FileNameDataTime).csv"
        $script:OutputFileNICCSV = "$OutputFolderPath\azure-NIC_$($FileNameDataTime).csv"
        $script:OutputFileSSCSV = "$OutputFolderPath\azure-SnapShot_$($FileNameDataTime).csv"
        
    } else {
        $script:OutputFileDisksCSV = "$OutputFolderPath\azure-disks.csv"
        $script:OutputFileVM = "$OutputFolderPath\azure-VM.csv"
        $script:OutputFileNICCSV = "$OutputFolderPath\azure-NIC.csv"
        $script:OutputFileSSCSV  = "$OutputFolderPath\azure-SnapShot.csv"
    }
}

  Function Export-ReportDataCSV
{
    param (
        [Parameter(Position=0,Mandatory=$true)]
        $HashtableOfData,

        [Parameter(Position=1,Mandatory=$true)]
        $FullFilePath
    )
    Write-Output($FullFilePath)
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

    $storageAccount = Get-AzStorageAccount -ResourceGroupName $storageRG -Name $storageName 
    $ctx = $storageAccount.Context    
    Set-AzStorageBlobContent -File $FullFilePath  -Container $container   -Blob $FullFilePath.Substring($FullFilePath.LastIndexOf('\')+1)  -Context $ctx  -Force -Confirm:$False

}

if($paramRG -eq $null -or $paramRG -eq "")
{
    throw "Resource group name(paramRG) is required parameter"
}
Install-Module -Name Az.Accounts -Force -AllowClobber
az login --service-principal -u $clientID -p $seceret --tenant $tenant
Set-OutputLogFiles
Get-AzurePSConnection
Get-AzResourceGroup | Where-Object {$_.ResourceGroupName -match $paramRG } | ForEach-Object {    
    $RG = $_.ResourceGroupName
        Get-AzResource -ResourceGroupName $_.ResourceGroupName  | Where-Object{$_.ResourceType -eq "Microsoft.Compute/virtualMachines"} | ForEach-Object {             
            $vmname = $_.ResourceName 
            
            $vmtags = @{"VMName"=$vmname;}
            $resource = Get-AzResource -Name $_.ResourceName -ResourceGroup $RG            
            Update-AzTag -ResourceId $resource.id -Tag $vmtags -Operation Merge
          
            $VMOutput = [ordered]@{}
            $VMOutput.Add("VMResourceGroup",$RG)
            $VMOutput.Add("VMName",$_.ResourceName)
            $VMOutput.Add("Location",$resource.Location)
            
            $VMOutput.GetEnumerator() | Sort-Object -Property Name -Descending | ForEach-Object {
            $line = "`t{0} = {1}" -f $_.key, $_.value
                Out-ToHostAndFile $line
            }
            Out-ToHostAndFile " "

            #Function to export data as CSV
            Export-ReportDataCSV $VMOutput $OutputFileVM

            
            $vmContext = az resource show -g $RG -n $vmname --resource-type "Microsoft.Compute/virtualMachines"                     

            #TAGGING EXTERNAL DISKS
            
            $extDisks = ( $vmContext | ConvertFrom-Json).properties.storageProfile.dataDisks
            foreach($extDisk in $extDisks)
            {                
                $extId = $extDisk.managedDisk.id
                $extDiskArr = $extId -split "/" 
                $extdiskname = $extDiskArr[$extDiskArr.Length-1]     
                $resource = Get-AzResource -Name $extdiskname  -ResourceGroup $RG
                Update-AzTag -ResourceId $resource.id -Tag $vmtags -Operation Merge
                
                
                $DiskOutput = [ordered]@{}
                $DiskOutput.Add("ResourceGroupName",$RG)
                $DiskOutput.Add("Name",$_.ResourceName)
                $DiskOutput.Add("DiskType",$resource.Sku.Tier)
                $DiskOutput.Add("OSType",$resource.OSType)
                $DiskOutput.Add("DiskSizeGB",$resource.DiskSizeGB)
                $DiskOutput.Add("TimeCreated",$resource.TimeCreated)
                $DiskOutput.Add("ID",$resource.Id)
                $DiskOutput.Add("Location",$resource.Location)                
                $DiskOutput.GetEnumerator() | Sort-Object -Property Name -Descending | ForEach-Object {
                $line = "`t{0} = {1}" -f $_.key, $_.value
                    Out-ToHostAndFile $line
                }
                Out-ToHostAndFile " "
                #Function to export data as CSV
                Export-ReportDataCSV $DiskOutput $OutputFileDisksCSV                
               
                $extDiskArr = $null
            }
            
            #TAGGING OS DISKS          
            $osDiskId = ($vmContext | ConvertFrom-Json).properties.storageProfile.osDisk.managedDisk.id           
            $osDiskArr = $osDiskId -split "/" 
            $osdiskname = $osDiskArr[$osDiskArr.Length-1]     
            $resource = Get-AzResource -Name $osdiskname -ResourceGroup $RG         
 
                Update-AzTag -ResourceId $resource.id -Tag $vmtags -Operation Merge
                
                $DiskOutput = [ordered]@{}
                $DiskOutput.Add("ResourceGroupName",$RG)
                $DiskOutput.Add("Name",$_.ResourceName)
                $DiskOutput.Add("DiskType",$resource.Sku.Tier)
                $DiskOutput.Add("OSType",$resource.OSType)
                $DiskOutput.Add("DiskSizeGB",$resource.DiskSizeGB)
                $DiskOutput.Add("TimeCreated",$resource.TimeCreated)
                $DiskOutput.Add("ID",$resource.Id)
                $DiskOutput.Add("Location",$resource.Location)
                
                $DiskOutput.GetEnumerator() | Sort-Object -Property Name -Descending | ForEach-Object {
                $line = "`t{0} = {1}" -f $_.key, $_.value
                    Out-ToHostAndFile $line
                }
                Out-ToHostAndFile " "

                #Function to export data as CSV
                Export-ReportDataCSV $DiskOutput $OutputFileDisksCSV  
                $osDiskArr= $null  
            # TAGGING NIC
            $Nics = ($vmContext | ConvertFrom-Json).properties.networkProfile

            foreach($nic in $Nics)
            {
                $nicArr = $nic.networkInterfaces.id -split "/" 
                $nicName = $nicArr[$nicArr.Length-1]     
                $resource = Get-AzResource -Name $nicName -ResourceGroup $RG
                Update-AzTag -ResourceId $resource.id -Tag $vmtags -Operation Merge                
                $NICOutput  = [ordered]@{}
                $NICOutput.Add("ResourceGroupName",$RG)
                $NICOutput.Add("Name",$_.ResourceName)
                $NICOutput.Add("AttachedTo",$vmname)
                $NICOutput.Add("Location",$resource.Location)
                
                $NICOutput.GetEnumerator() | Sort-Object -Property Name -Descending | ForEach-Object {
                $line = "`t{0} = {1}" -f $_.key, $_.value
                    Out-ToHostAndFile $line
                }
                Out-ToHostAndFile " "

                #Function to export data as CSV
                Export-ReportDataCSV $NICOutput $OutputFileNICCSV
                
                $nicArr = $null
            }   
        }    
    
    #TAGGING SNAPSHOTS
    Get-AzSnapshot -ResourceGroupName $RG | ForEach-Object { 
        $snapshot = az snapshot show --resource-group $RG --name $_.Name  --query "creationData.sourceResourceId" 
        $SSarr = $snapshot -split "/" 
        $diskname = $SSarr[$SSarr.Length-1].substring(0,$SSarr[$SSarr.Length-1].Length-1)
        #Fetching Disk Manged By
        $connectedDisk = Get-AzResource  -ResourceGroup $RG -Name $diskname
        if($connectedDisk -ne $null)
        {
            $disk = ($connectedDisk).ManagedBy 
            if($disk -ne $null)
            {
                $diskArr = $disk -split "/"
                $vmname = $diskArr[$diskArr.length-1]                                
                $tags = @{"VMName"=$vmname;}
                $resource = Get-AzResource -Name $_.Name -ResourceGroup $RG
                Update-AzTag -ResourceId $resource.id -Tag $tags -Operation Merge
                

                $SSOutput = [ordered]@{}
                $SSOutput.Add("Name",$_.ResourceName)
                $SSOutput.Add("AttachedTo",$vmname)
                $SSOutput.Add("Location",$resource.Location)                                
            
                $SSOutput.GetEnumerator() | Sort-Object -Property Name -Descending | ForEach-Object {
                $line = "`t{0} = {1}" -f $_.key, $_.value
                    Out-ToHostAndFile $line
                }
                Out-ToHostAndFile " "

                #Function to export data as CSV
                Export-ReportDataCSV $SSOutput $OutputFileSSCSV
            
            }   
        }
        $SSarr = $null
    }
}


 
