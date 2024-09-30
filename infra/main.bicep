param location string = 'australiaeast'
param swaLocation string = 'eastasia'
param addressPrefix string = '10.100.0.0/16'
param isPrivate bool = false
param imageName string
param acrName string
param embeddingClientName string
param partitionKey string = '/Id'
param aiSearchIndex string
param semanticConfigName string
param chatGptDeploymentName string
param systemPromptFileName string
param storageContainerName string
param jobImageName string
param openAiEmbeddingDeploymentName string
param containerSpaJobImageName string
param clientIpAddress string
@allowed([
  'standard'
  'standard2'
  'standard3'
  'standard3highcpu'
  'standard3highmemory'
  'free'
  'basic'
])
param aiSearchSku string = 'standard2'
//param fields string
param openAiCustomSubDomainName string = 'cbellee-open-ai'
param tags object = {
  environment: 'dev'
}

var cosmosDataContributorRoleDefinitionId = '00000000-0000-0000-0000-000000000002'
var cosmosDbAccountReaderRoleDefinitionId = 'fbdf93bf-df7d-467e-a4d2-9458aa1360c8'
var cosmosDbAccountOperatorRoleDefinitionId = '230815da-be43-4aae-9cb4-875f7bd000aa'
var aiSearchServiceAccountContributorRoleDefinitionId = '7ca78c08-252a-4471-8644-bb5ff32d4ba0'
var aiSearchServiceDataContributorRoleDefinitionId = '8ebe5a00-799e-43f5-93ac-243d3dce84a7'
var azureAiDeveloperRoleDefinitionId = '64702f94-c441-49e6-a78b-ef80e0188fee'
var containerJobContributorRoleDefinitionId = '4e3d2b60-56ae-4dc6-a233-09c8e5a82e68'
var cognitiveServiceOpenAiContributorRoleDefinitionId = 'a001fd3d-188f-4b5d-821b-7da978bf7442'
var acrPullRoleDefinitionId = '7f951dda-4ed3-4680-a7ca-43fe172d538d'
var storageDataContributorDefinitionId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
var storageContributorDefinitionId = '17d1049b-9a84-46fb-8f53-869881c3d3ab'
var aiSearchServiceName = '${prefix}-search-s2'

var prefix = uniqueString(resourceGroup().id)
var cosmosDbDatabaseName = 'catalogDb'
var cosmosDbContainerName = 'products'
var swaUmidName = '${prefix}-swa-umid'
var containerAppUmidName = '${prefix}-container-app-umid'
var containerAppName = '${prefix}-container-app'
var aiSearchUmidName = '${prefix}-ai-search-umid'
var apimUmidName = '${prefix}-apim-umid'
var containerAppEnvironmentName = '${prefix}-container-app-env'
var cosmosDbPrivateEndpointName = '${prefix}-cosmosdb-pe'
var lawName = '${prefix}-law'
var aiName = '${prefix}-ai'
var openAiName = '${prefix}-openai'
var swaName = '${prefix}-swa'
var storageAccountName = '${prefix}stor'
var containerJobName = '${prefix}-container-job'
var containerSpaJobName = '${prefix}-spa-job'

resource apimUserManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: apimUmidName
  location: location
}

resource swaUserManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: swaUmidName
  location: location
}

resource containerAppUserManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: containerAppUmidName
  location: location
}

resource aiSearchUserManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: aiSearchUmidName
  location: location
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' existing = {
  name: acrName
}

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: true
    publicNetworkAccess: 'Enabled'
    supportsHttpsTrafficOnly: true
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  name: 'default'
  parent: storage
}

resource storageContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  name: storageContainerName
  parent: blobService
  properties: {
    publicAccess: 'Blob'
  }
}

resource acrPullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, containerAppUserManagedIdentity.id, 'AcrPullRole')
  scope: acr
  properties: {
    principalId: containerAppUserManagedIdentity.properties.principalId
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${acrPullRoleDefinitionId}'
    principalType: 'ServicePrincipal'
  }
}

// Allows running container jobs
resource appUmidContainerJobContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(pythonContainer.id, containerAppUserManagedIdentity.id, 'appUmidContainerJobContributorRole')
  scope: pythonContainer
  properties: {
    principalId: containerAppUserManagedIdentity.properties.principalId
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${containerJobContributorRoleDefinitionId}'
    principalType: 'ServicePrincipal'
  }
}

resource appUmidContainerSpaJobContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(spaContainer.id, containerAppUserManagedIdentity.id, 'appUmidContainerSpaJobContributorRole')
  scope: spaContainer
  properties: {
    principalId: containerAppUserManagedIdentity.properties.principalId
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${containerJobContributorRoleDefinitionId}'
    principalType: 'ServicePrincipal'
  }
}

resource appUmidContainerSpaJobStorageDataContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(spaContainer.id, containerAppUserManagedIdentity.id, 'appUmidContainerSpaJobStorageDataContributorRole')
  scope: storage
  properties: {
    principalId: containerAppUserManagedIdentity.properties.principalId
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${storageDataContributorDefinitionId}'
    principalType: 'ServicePrincipal'
  }
}

resource appUmidContainerSpaJobStorageContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(spaContainer.id, containerAppUserManagedIdentity.id, 'appUmidContainerSpaJobStorageContributorRole')
  scope: storage
  properties: {
    principalId: containerAppUserManagedIdentity.properties.principalId
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${storageContributorDefinitionId}'
    principalType: 'ServicePrincipal'
  }
}

// Allows managing CosmosDb
resource appUmidCosmosDbAccountReaderRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(cosmosDbAccount.id, containerAppUserManagedIdentity.id, 'appUmidCosmosDbAccountReaderRole')
  scope: cosmosDbAccount
  properties: {
    principalId: containerAppUserManagedIdentity.properties.principalId
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${cosmosDbAccountReaderRoleDefinitionId}'
    principalType: 'ServicePrincipal'
  }
}

// Allows managing CosmosDb
resource appMidCosmosDbAccountReaderRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(cosmosDbAccount.id, containerAppUserManagedIdentity.id, 'appMidCosmosDbAccountReaderRole')
  scope: cosmosDbAccount
  properties: {
    principalId: pythonContainer.identity.principalId
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${cosmosDbAccountReaderRoleDefinitionId}'
    principalType: 'ServicePrincipal'
  }
}

resource appUmidCosmosDbAccountOperatorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(cosmosDbAccount.id, containerAppUserManagedIdentity.id, 'appUmidCosmosDbAccountOperatorRole')
  scope: cosmosDbAccount
  properties: {
    principalId: containerAppUserManagedIdentity.properties.principalId
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${cosmosDbAccountOperatorRoleDefinitionId}'
    principalType: 'ServicePrincipal'
  }
}

// Allows managing CosmosDb
/* resource aiSearchUmidCosmosDbAccountOperatorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(cosmosDbAccount.id, 'aiSearchUmidCosmosDbAccountOperatorRole')
  scope: cosmosDbAccount
  properties: {
    principalId: aiSearchUserManagedIdentity.properties.principalId
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${cosmosDbAccountOperatorRoleDefinitionId}'
    principalType: 'ServicePrincipal'
  }
}  */

// Allows managing CosmosDb
resource aiSearchMidCosmosDbOperatorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(cosmosDbAccount.id, 'aiSearchMidCosmosDbAccountOperatorRole')
  scope: cosmosDbAccount
  properties: {
    principalId: aiSearch.identity.principalId
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${cosmosDbAccountOperatorRoleDefinitionId}'
    principalType: 'ServicePrincipal'
  }
}

// Allows managing CosmosDb
resource aiSearchMidCosmosDbAccountReaderRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(cosmosDbAccount.id, 'aiSearchMidCosmosDbAccountReaderRole')
  scope: cosmosDbAccount
  properties: {
    principalId: aiSearch.identity.principalId
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${cosmosDbAccountReaderRoleDefinitionId}'
    principalType: 'ServicePrincipal'
  }
}

// Allows managing AI Search Services
resource appMidAiSearchServiceAccountContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiSearch.id, containerAppUserManagedIdentity.id, 'appMidAiSearchServiceAccountContributorRole')
  scope: aiSearch
  properties: {
    principalId: pythonContainer.identity.principalId
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${aiSearchServiceAccountContributorRoleDefinitionId}'
    principalType: 'ServicePrincipal'
  }
}

resource appUmidAiSearchServiceAccountContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiSearch.id, containerAppUserManagedIdentity.id, 'appUmidAiSearchServiceAccountContributorRole')
  scope: aiSearch
  properties: {
    principalId: containerAppUserManagedIdentity.properties.principalId
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${aiSearchServiceAccountContributorRoleDefinitionId}'
    principalType: 'ServicePrincipal'
  }
}

// Allows managing AI Search Services Data
resource appUmidAiSearchServiceDataContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiSearch.id, containerAppUserManagedIdentity.id, 'appUmidAiSearchServiceDataContributorRole')
  scope: aiSearch
  properties: {
    principalId: containerAppUserManagedIdentity.properties.principalId
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${aiSearchServiceDataContributorRoleDefinitionId}'
    principalType: 'ServicePrincipal'
  }
}

// Allows managing AI Search Services
resource aiSearchUmidAzureAiDeveloperRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiSearch.id, 'aiSearchUmidAzureAiDeveloperRole')
  scope: openAi
  properties: {
    principalId: aiSearchUserManagedIdentity.properties.principalId
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${azureAiDeveloperRoleDefinitionId}'
    principalType: 'ServicePrincipal'
  }
}

resource containerAppUmidAzureAiDeveloperRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiSearch.id, 'containerAppUmidAzureAiDeveloperRole')
  scope: openAi
  properties: {
    principalId: containerAppUserManagedIdentity.properties.principalId
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${azureAiDeveloperRoleDefinitionId}'
    principalType: 'ServicePrincipal'
  }
}

resource containerAppUmidCognitiveServicesOpenAIContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiSearch.id, 'containerAppUmidCognitiveServicesOpenAIContributorRole')
  scope: aiSearch
  properties: {
    principalId: containerAppUserManagedIdentity.properties.principalId
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${cognitiveServiceOpenAiContributorRoleDefinitionId}'
    principalType: 'ServicePrincipal'
  }
}

// Allows managing OpenAI Services
resource aiSearchUmidCognitiveServicesOpenAIContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiSearch.id, 'aiSearchUmidCognitiveServicesOpenAIContributorRole2')
  scope: openAi
  properties: {
    principalId: aiSearchUserManagedIdentity.properties.principalId
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${cognitiveServiceOpenAiContributorRoleDefinitionId}'
    principalType: 'ServicePrincipal'
  }
}

// Allows managing OpenAI Services
resource aiSearchMidCognitiveServicesOpenAIContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiSearch.id, 'aiSearchMidCognitiveServicesOpenAIContributorRole')
  scope: aiSearch
  properties: {
    principalId: aiSearch.identity.principalId
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${cognitiveServiceOpenAiContributorRoleDefinitionId}'
    principalType: 'ServicePrincipal'
  }
}

resource aiSearchMidaiDeveloperRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiSearch.id, 'aiSearchMidaiDeveloperRole')
  scope: aiSearch
  properties: {
    principalId: aiSearch.identity.principalId
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${azureAiDeveloperRoleDefinitionId}'
    principalType: 'ServicePrincipal'
  }
}

// CosmosDB SQL role assignments

resource appUmidCosmoDbDataContributorRoleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2023-04-15' = {
  name: guid(
    cosmosDataContributorRoleDefinitionId,
    containerAppUserManagedIdentity.id,
    cosmosDbAccount.id,
    'appUmidCosmoDbDataContributorRoleAssignment'
  )
  parent: cosmosDbAccount
  properties: {
    principalId: containerAppUserManagedIdentity.properties.principalId
    roleDefinitionId: '/${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.DocumentDB/databaseAccounts/${cosmosDbAccount.name}/sqlRoleDefinitions/${cosmosDataContributorRoleDefinitionId}'
    scope: cosmosDbAccount.id
  }
}

resource aiSearchMidCosmoDbDataContributorRoleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2023-04-15' = {
  name: guid(
    cosmosDataContributorRoleDefinitionId,
    cosmosDbAccount.id,
    'aiSearchMidCosmoDbDataContributorRoleAssignment'
  )
  parent: cosmosDbAccount
  properties: {
    principalId: aiSearch.identity.principalId
    roleDefinitionId: '/${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.DocumentDB/databaseAccounts/${cosmosDbAccount.name}/sqlRoleDefinitions/${cosmosDataContributorRoleDefinitionId}'
    scope: cosmosDbAccount.id
  }
}

resource aiSearchUmidCosmoDbDataContributorRoleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2023-04-15' = {
  name: guid(
    cosmosDataContributorRoleDefinitionId,
    cosmosDbAccount.id,
    'aiSearchUmidCosmoDbDataContributorRoleAssignment'
  )
  parent: cosmosDbAccount
  properties: {
    principalId: aiSearchUserManagedIdentity.properties.principalId
    roleDefinitionId: '/${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.DocumentDB/databaseAccounts/${cosmosDbAccount.name}/sqlRoleDefinitions/${cosmosDataContributorRoleDefinitionId}'
    scope: cosmosDbAccount.id
  }
}

resource pythonJobhMidCosmoDbDataContributorRoleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2023-04-15' = {
  name: guid(
    cosmosDataContributorRoleDefinitionId,
    cosmosDbAccount.id,
    'pythonJobhMidCosmoDbDataContributorRoleAssignment'
  )
  parent: cosmosDbAccount
  properties: {
    principalId: pythonContainer.identity.principalId
    roleDefinitionId: '/${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.DocumentDB/databaseAccounts/${cosmosDbAccount.name}/sqlRoleDefinitions/${cosmosDataContributorRoleDefinitionId}'
    scope: cosmosDbAccount.id
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: '${prefix}-vnet'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: 'apimSubnet'
        properties: {
          addressPrefix: cidrSubnet(cidrSubnet(addressPrefix, 22, 0), 24, 0)
          /* networkSecurityGroup: {
            id: apimNsg.id
          } */
          delegations: [
            {
              name: 'apimDelegation'
              type: 'Microsoft.Web/serverFarns'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: 'privateEndpoontSubnet'
        properties: {
          addressPrefix: cidrSubnet(cidrSubnet(addressPrefix, 22, 0), 24, 1)
        }
      }
      {
        name: 'containerAppSubnet'
        properties: {
          addressPrefix: cidrSubnet(cidrSubnet(addressPrefix, 22, 1), 23, 0)
        }
      }
      {
        name: 'mgmt-subnet'
        properties: {
          addressPrefix: cidrSubnet(cidrSubnet(addressPrefix, 22, 0), 24, 2)
        }
      }
    ]
  }
}

resource law 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: lawName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: aiName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Redfield'
  }
}

resource containerAppEnv 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: containerAppEnvironmentName
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: law.properties.customerId
        sharedKey: listKeys(law.id, law.apiVersion).primarySharedKey
      }
    }
    vnetConfiguration: {
      internal: false
      infrastructureSubnetId: vnet.properties.subnets[2].id
    }
  }
}

resource spaContainer 'Microsoft.App/jobs@2024-03-01' = {
  name: containerSpaJobName
  location: location
  identity: {
    type: 'UserAssigned, systemAssigned'
    userAssignedIdentities: {
      '${containerAppUserManagedIdentity.id}': {}
    }
  }
  properties: {
    configuration: {
      manualTriggerConfig: {
        parallelism: 1
        replicaCompletionCount: 1
      }
      replicaRetryLimit: 1
      secrets: []
      replicaTimeout: 600
      triggerType: 'Manual'
      registries: [
        {
          identity: containerAppUserManagedIdentity.id
          server: acr.properties.loginServer
        }
      ]
    }
    environmentId: containerAppEnv.id
    template: {
      containers: [
        {
          name: 'spa-job'
          image: containerSpaJobImageName
          env: [
            {
              name: 'AZURE_SUBSCRIPTION_ID'
              value: subscription().subscriptionId
            }
            {
              name: 'AZURE_CLIENT_ID'
              value: containerAppUserManagedIdentity.properties.clientId
            }
            {
              name: 'STORAGE_ACCOUNT_NAME'
              value: storage.name
            }
            {
              name: 'API_URI'
              value: backendContainerApp.properties.configuration.ingress.fqdn
            }
            {
              name: 'STORAGE_ACCOUNT_URI'
              value: storage.properties.primaryEndpoints.blob
            }
            {
              name: 'CONTAINER_NAME'
              value: storageContainerName
            }
          ]
        }
      ]
    }
  }
}

resource runSpaJob 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'runSpaJob'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${containerAppUserManagedIdentity.id}': {}
    }
  }
  properties: {
    azCliVersion: '2.61.0'
    retentionInterval: 'PT1H'
    scriptContent: 'az containerapp job start --name ${spaContainer.name} --resource-group ${resourceGroup().name}'
  }
}

resource pythonContainer 'Microsoft.App/jobs@2024-03-01' = {
  name: containerJobName
  location: location
  identity: {
    type: 'UserAssigned, systemAssigned'
    userAssignedIdentities: {
      '${containerAppUserManagedIdentity.id}': {}
    }
  }
  properties: {
    configuration: {
      manualTriggerConfig: {
        parallelism: 1
        replicaCompletionCount: 1
      }
      replicaRetryLimit: 1
      secrets: []
      replicaTimeout: 300
      triggerType: 'Manual'
      registries: [
        {
          identity: containerAppUserManagedIdentity.id
          server: acr.properties.loginServer
        }
      ]
    }
    environmentId: containerAppEnv.id
    template: {
      containers: [
        {
          name: 'python-job'
          image: jobImageName
          env: [
            {
              name: 'AZURE_SEARCH_ENDPOINT'
              value: 'https://${aiSearch.name}.search.windows.net'
            }
            {
              name: 'COSMOS_ENDPOINT'
              value: cosmosDbAccount.properties.documentEndpoint
            }
            {
              name: 'COSMOS_DATABASE'
              value: database.name
            }
            {
              name: 'COSMOS_DB_CONNECTION_STRING'
              value: 'ResourceId=/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.DocumentDB/databaseAccounts/${cosmosDbAccount.name};Database=${database.name};IdentityAuthType=AccessToken'
            }
            {
              name: 'OPEN_AI_ENDPOINT'
              value: openAi.properties.endpoint
            }
            {
              name: 'USER_ASSIGNED_IDENTITY_RID'
              value: aiSearchUserManagedIdentity.id
            }
            {
              name: 'OPEN_AI_EMBEDDING_DEPLOYMENT_NAME'
              value: openAiEmbeddingDeploymentName
            }
          ]
        }
      ]
    }
  }
}

resource runPythonJob 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'runPythonJob'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${containerAppUserManagedIdentity.id}': {}
    }
  }
  properties: {
    azCliVersion: '2.61.0'
    retentionInterval: 'PT1H'
    scriptContent: 'az containerapp job start --name ${pythonContainer.name} --resource-group ${resourceGroup().name}'
  }
}

resource backendContainerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${containerAppUserManagedIdentity.id}': {}
    }
  }
  tags: tags
  properties: {
    configuration: {
      secrets: []
      registries: [
        {
          identity: containerAppUserManagedIdentity.id
          server: acr.properties.loginServer
        }
      ]
      activeRevisionsMode: 'Single'
      ingress: {
        corsPolicy: {
          allowedOrigins: [
            '*'
          ]
          allowCredentials: false
          allowedHeaders: [
            '*'
          ]
          allowedMethods: [
            'GET'
            'POST'
            'PUT'
            'DELETE'
            'OPTIONS'
          ]
        }
        targetPort: 8080
        external: true
        transport: 'auto'
      }
    }
    environmentId: containerAppEnv.id
    template: {
      containers: [
        {
          name: 'container'
          image: imageName
          resources: {
            cpu: '0.25'
            memory: '0.5Gi'
          }
          env: [
            {
              name: 'AZURE_CLIENT_ID'
              value: containerAppUserManagedIdentity.properties.clientId
            }
            {
              name: 'AppConfiguration__AISearchClient__endpoint'
              value: 'https://${aiSearch.name}.search.windows.net'
            }
            {
              name: 'AppConfiguration__AISearchClient__indexName'
              value: aiSearchIndex
            }
            {
              name: 'AppConfiguration__AISearchClient__fields'
              value: '["id", "name", "description", "price", "category"]'
            }
            {
              name: 'ConnectionStrings__OpenAI'
              value: openAi.properties.endpoint
            }
            {
              name: 'AppConfiguration__AISearchClient__semanticConfigName'
              value: semanticConfigName
            }
            {
              name: 'AppConfiguration__AISearchClient__vectorFieldNames'
              value: '["description_vectorized"]'
            }
            {
              name: 'AppConfiguration__AISearchClient__nearestNeighbours'
              value: '3'
            }
            {
              name: 'AppConfiguration__OpenAIClient__embeddingClientName'
              value: embeddingClientName
            }
            {
              name: 'AppConfiguration__OpenAIClient__chatGptDeploymentName'
              value: chatGptDeploymentName
            }
            {
              name: 'AppConfiguration__OpenAIClient__systemPromptFileName'
              value: systemPromptFileName
            }
            {
              name: 'AppConfiguration__OpenAIClient__storageAccountUrl'
              value: '${storage.properties.primaryEndpoints.blob}${storageContainerName}/'
            }
          ]
        }
      ]
      scale: {
        maxReplicas: 3
        minReplicas: 1
      }
    }
  }
  dependsOn: [
    acrPullRole
  ]
}

resource openAi 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' = {
  name: openAiName
  location: location
  sku: {
    name: 'S0'
  }
  kind: 'OpenAI'
  properties: {
    publicNetworkAccess: isPrivate ? 'Disabled' : 'Enabled'
    customSubDomainName: openAiCustomSubDomainName
    disableLocalAuth: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

resource swa 'Microsoft.Web/staticSites@2023-12-01' = {
  name: swaName
  location: swaLocation
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${swaUserManagedIdentity.id}': {}
    }
  }
  tags: {
    environment: 'dev'
  }
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  properties: {
    stagingEnvironmentPolicy: 'Enabled'
    allowConfigFileUpdates: true
    provider: 'Other'
    enterpriseGradeCdnStatus: 'Disabled'
  }
}

resource aiSearch 'Microsoft.Search/searchServices@2024-06-01-preview' = {
  name: aiSearchServiceName
  location: location
  identity: {
    type: 'UserAssigned, SystemAssigned'
    userAssignedIdentities: {
      '${aiSearchUserManagedIdentity.id}': {}
    }
  }
  sku: {
    name: aiSearchSku
  }
  tags: tags
  properties: {
    disableLocalAuth: true
    publicNetworkAccess: isPrivate ? 'Disabled' : 'Enabled'
    semanticSearch: 'standard'
    /* networkRuleSet: {
      bypass: 'AzureServices'
    } */
  }
}

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' = {
  name: '${prefix}-cosmosdb'
  location: location
  tags: tags
  properties: {
    networkAclBypass: 'None'
    databaseAccountOfferType: 'Standard'
    locations: [
      {
        locationName: location
        isZoneRedundant: false
      }
    ]
    publicNetworkAccess: isPrivate ? 'Disabled' : 'Enabled'
    capabilities: []
  }
}

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2022-05-15' = {
  parent: cosmosDbAccount
  name: cosmosDbDatabaseName
  properties: {
    resource: {
      id: cosmosDbDatabaseName
    }
  }
}

resource container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-05-15' = {
  parent: database
  name: cosmosDbContainerName
  properties: {
    resource: {
      id: cosmosDbContainerName
      partitionKey: {
        paths: [
          partitionKey
        ]
        kind: 'Hash'
      }
    }
  }
}

resource cosmosDbPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-01-01' = if (isPrivate) {
  name: cosmosDbPrivateEndpointName
  location: location
  tags: tags
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'Sql'
        properties: {
          privateLinkServiceId: cosmosDbAccount.id
          groupIds: [
            'Sql'
          ]
        }
      }
    ]
    subnet: {
      id: vnet.properties.subnets[1].id
    }
  }
}

resource cosmosDbPrivateLinkServiceGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-01-01' = if (isPrivate) {
  parent: cosmosDbPrivateEndpoint
  name: '${prefix}-cosmosdb-plsg'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'cosmosDb'
        properties: {
          privateDnsZoneId: cosmosDbPrivateDnsZone.id
        }
      }
    ]
  }
}

resource sqlServerPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (isPrivate) {
  name: 'privatelink.database.windows.net'
  location: 'global'
  tags: tags
}

resource cosmosDbPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (isPrivate) {
  name: 'privatelink.documents.azure.com'
  location: 'global'
  tags: tags
}

resource sqlServerPrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (isPrivate) {
  parent: sqlServerPrivateDnsZone
  name: '${prefix}-sqlserver-vnet-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource cosmosDbPrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (isPrivate) {
  parent: cosmosDbPrivateDnsZone
  name: '${prefix}-cosmosdb-vnet-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

output swaUmidName string = swaUserManagedIdentity.name
output swaName string = swa.name
output containerAppName string = backendContainerApp.name
output containerAppFqdn string = backendContainerApp.properties.configuration.ingress.fqdn
output storageAccountName string = storage.name
output storageAccountUrl string = storage.properties.primaryEndpoints.blob
output storageContainerUrl string = '${storage.properties.primaryEndpoints.blob}${storageContainerName}/'
