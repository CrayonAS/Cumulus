

# Create ADAL application and test connection
# Connect to Azure AD as an admin account
Connect-AzureAD
 
# Create Azure Active Directory Application (ADAL App)
$application = New-AzureADApplication -DisplayName "AzureADPosh" -IdentifierUris "https://techmikael.com/AzureADPosh"
New-AzureADApplicationKeyCredential -ObjectId $application.ObjectId -CustomKeyIdentifier "AzureADPosh" -Type AsymmetricX509Cert -Usage Verify -Value $keyValue -StartDate $currentDate -EndDate $endDate
 
# Create the Service Principal and connect it to the Application
$sp=New-AzureADServicePrincipal -AppId $application.AppId 
 
# Give the application read/write permissions to AAD
Add-AzureADDirectoryRoleMember -ObjectId (Get-AzureADDirectoryRole | where-object {$_.DisplayName -eq "Directory Writers"}).Objectid -RefObjectId $sp.ObjectId
 
# Test to login using the app
$tenant = Get-AzureADTenantDetail
$appId = $application.AppId
Connect-AzureAD -TenantId $tenant.ObjectId -ApplicationId  $Application.AppId -CertificateThumbprint $thumb


 # ***********      #1     ***********************

# 1.  Create ADAL application with app-only permissions


        # Connect to Azure AD with Admin Account.

        Connect-AzureAD

        $displayName = Read-Host -Prompt "Enter Application display name"
        $homePageUri = Read-Host -Prompt "Home page url - the URL where users can sign in and use your app. You can change this later."
       
        #Create Application

        $Application = New-AzureADApplication -DisplayName $displayName  -IdentifierUris $homePageUri  
        # The application Created will return ....

        # ObjectId                             AppId                                DisplayName
        # --------                             -----                                -----------
        # 57d634d3-f79d-4fd4-b8fa-25aadf2382c5 fcaac6ac-5bb2-4153-8877-a33679de4e91 AutoPShell

        # Get AppID
        $AppObjID = $Application.ObjectId
        
# 3. Create key which never expire  ( Make the End Date "31/12/2299" This will give you the 281: If you creating keys which never expires in Azure will do the same)
        
                # Create AppKeys
                $AppKey = New-AzureADApplicationKeyCredential -ObjectId $AppObjID -CustomKeyIdentifier "Test" -StartDate "25/9/2018" -EndtDate "31/12/2299"  -Type "Symmetric" 
                # The following will returned
                #CustomKeyIdentifier : {84, 101, 115, 116}
                #EndDate             : 31.12.2299 00:00:00
                #KeyId               : db200527-1ceb-4029-b0ee-9e69bc2ca53c
                #StartDate           : 25.09.2018 00:00:00
                #Type                : Symmetric
                #Usage               : Sign
                #Value               : {36, 69, 97, 13...}
                # Get AppKey
                $Appkey.KeyId

# 2. Add correct permissions
        ## Groups.ReadWrite.All (Microsoft Graph)
        ## Sites.FullControl.All (Office 365 SharePoint Online)




# 4. Create keyvault to store appid/appsecret 

        # connect AzureRMAcount to create Resource Group
         Connect-AzureRmAccount 

# 5. Store appid/appsecret in Azure Key Vault
# 6. Create certificate to be used with SharePoint CSOM app-only from ADAL app
# 7. Add certificate thumbprint to ADAL manifest
# 8. Grant admin permission on ADAL app
