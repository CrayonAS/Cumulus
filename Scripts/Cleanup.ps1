[CmdletBinding()]
param(    
    [PSCredential] $Credential,
    [Parameter(Mandatory=$False, HelpMessage='Tenant ID (This is a GUID which represents the "Directory ID" of the AzureAD tenant into which you want to create the apps')]
    [string] $tenantId
)

Import-Module AzureAD
$ErrorActionPreference = 'Stop'

Function Cleanup
{
<#
.Description
This function removes the Azure AD applications that were created by the #1.ps1 script
#>

    

    if (!$Credential -and $TenantId)
    {
        $creds = Connect-AzureAD -TenantId $tenantId
    }
    else
    {
        if (!$TenantId)
        {
            $creds = Connect-AzureAD -Credential $Credential
        }
        else
        {
            $creds = Connect-AzureAD -TenantId $tenantId -Credential $Credential
        }
    }

    if (!$tenantId)
    {
        $tenantId = $creds.Tenant.Id
    }
    $tenant = Get-AzureADTenantDetail
    $tenantName =  ($tenant.VerifiedDomains | Where { $_._Default -eq $True }).Name
    
    # Removes the applications
    Write-Host "Cleaning-up applications from tenant '$tenantName'"

    Write-Host "Removing 'client' (AutomationEngine) if needed"
    $app=Get-AzureADApplication -Filter "identifierUris/any(uri:uri eq 'https://$tenantName/AutomationEngine')"  
    if ($app)
    {
        Remove-AzureADApplication -ObjectId $app.ObjectId
        Write-Host "Removed."

        Remove-AzureRmKeyVault -VaultName "AutomationEngineKeyVault" -ResourceGroupName "AutomationEngineResourceGroup"  -Force -Confirm:$False
        Remove-AzureRmResourceGroup -Name "AutomationEngineResourceGroup" -Force
    }

}

Cleanup -Credential $Credential -tenantId $TenantId

#$userNameDemo = 'userNameDemo'
# $passDemo = ConvertTo-SecureString -String 'passowrd' -AsPlainText -Force
# $DemoCre = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $userNameDemo,$passDemo

# Go the file path.. and run  .\Cleanup.ps1
