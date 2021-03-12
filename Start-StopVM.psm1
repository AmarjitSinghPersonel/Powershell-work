

function Start-StopVM {
    param (
        [string]$ResourceGroupName,
        [string]$TableStorageName,
        [string]$TableName
        
    )

    $time = get-date -Format "HH:00"
    $day = (get-date).DayOfWeek
    $time
    $day
    $ctx = (Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $TableStorageName).Context
    $cloudTable = (Get-AzStorageTable –Name '' –Context $ctx).CloudTable
  
    [string]$Filter1 = [Microsoft.Azure.Cosmos.Table.TableQuery]::GenerateFilterCondition("StartTime",[Microsoft.Azure.Cosmos.Table.QueryComparisons]::Equal,$time)
    [string]$Filter2 = [Microsoft.Azure.Cosmos.Table.TableQuery]::GenerateFilterCondition("StartDay",[Microsoft.Azure.Cosmos.Table.QueryComparisons]::Equal,$day)
    [string]$finalFilter = [Microsoft.Azure.Cosmos.Table.TableQuery]::CombineFilters($Filter1,"and",$Filter2)
    
    Get-AzTableRow -table $cloudTable -customFilter $finalFilter | ForEach-Object{
        try
        {
             Start-AzVM -Name  $_.VMName -ResourceGroupName $_.ResourceGroup -NoWait 
        }
        catch
        {
            Write-Error "Error: $($error[0].Exception)"
        }      

    }

   
    [string]$Filter1 = [Microsoft.Azure.Cosmos.Table.TableQuery]::GenerateFilterCondition("StopTime",[Microsoft.Azure.Cosmos.Table.QueryComparisons]::Equal,$time)
    [string]$Filter2 = [Microsoft.Azure.Cosmos.Table.TableQuery]::GenerateFilterCondition("StopDay",[Microsoft.Azure.Cosmos.Table.QueryComparisons]::Equal,$day)
    [string]$finalFilter = [Microsoft.Azure.Cosmos.Table.TableQuery]::CombineFilters($Filter1,"and",$Filter2)
  
    Get-AzTableRow -table $cloudTable -customFilter $finalFilter | ForEach-Object{
    
        try
        {
               Stop-AzVM -Name  $_.VMName -ResourceGroupName $_.ResourceGroup -Force -NoWait
        }
        catch
        {
                  Write-Error "Error: $($error[0].Exception)"
        }
    

    }
}









