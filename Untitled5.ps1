 #Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
#Install-Module -Name Az.KeyVault -force
#Connect-AzureRmAccount -SubscriptionId '39a939fd-de7a-45d8-91a6-a9e868096197'
$SubscriptionName = 'Development_1'
$AzContext=$null
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
              

                # Login to Azure Resource Manager (ARM), if this fails, stop script.
                try {
                    Login-AzAccount -SubscriptionName $SubscriptionName -ErrorAction Stop
                } catch {

                    # Authenticated with Azure, but does not have access to subscription.
                    if($error[0].Exception.ToString().Contains("does not have access to subscription name")) {

                        Login-AzAccount -ErrorAction Stop

                        $AzContext = (Get-AzSubscription -ErrorAction Stop | Out-GridView `
                        -Title $GridViewTile `
                        -PassThru)

                        Try {
                            Set-AzContext -TenantId $AzContext.TenantID -SubscriptionName $AzContext.Name -ErrorAction Stop -WarningAction Stop
                        } Catch [System.Management.Automation.PSInvalidOperationException] {
                           
                            Exit
                        }
                    }
                }

            # Already logged into Azure, but Subscription does NOT exist.
            } elseif($error[0].Exception.ToString().Contains("Please provide a valid tenant or a valid subscription.")) {

               
                $AzContext = (Get-AzSubscription -ErrorAction Stop | Out-GridView `
                -Title $GridViewTile `
                -PassThru)

                Try {
                    Set-AzContext -TenantId $AzContext.TenantID -SubscriptionName $AzContext.Name -ErrorAction Stop -WarningAction Stop
                } Catch [System.Management.Automation.PSInvalidOperationException] {
                   
                    Exit
                }

            # Already authenticated with Azure, but does not have access to subscription.
            } elseif($error[0].Exception.ToString().Contains("does not have access to subscription name")) {

                 Exit

            # All other errors.
            } else {

               
                # Exit script
                Exit

            } # EndIf Checking for $error[0] conditions

        } # End Catch

    } # EndIf $SubscriptionName has been set

    $Script:ActiveSubscriptionName = (Get-AzContext).Subscription.Name
    $Script:ActiveSubscriptionID = (Get-AzContext).Subscription.Id

    

}

Get-AzurePSConnection
$name = (get-azcontext).Name
 $name
Connect-AzureRmAccount -ContextName $name
(Get-AzureKeyVaultSecret -VaultName 'ServicePrincipalVault' -Name 'ServicePrincipalSecert').SecretValueText