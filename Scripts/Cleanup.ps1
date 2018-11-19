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
    $ApplicationNameTobeDeleted = Read-Host " Enter the Application Name "
    
    $app=Get-AzureADApplication -Filter "identifierUris/any(uri:uri eq 'https://$tenantName/$ApplicationNameTobeDeleted')"  


    if ($app) 
    {
     
        # The Application to be deleted
        $appName = $app.DisplayName  
        Write-Host "Checking Saved keys...      $appName " -ForegroundColor Green
   
         #Getting Credentials for AzureRMAccount
        Write-Host "You need to connect AzureRmAccount to DELETE Resource Group and Key Vault! " -ForegroundColor Green
        $userNameInmeta = Read-Host "Enter Your User Name "
        $PassPrompt = Read-Host "Enter Your Password " -AsSecureString
        $passInmeta = ConvertTo-SecureString -String  $PassPrompt -AsPlainText -Force
        $InmetaCre = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $userNameInmeta,$passInmeta

        Remove-AzureADApplication -ObjectId $app.ObjectId
        Write-Host "Removed ADAL Application."

        Connect-AzureRmAccount  -Credential  $InmetaCre
        Write-Host "Removing Resource Group and Key Vault Just a minute ......"
        $ResourceGroup = Read-Host "Enter Resource Group to be Deleted "
        $KeyVault = Read-Host "Enter Key Vault to be Deleted "
        Remove-AzureRmKeyVault -VaultName $KeyVault -ResourceGroupName $ResourceGroup  -Force -Confirm:$False
     
        Remove-AzureRmResourceGroup -Name  $ResourceGroup -Force
        Write-Host " Done! "
    }

    else{

        Write-Host "No App to be deleted!...      $appName " -ForegroundColor Green
    }
}

Cleanup -Credential $Credential -tenantId $TenantId

#$userNameDemo = 'userNameDemo'
# $passDemo = ConvertTo-SecureString -String 'passowrd' -AsPlainText -Force
# $DemoCre = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $userNameDemo,$passDemo

# Go the file path.. and run  .\Cleanup.ps1
