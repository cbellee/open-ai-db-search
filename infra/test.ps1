$readOnlyRoleDefinitionId = "00000000-0000-0000-0000-000000000002" # as fetched above
$principalId="6178da65-05ec-4edb-a9b6-1b05c3d0fd37"
# $principalId="a6b0fb66-4vvvv52"
$ResourceGroupName="open-ai-search-rg"
$accountName="ggxp4x2dg3jdy-cosmosdb"
 
# check if the role is present
$roleAssignment = Get-AzCosmosDBSqlRoleAssignment -AccountName $accountName -ResourceGroupName $resourceGroupName | Where-Object { $_.PrincipalId -eq $principalId -and $_.RoleDefinitionId -match $readOnlyRoleDefinitionId }
if (!$roleAssignment) {
    Write-Output "Assigning role to the service principal"
    New-AzCosmosDBSqlRoleAssignment -AccountName $accountName -ResourceGroupName $resourceGroupName -RoleDefinitionId $readOnlyRoleDefinitionId -Scope "/" -PrincipalId $principalId  
}