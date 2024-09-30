docker run -it \
    -e 'AZURE_TENANT_ID'='b9dcb86c-3d9f-4bc5-aba3-1de6cc56f6dc' \
    -e 'AZURE_CLIENT_ID'='' \
    -e 'AZURE_SEARCH_ENDPOINT'='https://ggxp4x2dg3jdy-search-s2.search.windows.net' \
    -e 'COSMOS_ENDPOINT'='https://ggxp4x2dg3jdy-cosmosdb.documents.azure.com:443/' \
    -e 'COSMOS_DATABASE'='catalogDb' \
    -e 'COSMOS_DB_CONNECTION_STRING'='ResourceId=/subscriptions/1452f655-bdd3-4cad-a635-fd5f7af5b012/resourceGroups/open-ai-search-rg/providers/Microsoft.DocumentDB/databaseAccounts/ggxp4x2dg3jdy-cosmosdb;Database=catalogDb;IdentityAuthType=AccessToken' \
    -e 'OPEN_AI_ENDPOINT'='https://ggxp4x2dg3jdy-openai.openai.azure.com' \
    -e 'USER_ASSIGNED_IDENTITY_RID'='/subscriptions/1452f655-bdd3-4cad-a635-fd5f7af5b012/resourceGroups/open-ai-search-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/ggxp4x2dg3jdy-ai-search-umid' \
    ggxp4x2dg3jdyacr.azurecr.io/ai-search-python-job:v0.0.13

export AZURE_TENANT_ID='b9dcb86c-3d9f-4bc5-aba3-1de6cc56f6dc'
export AZURE_CLIENT_ID=''
export AZURE_SEARCH_ENDPOINT='https://ggxp4x2dg3jdy-search-s2.search.windows.net'
export COSMOS_ENDPOINT='https://ggxp4x2dg3jdy-cosmosdb.documents.azure.com:443/'
export COSMOS_DATABASE='catalogDb'
export COSMOS_DB_CONNECTION_STRING='ResourceId=/subscriptions/1452f655-bdd3-4cad-a635-fd5f7af5b012/resourceGroups/open-ai-search-rg/providers/Microsoft.DocumentDB/databaseAccounts/ggxp4x2dg3jdy-cosmosdb;Database=catalogDb;IdentityAuthType=AccessToken'
export OPEN_AI_ENDPOINT='https://cbellee-open-ai.openai.azure.com/'
export USER_ASSIGNED_IDENTITY_RID='/subscriptions/1452f655-bdd3-4cad-a635-fd5f7af5b012/resourceGroups/open-ai-search-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/ggxp4x2dg3jdy-ai-search-umid'
#export OPEN_AI_ENDPOINT='https://ggxp4x2dg3jdy-openai.openai.azure.com'
          