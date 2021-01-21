Get-AzVM -ResourceGroupName 'SHAN-RG-EAST-US' -Name tagtest | ForEach-Object {  
$_.StorageProfile.DataDisks
}

 Get-AzNetworkInterface -ResourceGroupName "RG-RSOODS" -Name "jjjk" -ErrorAction Ignore
[CmdletBinding()]
Param(
	    # Optional. Azure Subscription Name, can be passed as a Parameter
        
        #[Parameter(Mandatory=$true)]
        [parameter(Position=1)]
        [string]$paramRG = "",
        
        [parameter(Position=2)]
        [string]$storageRG = "",
        
        [parameter(Position=3)]
        [string]$storageName = "",
        
        [parameter(Position=4)]
        [string]$container = ""

	)
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


Function Set-OutputLogFiles {

    [string]$FileNameDataTime = Get-Date -Format "yy-MM-dd_HHmmss"

    # Default to script folder, or user profile folder.
    if([string]::IsNullOrWhiteSpace($script:MyInvocation.MyCommand.Path)){
        $ScriptDir = "."
    } else {
        $ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path
    }
    $OutputFolderPath = $ScriptDir
    #CSV Output File Paths, can be unique depending on boolean flag

    $script:OutputFileDisksCSV = "$OutputFolderPath\azure-disks_$($FileNameDataTime).csv"
    $script:OutputFileVM = "$OutputFolderPath\azure-VM_$($FileNameDataTime).csv"
    $script:OutputFileNICCSV = "$OutputFolderPath\azure-NIC_$($FileNameDataTime).csv"
    $script:OutputFileSSCSV = "$OutputFolderPath\azure-SnapShot_$($FileNameDataTime).csv"
    $script:OutputFileERRORLOGS = "$OutputFolderPath\azure-ErrorLogs_$($FileNameDataTime).csv"
}

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
Function UploadFiles
{
     param (
        [Parameter(Position=0,Mandatory=$true)]
        $FullFilePath
        )
        try {
            if( $null -ne $FullFilePath -or "" -ne $FullFilePath)
            {
                if(Test-Path $FullFilePath){  
                    $fileName = $FullFilePath.Substring($FullFilePath.LastIndexOf('\')+1)        
                    $tmpStr = "Uploading "+ $fileName +" File"
                    Out-ToHostAndFile $tmpStr
                    $storageAccount = Get-AzStorageAccount -ResourceGroupName $storageRG -Name $storageName 
                    $ctx = $storageAccount.Context                        
                    Set-AzStorageBlobContent -File $FullFilePath  -Container $container   -Blob $fileName  -Context $ctx  -Force -Confirm:$False | Out-null
                    Out-ToHostAndFile "Upload complete"
                }
            }
        }
        catch {
            Out-ToHostAndFile "Upload Failed"
            Out-ToHostAndFile $_.Exception.Message         
        }
       
}
if($null -eq $paramRG -or "" -eq $paramRG){
    Throw "The parameter(paramRG) is requried."
}
if("*" -eq $paramRG){
    $paramRG = ""
    }

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
    $ExceptionData.Add("VirtualMachine",$vmname)
    $ExceptionData.Add("ResourceGroup",$RG)
    
    $ExceptionData.GetEnumerator() | Sort-Object -Property Name -Descending | ForEach-Object {
    $line = "`t{0} = {1}" -f $_.key, $_.value
        Out-ToHostAndFile $line
    }
    Out-ToHostAndFile " "
    #Function to export data as CSV
    Export-ReportDataCSV $ExceptionData $OutputFileERRORLOGS

    $script:LogErrorsBool = $true
}

Set-OutputLogFiles
Get-AzurePSConnection
$vmBool=$false 
$NICBool=$false
$SnapShotBool=$false
$script:LogErrorsBool = $false

Get-AzResourceGroup | Where-Object {$_.ResourceGroupName -match $paramRG } | ForEach-Object { 
    
    $RG = $_.ResourceGroupName    
    Get-AzVM -ResourceGroupName $_.ResourceGroupName  | ForEach-Object {  
         
    try{
         # VM ########################    
           $vmname = $_.Name                
           $vmtags = @{"VMName"=$vmname;}                            
           Update-AzTag -ResourceId $_.Id -Tag $vmtags -Operation Merge | Out-null

           $VMOutput = [ordered]@{}
           $VMOutput.Add("VMResourceGroup",$RG)
           $VMOutput.Add("VMName",$_.Name)
           $VMOutput.Add("Location",$_.Location)     
           $VMOutput.GetEnumerator() | Sort-Object -Property Name -Descending | ForEach-Object {
               $line = "`t{0} = {1}" -f $_.key, $_.value
               Out-ToHostAndFile $line
           }
           Out-ToHostAndFile " "
           #Function to export data as CSV
           Export-ReportDataCSV $VMOutput $script:OutputFileVM
           $vmBool=$true

    }catch
    {
        ErrorLogs $vmname $RG
    }

    try{
        #OS Data disk
        if($_.StorageProfile.OsDisk.Vhd -ne $null){
            Out-ToHostAndFile "OS disk start"
            $resource = Get-AzResource -Name $_.StorageProfile.OsDisk.Name -ResourceGroup $RG -ResourceType "Microsoft.Compute/disks"
            Update-AzTag -ResourceId $resource.id -Tag $vmtags -Operation Merge | Out-null
            Out-ToHostAndFile 'OS disk end'

            $DiskOutput = [ordered]@{}
            $DiskOutput.Add("ResourceGroupName",$RG)
            $DiskOutput.Add("Name",$_.StorageProfile.OsDisk.Name)
            $DiskOutput.Add("OSType",$_.StorageProfile.OsDisk.OsType)        
            $DiskOutput.Add("DiskSizeGB",$_.StorageProfile.OsDisk.DiskSizeGB)
            
            $DiskOutput.GetEnumerator() | Sort-Object -Property Name -Descending | ForEach-Object {
            $line = "`t{0} = {1}" -f $_.key, $_.value
                Out-ToHostAndFile $line
            }
            Out-ToHostAndFile " "

            #Function to export data as CSV
            Export-ReportDataCSV $DiskOutput $OutputFileDisksCSV
      }
    }catch
    {
        ErrorLogs $vmname $RG
    }
    

    try{
        #Ext Data disk
        $_.StorageProfile.DataDisks | ForEach-Object{
            if($_.Vhd -ne $null){
                Out-ToHostAndFile "External Disk Start"
                $diskname = $_.Name
                #$resource = Get-AzResource -Name  -ResourceGroup $RG -ResourceType "Microsoft.Compute/disks"
                Get-AzDisk | Where-Object {$_.Name -eq $diskname -and $_.ResourceGroupName -match $paramRG } | ForEach-Object {
                
                $arr = $_.ManagedBy -split "/" 
                $diskVmName = $arr[$arr.Length-1] 
                $diskTags = @{"VMName"=$diskVmName ;}   
                Update-AzTag -ResourceId $_.Id -Tag $diskTags -Operation Merge | Out-null
                $DiskOutput = [ordered]@{}
                $DiskOutput.Add("ResourceGroupName",$RG)
                $DiskOutput.Add("Name",$_.Name)
                $DiskOutput.Add("OSType","External Disk") 
                $DiskOutput.Add("DiskSizeGB",$_.DiskSizeGB)
                
                $DiskOutput.GetEnumerator() | Sort-Object -Property Name -Descending | ForEach-Object {
                $line = "`t{0} = {1}" -f $_.key, $_.value
                    Out-ToHostAndFile $line
                }
                Out-ToHostAndFile " "
                #Function to export data as CSV
                Export-ReportDataCSV $DiskOutput $OutputFileDisksCSV
                $arr = $null
             }
            Out-ToHostAndFile "External Disk end"
         }
        }
    }catch
    {
        ErrorLogs $vmname $RG
    }
        
    try {
        #NIC
        $_.NetworkProfile.NetworkInterfaces | ForEach-Object{
            Out-ToHostAndFile "NIC Start"
            $nicArr = $_.Id -split "/" 
            $nicName = $nicArr[$nicArr.Length-1]     
            #NIC could exist in different RG i.e why we are looping through 
            Get-AzNetworkInterface | Where-Object {$_.Name -eq $nicName -and $_.ResourceGroupName -match $paramRG } | ForEach-Object {
                
                $str = ($_.VirtualMachineText | ConvertFrom-Json).Id                
                $arr = $str -split "/" 
                $nicVmName = $arr[$arr.Length-1]  
                $nicTags = @{"VMName"=$nicVmName ;}   
                Update-AzTag -ResourceId $_.Id -Tag $nicTags -Operation Merge | Out-null
                $NICOutput  = [ordered]@{}
                $NICOutput.Add("ResourceGroupName",$RG)
                $NICOutput.Add("Name",$nicName)
                $NICOutput.Add("AttachedTo",$vmname)            
                $NICOutput.GetEnumerator() | Sort-Object -Property Name -Descending | ForEach-Object {
                $line = "`t{0} = {1}" -f $_.key, $_.value
                Out-ToHostAndFile $line                
                }
                Out-ToHostAndFile " "
                #Function to export data as CSV
                Export-ReportDataCSV $NICOutput $OutputFileNICCSV
                $arr = $null
            }
            $nicArr = $null
            Out-ToHostAndFile "NIC End"
            $NICBool=$true
            }
    }catch
    {
        ErrorLogs $vmname $RG
    }
                            
} #End ForEach VMs   
    
    try{
        #START SNAPSHOT ForEach
        Get-AzSnapshot -ResourceGroupName $RG | ForEach-Object { 
            
            $SSarr =  $_.creationdata.sourceresourceid -split "/" 
            $diskname = $SSarr[$SSarr.Length-1]
            $snapshotName = $_.Name
            $snapshotId = $_.Id
            #Fetching Disk Manged By          
         Get-AzDisk | Where-Object {$_.Name -eq $diskname -and $_.ResourceGroupName -match $paramRG } | ForEach-Object {
                $vm = $_.ManagedBy 
               if($vm -ne $null)
                {
                    Out-ToHostAndFile "Snapshot Start"
                    $vmArr = $vm -split "/"
                    $vmname = $vmArr[$vmArr.length-1]                                
                    $tags = @{"VMName"=$vmname;}
                    Update-AzTag -ResourceId $snapshotId -Tag $tags -Operation Merge | Out-null
                
                    $SSOutput = [ordered]@{}
                    $SSOutput.Add("Name",$snapshotName)
                    $SSOutput.Add("AttachedTo",$vmname)
                    $SSOutput.Add("Location",$_.Location)                                
                
                    $SSOutput.GetEnumerator() | Sort-Object -Property Name -Descending | ForEach-Object {
                    $line = "`t{0} = {1}" -f $_.key, $_.value
                        Out-ToHostAndFile $line
                    }
                    Out-ToHostAndFile " "

                    #Function to export data as CSV
                    Export-ReportDataCSV $SSOutput $OutputFileSSCSV
                    $SnapShotBool=$true
                    Out-ToHostAndFile "Snapshot end"
                }   
            }
            $SSarr = $null
        }               
    }catch
    {
        ErrorLogs $vmname $RG
    }
}

Get-AzDisk

if($vmBool -eq $true){
    UploadFiles $script:OutputFileVM
    UploadFiles $OutputFileDisksCSV # AS THERE WILL BE ALWAYS OS DISK PRESENT
}

if($NICBool -eq $true)
{
    UploadFiles $OutputFileNICCSV
}
if($SnapShotBool -eq $true)
{
    UploadFiles $OutputFileSSCSV
}
    
if($LogErrorsBool -eq $true)
{
    UploadFiles $OutputFileERRORLOGS
}
    
     
