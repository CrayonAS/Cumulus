#
# Script.ps1
#

$adminSiteUrl = "https://inmetademo-admin.sharepoint.com"

#sitedesign/site script variables
$siteScriptFile = $PSScriptRoot + "\cumulus-teamsitescript.json"
$webTemplate = "64"
$isDefault = $false # or $true
$siteScriptTitle = "Cumulus Team Site Script"
$siteScriptDescription = "Cumulus team site script which adds a SPFx extension and triggers an Azure Logic App that monitors custom actions on the site."
$siteDesignTitle = "Cumulus Team Site Design"
$siteDesignDescription = "Cumulus team site design which adds a SPFx extension and triggers an Azure Logic App that monitors custom actions on the site."

#url pointing to trigger in azure logic app
$logicAppUrl = "https://prod-38.westeurope.logic.azure.com:443/workflows/35ce5d9b3c4f4a869380cc6463454a9e/triggers/manual/paths/invoke?api-version=2016-06-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=jXbWCkMRwkog0JjRBiFejvDr34632dKa2oyaiyRsJvg"
# solution id
$solutionId = "99461716-b1b0-48b6-b17c-dcd1e1095768"
#extension clientSideComponentId
$extensionGuid = "424EA575-A160-4142-8A9C-8D52972FA508"

$cred = Get-Credential
Connect-SPOService $adminSiteUrl -Credential $cred

#Update the url to point to azure logic app url
$a = Get-Content $siteScriptFile | ConvertFrom-Json
$a.actions | % {if($_.verb -eq 'triggerFlow'){$_.url=$logicAppUrl}}
$a.actions | % {if($_.verb -eq 'associateExtension'){$_.clientSideComponentId=$extensionGuid}}
$a.actions | % {if($_.verb -eq 'installSolution'){$_.id=$solutionId}}
$a | ConvertTo-Json -Depth 20| set-content $siteScriptFile

#add site script and site design
$siteScript = (Get-Content $siteScriptFile -Raw | Add-SPOSiteScript -Title $siteScriptTitle -Description $siteScriptDescription ) | Select -First 1 Id
Add-SPOSiteDesign -SiteScripts $siteScript.Id -Title $siteDesignTitle -WebTemplate $webTemplate -Description $siteDesignDescription -IsDefault:$isDefault