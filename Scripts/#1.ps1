[CmdletBinding()]
param(
    [PSCredential] $Credential,
    [Parameter(Mandatory=$False, HelpMessage='Tenant ID (This is a GUID which represents the "Directory ID" of the AzureAD tenant into which you want to create the apps')]
    [string] $tenantId
)

<#
 This script creates the Azure ADAL applications   
 prerequisite to run:
  - Install AzureAD
  - Run PowerShell as Admin.
#>

# Adds the Correct permission to Applications 

Function AddResourcePermission($requiredAccess, `
                               $exposedPermissions, [string]$requiredAccesses, [string]$permissionType)
{
        foreach($permission in $requiredAccesses.Trim().Split("|"))
        {
            foreach($exposedPermission in $exposedPermissions)
            {
                if ($exposedPermission.Value -eq $permission)
                 {
                    $resourceAccess = New-Object Microsoft.Open.AzureAD.Model.ResourceAccess
                    $resourceAccess.Type = $permissionType  #Role = Application permissions
                    $resourceAccess.Id = $exposedPermission.Id 
                    $requiredAccess.ResourceAccess.Add($resourceAccess)
                 }
            }
        }
}


# GetRequiredPermissions via  Microsoft Graph
# $GroupReadWriteAll = $msgraph.Oauth2Permissions | select Id, AdminConsentDisplayName, Value | Where-object {$_.Value -match 'Group.ReadWrite.All'} : run to see this permission
# $SiteFullControllAll = $msgraph.Oauth2Permissions | select Id, AdminConsentDisplayName, Value | Where-object {$_.Value -match 'Sites.FullControl.All'}: run to see this permission

Function GetRequiredPermissions([string] $applicationDisplayName, [string] $requiredDelegatedPermissions, [string]$requiredApplicationPermissions, $servicePrincipal)
{
    # If we are passed the service principal we use it directly, otherwise we find it from the display name (which might not be unique)
    if ($servicePrincipal)
    {
        $sp = $servicePrincipal
    }
    else
    {
        $sp = Get-AzureADServicePrincipal -Filter "DisplayName eq '$applicationDisplayName'"
    }
    $appid = $sp.AppId
    $requiredAccess = New-Object Microsoft.Open.AzureAD.Model.RequiredResourceAccess
    $requiredAccess.ResourceAppId = $appid 
    $requiredAccess.ResourceAccess = New-Object System.Collections.Generic.List[Microsoft.Open.AzureAD.Model.ResourceAccess]


    if ($requiredApplicationPermissions)
    {
        AddResourcePermission $requiredAccess -exposedPermissions $sp.AppRoles -requiredAccesses $requiredApplicationPermissions -permissionType "Role"
    }
    return $requiredAccess
}





<# This function Creates ADAL application with app-only permission, it add correct permissions
        --> Groups.ReadWrite.All (Microsoft Graph)
        --> Sites.FullControl.All (Office 365 SharePoint Online)
#>
Function CreateADALApplications
{

     # Login to Azure PowerShell (interactive if credentials are not already provided:
    # you'll need to sign-in with creds enabling your to create apps in the tenant)
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
    
    # Get the user running the script
    $user = Get-AzureADUser -ObjectId $creds.Account.Id

   
    #Generate password
    Function GeneratePassword {
        $aesManaged = New-Object "System.Security.Cryptography.AesManaged"
        $aesManaged.Mode = [System.Security.Cryptography.CipherMode]::CBC
        $aesManaged.Padding = [System.Security.Cryptography.PaddingMode]::Zeros
        $aesManaged.BlockSize = 128
        $aesManaged.KeySize = 256
        $aesManaged.GenerateKey()
        return [System.Convert]::ToBase64String($aesManaged.Key)
    }
    
    #Generate key
    Function GenerateKey ($fromDate, $durationInYears, $pw) {
        $endDate = $fromDate.AddYears($durationInYears) 
        $keyId = (New-Guid).ToString();
        $key = New-Object Microsoft.Open.AzureAD.Model.PasswordCredential($null, $endDate, $keyId, $fromDate, $pw)
        return $key
    }
        
    #Create key
    Function CreateKey($fromDate, $durationInYears, $pw) {
        
        $testKey = GenerateKey -fromDate $fromDate -durationInYears $durationInYears -pw $pw
        
        while ($testKey.Value -match "\+" -or $testKey.Value -match "/") {
            Write-Host "Secret contains + or / and may not authenticate correctly. Regenerating..." -ForegroundColor Yellow
            $pw = GeneratePassword
            $testKey = GenerateKey -fromDate $fromDate -durationInYears $durationInYears -pw $pw
        }
        Write-Host "Secret doesn't contain + or /. Continuing..." -ForegroundColor Green
        $key = $testKey
        
        return $key
    }
    


  # Get an application key
  $pw = GeneratePassword
  $fromDate = [System.DateTime]::Now
  $appKey = CreateKey -fromDate $fromDate -durationInYears 2299 -pw $pw

   # Create the client AAD application
   Write-Host "Creating the AAD application (AutomationEngine)"
   $clientAadApplication = New-AzureADApplication -DisplayName "AutomationEngine" `
                                                  -HomePage "https://localhost:44321/" `
                                                  -ReplyUrls "https://$tenantName/AutomationEngine/oauth2/callback" `
                                                  -IdentifierUris "https://$tenantName/AutomationEngine" `
                                                  -PublicClient $False `
                                                  -PasswordCredentials $appKey
                                                  #-KeyCredentials $clientKeyCredentials

                                                               
                                               
   # Generate a certificate
   Write-Host "Creating the client appplication (AutomationEngine)"
   $certificate=New-SelfSignedCertificate  -Subject CN=AutomationEngineWithCert `
                                           -CertStoreLocation "Cert:\CurrentUser\My" `
                                           -KeyExportPolicy Exportable `
                                           -KeySpec Signature
                                           
   $certKeyId = [Guid]::NewGuid()
   $certBase64Value = [System.Convert]::ToBase64String($certificate.GetRawCertData())
   $certBase64Thumbprint = [System.Convert]::ToBase64String($certificate.GetCertHash())

   #$certBase64Thumbprint = [System.Convert]::ToBase64String($certificate.GetCertHash())

   $now = [System.DateTime]::Now
   $EnDAte = $now.AddYears(5)
 
   Write-Host "End Date with Get staff $EnDAte"
       
   $password = ConvertTo-SecureString -String "123" -AsPlainText -Force
   $thumbp = (($certificate).Thumbprint)
   $cert = Get-Item -Path Microsoft.PowerShell.Security\Certificate::CurrentUser\My\$thumbp

   # Add Certificate thumbprint to ADAL minifest

   Export-PfxCertificate -Password $password -Cert $cert -FilePath "C:\Users\abdahmed\Desktop\MyCert.pfx" -Verbose
   $Global:mycert = $certificate
   $currentAppId = $clientAadApplication.AppId
   $clientServicePrincipal = New-AzureADServicePrincipal -AppId $currentAppId -Tags {WindowsAzureActiveDirectoryIntegratedApp}


  # Generating Credentials
   $clientKeyCredentials = New-AzureADApplicationKeyCredential -ObjectId $clientAadApplication.ObjectId `
                                                                -CustomKeyIdentifier $certBase64Thumbprint `
                                                                -Type AsymmetricX509Cert `
                                                                -Usage Verify `
                                                                -Value $certBase64Value `
                                                                -StartDate $certificate.NotBefore `
                                                                -EndDate $EnDAte.NotAfter


                                                                

   # add the user running the script as an app owner/
   Add-AzureADApplicationOwner -ObjectId $clientAadApplication.ObjectId -RefObjectId $user.ObjectId
   Write-Host "'$($user.UserPrincipalName)' added as an application owner to app '$($clientServicePrincipal.DisplayName)'"

   Write-Host "Done creating the client application (AutomationEngine)"



   $requiredResourcesAccess = New-Object System.Collections.Generic.List[Microsoft.Open.AzureAD.Model.RequiredResourceAccess]

   # Add Required Resources Access Groups.ReadWrite.All (Microsoft Graph)  Sites.FullControl.All (Office 365 SharePoint Online)

   Write-Host "Getting correct permissions"
   $requiredGraphPermissions = GetRequiredPermissions -applicationDisplayName "Microsoft Graph" `
                                                 -requiredApplicationPermissions "Group.ReadWrite.All";


   $requiredSPPermissions = GetRequiredPermissions -applicationDisplayName "Office 365 SharePoint Online" `
                                                 -requiredApplicationPermissions "Sites.FullControl.All";
   $requiredResourcesAccess.Add($requiredSPPermissions)
   $requiredResourcesAccess.Add($requiredGraphPermissions)

   # Grant  
   Set-AzureADApplication -ObjectId $clientAadApplication.ObjectId -RequiredResourceAccess $requiredResourcesAccess
   Write-Host "Granted permissions."
  
}


# Run interactively (will ask you for the tenant ID)
CreateADALApplications -Credential $Credential -tenantId $TenantId

#$userNameDemo = 'userNameDemo'
# $passDemo = ConvertTo-SecureString -String 'passowrd' -AsPlainText -Force
# $DemoCre = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $userNameDemo,$passDemo

# Go the file path.. and run  .\#1.ps1

