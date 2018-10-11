[CmdletBinding()]
param(
    [PSCredential] $Credential,
    [Parameter(Mandatory=$False, HelpMessage='Tenant ID (This is a GUID which represents the "Directory ID" of the AzureAD tenant into which you want to create the apps')]
    [string] $tenantId
)
Function CreateKeyVault
{

     # Login to AzureRM PowerShell (interactive if credentials are not already provided:
    # you'll need to sign-in with creds enabling your to create apps in the tenant)
    if (!$Credential -and $TenantId)
    {
        $creds = Connect-AzureRmAccount -TenantId $tenantId
    }
    else
    {
        if (!$TenantId)
        {
            $creds = Connect-AzureRmAccount  -Credential $Credential
        }
        else
        {
            $creds = Connect-AzureRmAccount  -TenantId $tenantId -Credential $Credential
        }
    }

    if (!$tenantId)
    {
        $tenantId = $creds.Tenant.Id
    }

        #Creating a resource group
    $ResourceGroup = New-AzureRmResourceGroup -Name 'AutomationEngineResourceGroup' -Location 'NorthEurope'

        #Creating a key Vault
    $KeyVault = New-AzureRmKeyVault -VaultName 'AutomationEngineKeyVault' -ResourceGroupName 'AutomationEngineResourceGroup' -Location 'NorthEurope'
        #Convert password to a secure string
    $secretvalue = ConvertTo-SecureString 'Password' -AsPlainText -Force
        #Store the Secret in Azure KeyVault
    $secret = Set-AzureKeyVaultSecret -VaultName 'AutomationEngineKeyVault' -Name 'ExamplePassword' -SecretValue $secretvalue

    (Get-AzureKeyVaultSecret -vaultName "AutomationEngineKeyVault" -name "ExamplePassword").SecretValueText


   # Write-Host " This is the Created Group:  $ResourceGroup"
    
   
  
}

 CreateKeyVault -Credential $Credential -tenantId $TenantId