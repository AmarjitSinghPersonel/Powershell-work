Get-AzVM | Where-Object{$_.ResourceGroupName -eq "somename" -and $_.Tags.Keys -like  "VMName*"} | ForEach-Object {
   
    
        Write-Output("writesomething");
    
}
 # if($_.Tags.Keys -like "VMmName*")

 Get-AzVM | Where-Object{$_.ResourceGroupName -eq "rg-rsoods" -and $_.Tags.Keys -like "VMname*"} | ForEach-Object {
    Write-Output($_.Name);
 }

  Get-Azdisk  | ForEach-Object {
    $_.NetworkProfile.NetworkInterfaces | Where-Object{$_.Tags.Keys -like "VMname*"} | ForEach-Object{ 
          Write-Output($_.Name);
  }  
 }

   Get-AzSnapshot | Where-Object{$_.ResourceGroupName -eq "rg-rsoods" -and $_.Tags.Keys -notlike "VMname*"} | ForEach-Object {             
   Write-Output($_.Name);
   }

Get-AzNetworkInterface  -ResourceGroupName "rg-rsoods" -Name "secondmachine166"  -ErrorAction Ignore | Where-Object{$_.Tag.Keys -notlike "VMname*"} | Select-Object{$_.Tag.Keys}