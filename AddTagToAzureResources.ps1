
[CmdletBinding()]
Param(
	    # Optional. Azure Subscription Name, can be passed as a Parameter
        
        #[Parameter(Mandatory=$true)]
        [parameter(Position=1)]
        [string]$paramRG = "*",
        
        [parameter(Position=2)]
        [string]$storageRG = "rg-rsoods",
        
        [parameter(Position=3)]
        [string]$storageName = "storageaccountrgrsoa82d",
        
        [parameter(Position=4)]
        [string]$container = "azure-webjobs-hosts",

        [parameter(Position=5)]
        [boolean]$IsFirstRun = $true

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
    $vmname = ""
    $script:LogErrorsBool = $false
        
    Function VMTagAndLog {
        param (
            [parameter(Position=1)]
            $context,
            [parameter(Position=2)]
            $RG
        )
        Out-ToHostAndFile "VM start"
        
        $vmtags = @{"VMName"=$vmname;}                            
        Update-AzTag -ResourceId $context.Id -Tag $vmtags -Operation Merge | Out-null
    
        $VMOutput = [ordered]@{}
        $VMOutput.Add("VMResourceGroup",$RG)
        $VMOutput.Add("VMName",$context.Name)
        $VMOutput.Add("Location",$context.Location)     
        $VMOutput.GetEnumerator() | Sort-Object -Property Name -Descending | ForEach-Object {
            $line = "`t{0} = {1}" -f $_.key, $_.value
            Out-ToHostAndFile $line
        }
        Out-ToHostAndFile " "
        #Function to export data as CSV
        Export-ReportDataCSV $VMOutput $script:OutputFileVM
        $vmBool=$true
        Out-ToHostAndFile "VM end"
    }
    Function ExtDiskTagAndLog {
        param (
            [parameter(Position=1)]
            $context,
            [parameter(Position=2)]
            $RG
        )
        Out-ToHostAndFile "External Disk Start"                
        $diskname = $context.Name
        $disk = Get-AzDisk -ResourceGroupName $RG -DiskName $diskname -ErrorAction Ignore
        if($disk -ne $null){
            $arr = $disk.ManagedBy -split "/" 
            $diskVmName = $arr[$arr.Length-1] 
            $diskTags = @{"VMName"=$diskVmName ;}   
            Update-AzTag -ResourceId $disk.Id -Tag $diskTags -Operation Merge | Out-null
            $DiskOutput = [ordered]@{}
            $DiskOutput.Add("ResourceGroupName",$disk.ResourceGroupName)
            $DiskOutput.Add("Name",$disk.Name)
            $DiskOutput.Add("OSType","External Disk") 
            $DiskOutput.Add("DiskSizeGB",$disk.DiskSizeGB)
            
            $DiskOutput.GetEnumerator() | Sort-Object -Property Name -Descending | ForEach-Object {
            $line = "`t{0} = {1}" -f $_.key, $_.value
                Out-ToHostAndFile $line
        }
            Out-ToHostAndFile " "
            #Function to export data as CSV
            Export-ReportDataCSV $DiskOutput $OutputFileDisksCSV
            $arr = $null
    }
    }
    Function NICTagAndLog {
        param (
            [parameter(Position=1)]
            $VmText,
            [parameter(Position=2)]
            $NICId,
            [parameter(Position=3)]
            $NICRG,
            [parameter(Position=4)]
            $nicName,
            [parameter(Position=5)]
            $vmName
        )
        $arr = $VmText -split "/" 
        $nicVmName = $arr[$arr.Length-1]  
        $nicTags = @{"VMName"=$nicVmName ;}   
        Update-AzTag -ResourceId $NIC.Id -Tag $nicTags -Operation Merge | Out-null
    
        $NICOutput  = [ordered]@{}
        $NICOutput.Add("ResourceGroupName",$NICRG)
        $NICOutput.Add("Name",$nicName)
        $NICOutput.Add("AttachedTo",$vmName)            
        $NICOutput.GetEnumerator() | Sort-Object -Property Name -Descending | ForEach-Object {
        $line = "`t{0} = {1}" -f $_.key, $_.value
        Out-ToHostAndFile $line                
        }
        Out-ToHostAndFile " "
        #Function to export data as CSV
        Export-ReportDataCSV $NICOutput $OutputFileNICCSV
        $arr = $null
    }
    Function SnapshotTagAndLog {
        param (
            [parameter(Position=1)]
            $vm,
            [parameter(Position=2)]
            $snapshotId,
            [parameter(Position=3)]
            $snapshotName,
            [parameter(Position=4)]
            $location
        )
        Out-ToHostAndFile "Snapshot Start"
        $vmArr = $vm -split "/"
        $vmname = $vmArr[$vmArr.length-1]                                
        $tags = @{"VMName"=$vmname;}
        Update-AzTag -ResourceId $snapshotId -Tag $tags -Operation Merge | Out-null
    
        $SSOutput = [ordered]@{}
        $SSOutput.Add("Name",$snapshotName)
        $SSOutput.Add("AttachedTo",$vmname)
        $SSOutput.Add("Location",$location)                
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
    Function DiskTagAndLog {
        param (
            [parameter(Position=1)]
            $context,
            [parameter(Position=2)]
            $vmtags
        )
        Out-ToHostAndFile "OS disk start"
        $resource = Get-Azdisk -Name $context.StorageProfile.OsDisk.Name -ResourceGroup $RG 
        Update-AzTag -ResourceId $resource.id -Tag $vmtags -Operation Merge | Out-null
        
    
        $DiskOutput = [ordered]@{}
        $DiskOutput.Add("ResourceGroupName",$RG)
        $DiskOutput.Add("Name",$context.StorageProfile.OsDisk.Name)
        $DiskOutput.Add("OSType",$context.StorageProfile.OsDisk.OsType)        
        $DiskOutput.Add("DiskSizeGB",$context.StorageProfile.OsDisk.DiskSizeGB)
    
        $DiskOutput.GetEnumerator() | Sort-Object -Property Name -Descending | ForEach-Object {
        $line = "`t{0} = {1}" -f $_.key, $_.value
            Out-ToHostAndFile $line
        }
        Out-ToHostAndFile " "
    
        #Function to export data as CSV
        Export-ReportDataCSV $DiskOutput $OutputFileDisksCSV
        Out-ToHostAndFile "OS disk End"
    }
    if($IsFirstRun -eq $true){
        Get-AzResourceGroup | Where-Object {$_.ResourceGroupName -match $paramRG } | ForEach-Object { 
        
            $RG = $_.ResourceGroupName    
            Get-AzVM -ResourceGroupName $_.ResourceGroupName  | ForEach-Object {  
            $vmname = $_.Name                     
            try{
                 # VM ########################    
                 VMTagAndLog $_ $RG
        
            }catch
            {
                ErrorLogs $vmname $RG
            }
        
            try{
                #OS Data disk
                if($_.StorageProfile.OsDisk.Vhd -eq $null){
                    DiskTagAndLog $_ $vmtags
                }
            }catch
            {
                ErrorLogs $vmname $RG
            }
            
            try{
                #Ext Data disk
                $_.StorageProfile.DataDisks | ForEach-Object{            
                    if($_.Vhd -eq $null){
                        ExtDiskTagAndLog $_ $RG
                        }
                        else {                
                            Get-AzDisk | Where-Object {$_.Name -eq $diskname } | ForEach-Object {                
                                $arr = $_.ManagedBy -split "/" 
                                $diskVmName = $arr[$arr.Length-1] 
                                $diskTags = @{"VMName"=$diskVmName ;}   
                                Update-AzTag -ResourceId $_.Id -Tag $diskTags -Operation Merge | Out-null
                                $DiskOutput = [ordered]@{}
                                $DiskOutput.Add("ResourceGroupName",$_.ResourceGroupName)
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
                        }
                    Out-ToHostAndFile "External Disk end"
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
                    $NIC = Get-AzNetworkInterface -ResourceGroupName $RG -Name $nicName -ErrorAction Ignore
                    if($null -ne $NIC){
                        $str = ($NIC.VirtualMachineText | ConvertFrom-Json).Id        
                        NICTagAndLog $str $NIC.Id $NIC.ResourceGroupName $nicName $vmname                 
                    }
                    else {            
                        #NIC could exist in different RG i.e why we are looping through 
                        Get-AzNetworkInterface | Where-Object {$_.Name -eq $nicName} | ForEach-Object {                
                            $str = ($_.VirtualMachineText | ConvertFrom-Json).Id                
                            NICTagAndLog $str $_.Id $_.ResourceGroupName $nicName $vmname
                            
                        }
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
                    $ssDisk = Get-AzDisk -ResourceGroupName $RG -DiskName $diskname -ErrorAction Ignore
                    if($ssDisk -ne $null){
                        $vm = $ssDisk.ManagedBy 
                        if($vm -ne $null)
                            {
                                SnapshotTagAndLog $vm $snapshotId $snapshotName $ssDisk.Location
                            }   
                        }
                                    
                else {            
                    #Fetching Disk Manged By          
                    Get-AzDisk | Where-Object {$_.Name -eq $diskname} | ForEach-Object {
                        $vm = $_.ManagedBy 
                        if($vm -ne $null)
                            {
                                SnapshotTagAndLog $vm $snapshotId $snapshotName $ssDisk.Location
                            }   
                        }
                        $SSarr = $null
                }
                
            }               
            }catch
            {
                ErrorLogs $vmname $RG
            }
        }
    }
    else{
    Get-AzResourceGroup | Where-Object {$_.ResourceGroupName -match $paramRG } | ForEach-Object { 
        
        $RG = $_.ResourceGroupName    
        Get-AzVM -ResourceGroupName $_.ResourceGroupName  | ForEach-Object {  
            $vmname = $_.Name                     
        try{
             # VM ########################   
             if($_.Tags.Count -ge 1){
                if(!$_.Tags.Keys.Contains("VMName"))
                { 
                    VMTagAndLog $_ $RG
                }
             }
             else {
                VMTagAndLog $_ $RG
             }
    
        }
        catch
        {
            ErrorLogs $vmname $RG
        }
    
        try{
            #OS Data disk
            if($_.StorageProfile.OsDisk.Vhd -eq $null){
                $tags = (Get-AzResource -ResourceGroupName $RG -Name $_.StorageProfile.OsDisk.Name).Tags
                
                if($tags.Count -ge 1){
                
                    if(!$tags.Keys.Contains("VMName"))
                    {            
                        DiskTagAndLog $_ $vmtags
                    }
                }
                else
                {
                    DiskTagAndLog $_ $vmtags
                }
                $tags=$null
            }
        }catch
        {
            ErrorLogs $vmname $RG
        }
        
        try{
            #Ext Data disk        
            $_.StorageProfile.DataDisks | ForEach-Object{            
            $diskname = $_.Name
            if($_.Vhd -eq $null){
                  $tags = (Get-AzResource -ResourceGroupName $RG -Name $_.Name).Tags
                if($tags.Count -ge 1){
                    if(!$tags.Keys.Contains("VMName")){
                        ExtDiskTagAndLog $_ $RG
                        }
                    }
                }
                 else
                {
                    ExtDiskTagAndLog $_ $RG
                }            
            }
            else 
            {                
                Get-AzDisk | Where-Object {$_.Name -eq $diskname } | ForEach-Object {  
                    $tags = (Get-AzResource -ResourceGroupName $RG -Name $diskname).Tags
                    if($tags.Count -ge 1){              
                        if(!$tags.Keys.Contains("VMName"))
                           {
                            ExtDiskTagAndLog $_ $RG
                            }
                    }
                    else
                    {
                        ExtDiskTagAndLog $_ $RG
                    }
                }
            }
            
        }catch
        {
            ErrorLogs $vmname $RG
        }
            
        try {
            #NIC
            $_.NetworkProfile.NetworkInterfaces | ForEach-Object{
                
                $nicArr = $_.Id -split "/" 
                $nicName = $nicArr[$nicArr.Length-1]     
                $NIC = Get-AzNetworkInterface -ResourceGroupName $RG -Name $nicName -ErrorAction Ignore
                if($NIC -ne $null){
                    $tags = (Get-AzResource -ResourceGroupName $RG -Name $nicName).Tags                
                    if($tags.Count -ge 1){                     
                        if(!$tags.Keys.Contains("VMName")){
                            Out-ToHostAndFile "NIC Start"
                            $str = ($NIC.VirtualMachineText | ConvertFrom-Json).Id                
                            NICTagAndLog $str $NIC.Id $NIC.ResourceGroupName $nicName $vmname                 
                        }
                     }
                     else{
                         Out-ToHostAndFile "NIC Start"
                            $str = ($NIC.VirtualMachineText | ConvertFrom-Json).Id                
                            NICTagAndLog $str $NIC.Id $NIC.ResourceGroupName $nicName $vmname                   
                     }
                }
                else {            
                    #NIC could exist in different RG i.e why we are looping through 
                    Get-AzNetworkInterface | Where-Object {$_.Name -eq $nicName} | ForEach-Object { 
                    $tags = (Get-AzResource -ResourceGroupName $RG -Name $nicName).Tags
                    if($tags.Count -ge 1){  
                        if(!$tags.Keys.Contains("VMName")){
                            Out-ToHostAndFile "NIC Start"               
                            $str = ($_.VirtualMachineText | ConvertFrom-Json).Id                
                            NICTagAndLog $str $_.Id $_.ResourceGroupName $nicName $vmname                   
                        }
                    }
                    else
                    {
                        Out-ToHostAndFile "NIC Start"               
                            $str = ($_.VirtualMachineText | ConvertFrom-Json).Id                
                            NICTagAndLog $str $_.Id $_.ResourceGroupName $nicName $vmname                    
                    }
                }
                $nicArr = $null
                
                
            }
           }
        }
        catch
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
                $ssDisk = Get-AzDisk -ResourceGroupName $RG -DiskName $diskname -ErrorAction Ignore
                if($ssDisk -ne $null){
                    $vm = $ssDisk.ManagedBy 
                    if($vm -ne $null)
                        {
                        $tags = (Get-AzResource -ResourceGroupName $RG -Name $_.Name).Tags
                        if($tags.Count -ge 1){  
                            if(!$tags.Keys.Contains("VMName")){
                                SnapshotTagAndLog $vm $snapshotId $snapshotName $ssDisk.Location
                               }
                            }
                        else{
                            SnapshotTagAndLog $vm $snapshotId $snapshotName $ssDisk.Location
                         }
                        }   
                    }
                                
            else {            
                #Fetching Disk Manged By          
                Get-AzDisk | Where-Object {$_.Name -eq $diskname} | ForEach-Object {
                    $vm = $_.ManagedBy 
                    if($vm -ne $null)
                        {
                        $tags = (Get-AzResource -ResourceGroupName $RG -Name $_.Name).Tags
                        if($tags.Count -ge 1){  
                        if(!$tags.Keys.Contains("VMName")){
                            SnapshotTagAndLog $vm $snapshotId $snapshotName $ssDisk.Location
                           }
                        }
                        else
                        {
                            SnapshotTagAndLog $vm $snapshotId $snapshotName $ssDisk.Location
                        }
                       }   
                    }
                    $SSarr = $null
            }
            
        }               
        }
        catch
        {
            ErrorLogs $vmname $RG
        }
    }
    }
    
    
    
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
        
     