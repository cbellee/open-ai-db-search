# check if the module is installed, if not instal it 
if (-not (Get-Module -Name Az.CosmosDB -ListAvailable)) {
    Install-Module -Name Az.CosmosDB -AllowClobber -Force
}
# read the .env file
$env = Get-Content -Path ".env" | ForEach-Object {
    $k, $v = $_ -split '=', 2
    # remove the double quotes
    $v = $v -replace '^"|"$'
    #remove spaces at the end of the line
    $v = $v.Trim()
    # remove spaces at the beginning of the line
    $k = $k.Trim() 
    [PSCustomObject]@{ Key = $k; Value = $v }
}

# login to azure using service principal
$tenantId = $env:TENANT_ID
$clientId = $env:CLIENT_ID
$clientSecret = $env:CLIENT_SECRET
$resourceGroupName=$env:RESOURCE_GROUP_NAME
$url = $env:COSMOS_ENDPOINT


# Use a regular expression to extract the subdomain
if ($url -match "https://(.*?)\.documents\.azure\.com") {
    $accountName = $matches[1]
    Write-Output $subdomain
} else {
    Write-Output "No match found"
}

#login to azure using service principal
$secPassword = ConvertTo-SecureString $clientSecret -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($clientId, $secPassword)
Connect-AzAccount -ServicePrincipal -Tenant $tenantId -Credential $cred

#getting the Object ID of the service principal
$principal = Get-AzADServicePrincipal -ApplicationId $clientId
$principalId = $principal.Id

# Grant cosmos db built in role for service principal

# $resourceGroupName = "<hardcoded-resource-group-name>"
# $accountName = "<hardcoded-cosmos-account-name>"

# https://learn.microsoft.com/en-us/azure/cosmos-db/how-to-setup-rbac#built-in-role-definitions
$readOnlyRoleDefinitionId = "00000000-0000-0000-0000-000000000001" # as fetched above


# check if the role is present
$roleAssignment = Get-AzCosmosDBSqlRoleAssignment -AccountName $accountName -ResourceGroupName $resourceGroupName | Where-Object { $_.PrincipalId -eq $principalId -and $_.RoleDefinitionId -match $readOnlyRoleDefinitionId }
if ($roleAssignment) {
    Write-Output "Role assignment already exists"    
}
else {
    New-AzCosmosDBSqlRoleAssignment -AccountName $accountName -ResourceGroupName $resourceGroupName -RoleDefinitionId $readOnlyRoleDefinitionId -Scope "/" -PrincipalId $principalId

}

# to-do

# 1. Provide the Search manage identity permission on Cosmos DB to fetch the data.
# 2. Provide search manage identity and SPN permission on Azure Open AI to call the embedding module ( Azure AI Developer role)
# 3. Provide the service principal access to the Azure Search service for quering (Search Index Data reader)




