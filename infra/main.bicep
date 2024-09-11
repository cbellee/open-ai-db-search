param location string = 'australiaeast'
param swaLocation string = 'eastasia'
param publisherEmail string
param publisherName string
param addressPrefix string = '10.100.0.0/16'
param isPrivate bool = true
param imageName string
param acrName string
param embeddingClientName string
param partitionKey string = '/Id'
param aiSearchIndex string
param semanticConfigName string
param model string
param systemPromptFileName string
param storageContainerName string
param gpt4Key string
param jobImageName string
param clientIpAddress string
param tags object = {
  environment: 'dev'
}

var cosmosDataContributorRoleDefinitionId = '00000000-0000-0000-0000-000000000002'
var prefix = uniqueString(resourceGroup().id)
var cosmosDbDatabaseName = 'catalogDb'
var cosmosDbContainerName = 'products'
var apimPip = '${prefix}-apim-ip'
var swaUmidName = '${prefix}-swa-umid'
var containerAppUmidName = '${prefix}-container-app-umid'
var containerAppName = '${prefix}-container-app'
var aiSearchUmidName = '${prefix}-ai-search-umid'
var apimName = '${prefix}-apim'
var apimUmidName = '${prefix}-apim-umid'
var containerAppEnvironmentName = '${prefix}-container-app-env'
var apimNsgName = '${prefix}-apim-nsg'
var cosmosDbPrivateEndpointName = '${prefix}-cosmosdb-pe'
var lawName = '${prefix}-law'
var aiName = '${prefix}-ai'
var openAiName = '${prefix}-openai'
var swaName = '${prefix}-swa'
var storageAccountName = '${prefix}stor'
var containerJobName = '${prefix}-container-job'

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
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/7f951dda-4ed3-4680-a7ca-43fe172d538d'
    principalType: 'ServicePrincipal'
  }
}

// Allows running container jobs
resource containerJobContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, containerAppUserManagedIdentity.id, 'containerJobContributorRole')
  scope: pythonContainer
  properties: {
    principalId: containerAppUserManagedIdentity.properties.principalId
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/4e3d2b60-56ae-4dc6-a233-09c8e5a82e68'
    principalType: 'ServicePrincipal'
  }
}

// Allows managing CosmosDb
resource cosmosDbOperatorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(cosmosDbAccount.id, containerAppUserManagedIdentity.id, 'cosmosDbOperatorRole')
  scope: cosmosDbAccount
  properties: {
    principalId: containerAppUserManagedIdentity.properties.principalId
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/230815da-be43-4aae-9cb4-875f7bd000aa'
    principalType: 'ServicePrincipal'
  }
}

// Allows managing CosmosDb
resource cosmosDbAccountReaderRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(cosmosDbAccount.id, containerAppUserManagedIdentity.id, 'cosmosDbAccountReaderRole')
  scope: cosmosDbAccount
  properties: {
    principalId: aiSearchUserManagedIdentity.properties.principalId
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/fbdf93bf-df7d-467e-a4d2-9458aa1360c8'
    principalType: 'ServicePrincipal'
  }
}

resource apimNsg 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: apimNsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Allow_Apim_Gateway'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: 'VirtualNetwork'
        }
      }
      {
        name: 'Allow_Apim_Mgmt'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3443'
          sourceAddressPrefix: 'ApiManagement'
          destinationAddressPrefix: 'VirtualNetwork'
        }
      }
      {
        name: 'Allow_Azure_Load_Balancer'
        properties: {
          priority: 120
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '6390'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: 'VirtualNetwork'
        }
      }
      {
        name: 'Dependency_on_Azure_SQL'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '1433'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Sql'
          access: 'Allow'
          priority: 130
          direction: 'Outbound'
        }
      }
      {
        name: 'Dependency_on_Azure_Storage'
        properties: {
          description: 'API Management service dependency on Azure blob and Azure table storage'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Storage'
          access: 'Allow'
          priority: 140
          direction: 'Outbound'
        }
      }
    ]
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
          networkSecurityGroup: {
            id: apimNsg.id
          }
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

resource pythonContainer 'Microsoft.App/jobs@2024-03-01' = {
  name: containerJobName
  location: location
  identity: {
    type: 'UserAssigned'
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
      secrets: [
        {
          name: 'cosmosdbcxnstring'
          value: 'ResourceId=/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.DocumentDB/databaseAccounts/${cosmosDbAccount.name};Database=${database.name};IdentityAuthType=AccessToken'
        }
      ]
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
              name: 'AZURE_TENANT_ID'
              value: tenant().tenantId
            }
            {
              name: 'AZURE_CLIENT_ID'
              value: containerAppUserManagedIdentity.properties.clientId
            }
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
              secretRef: 'cosmosdbcxnstring'
            }
            {
              name: 'OPEN_AI_ENDPOINT'
              value: openAi.properties.endpoint
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
      secrets: [
        {
          name: 'endpoint'
          value: 'https://${aiSearch.name}.search.windows.net'
        }
        {
          name: 'key'
          value: aiSearch.listQueryKeys().value[0].key
        }
        {
          name: 'indexname'
          value: aiSearchIndex
        }
        {
          name: 'semanticconfigname'
          value: semanticConfigName
        }
        {
          name: 'openaiconnection'
          value: 'Endpoint=${openAi.properties.endpoint};Key=${listKeys(openAi.id, openAi.apiVersion).key1}'
        }
        {
          name: 'aikey'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'clientid'
          value: containerAppUserManagedIdentity.properties.clientId
        }
        {
          name: 'embeddingclient'
          value: embeddingClientName
        }
        {
          name: 'model'
          value: model
        }
        {
          name: 'gpt4key'
          value: gpt4Key
        }
        {
          name: 'systempromptfilename'
          value: systemPromptFileName
        }
        {
          name: 'storageaccounturl'
          value: '${storage.properties.primaryEndpoints.blob}${storageContainerName}/'
        }
      ]
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
              name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
              secretRef: 'aikey'
            }
            {
              name: 'AZURE_CLIENT_ID'
              secretRef: 'clientid'
            }
            {
              name: 'SearchClient__endpoint'
              secretRef: 'endpoint'
            }
            {
              name: 'SearchClient__credential__key'
              secretRef: 'key'
            }
            {
              name: 'SearchClient__indexName'
              secretRef: 'indexname'
            }
            {
              name: 'ConnectionStrings__OpenAI'
              secretRef: 'openaiconnection'
            }
            {
              name: 'semanticConfigName'
              secretRef: 'semanticconfigname'
            }
            {
              name: 'vectorFieldName'
              value: 'Description_V'
            }
            {
              name: 'nearestNeighbours'
              value: '3'
            }
            {
              name: 'OpenAI__embeddingClientName'
              secretRef: 'embeddingclient'
            }
            {
              name: 'OpenAI__model'
              secretRef: 'model'
            }
            {
              name: 'OpenAI__gpt4Key'
              secretRef: 'gpt4key'
            }
            {
              name: 'OpenAI__systemPromptFileName'
              secretRef: 'systempromptfilename'
            }
            {
              name: 'OpenAI__storageAccountUrl'
              secretRef: 'storageaccounturl'
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

/* resource openAi 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' = {
  name: openAiName
  location: location
  sku: {
    name: 'S0'
  }
  kind: 'OpenAI'
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}
 */

resource openAi 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' existing = {
  name: openAiName
}

resource apimPublicIpAddress 'Microsoft.Network/publicIPAddresses@2024-01-01' = {
  name: apimPip
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: 'apim${prefix}'
    }
  }
}

resource apim 'Microsoft.ApiManagement/service@2023-09-01-preview' = {
  name: apimName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${apimUserManagedIdentity.id}': {}
    }
  }
  sku: {
    name: 'Standardv2'
    capacity: 1
  }
  properties: {
    customProperties: {
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_128_GCM_SHA256': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_256_CBC_SHA256': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_128_CBC_SHA256': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_256_CBC_SHA': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_128_CBC_SHA': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TripleDes168': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls10': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls11': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Ssl30': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls10': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls11': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Ssl30': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Protocols.Server.Http2': 'false'
    }
    publisherEmail: publisherEmail
    publisherName: publisherName
    publicIpAddressId: apimPublicIpAddress.id
    publicNetworkAccess: 'Enabled'
    virtualNetworkType: 'External'
    virtualNetworkConfiguration: {
      subnetResourceId: vnet.properties.subnets[0].id
    }
  }
}

resource api 'Microsoft.ApiManagement/service/apis@2023-09-01-preview' = {
  parent: apim
  name: 'api'
  properties: {
    path: '/search-api'
    apiType: 'http'
    displayName: 'search-api'
    type: 'http'
    subscriptionRequired: false
    protocols: [
      'https'
    ]
    serviceUrl: 'https://${backendContainerApp.properties.configuration.ingress.fqdn}'
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
    //repositoryUrl: repoUrl //'https://github.com/cbellee/open-ai-db-search'
    //branch: repoBranch
    stagingEnvironmentPolicy: 'Enabled'
    allowConfigFileUpdates: true
    provider: 'Other'
    enterpriseGradeCdnStatus: 'Disabled'
    //repositoryToken: gitHubToken
    //buildProperties: {
    //  outputLocation: '/dist'
    //  appLocation: '/spa'
    //apiLocation: '/api'
    //}
  }
}

/* resource swa_auth 'Microsoft.Web/staticSites/basicAuth@2023-12-01' = {
  parent: swa
  name: 'default'
  properties: {
    applicableEnvironmentsMode: 'SpecifiedEnvironments'
  }
}

resource swa_backend 'Microsoft.Web/staticSites/linkedBackends@2023-12-01' = {
  parent: swa
  name: 'api-backend'
  properties: {
    backendResourceId: apim.id
    region: location
  }
}
 */

resource aiSearch 'Microsoft.Search/searchServices@2024-06-01-preview' = {
  name: '${prefix}-search'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${containerAppUserManagedIdentity.id}': {}
    }
  }
  sku: {
    name: 'standard'
  }
  tags: tags
  properties: {
    disableLocalAuth: true
    semanticSearch: 'standard'
    networkRuleSet: {
      bypass: 'AzureServices'
    }
  }
}

// Allows managing AI Search Services
resource aiSearchServiceContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiSearch.id, containerAppUserManagedIdentity.id, 'aiSearchServiceContributor')
  scope: aiSearch
  properties: {
    principalId: containerAppUserManagedIdentity.properties.principalId
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/7ca78c08-252a-4471-8644-bb5ff32d4ba0'
    principalType: 'ServicePrincipal'
  }
}

// Allows managing AI Search Services
resource aiSearchServiceDataContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiSearch.id, containerAppUserManagedIdentity.id, 'aiSearchServiceDataContributor')
  scope: aiSearch
  properties: {
    principalId: containerAppUserManagedIdentity.properties.principalId
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/8ebe5a00-799e-43f5-93ac-243d3dce84a7'
    principalType: 'ServicePrincipal'
  }
}

// Allows managing OpenAI Services
resource cognitiveServicesOpenAIContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiSearch.id, containerAppUserManagedIdentity.id, 'cognitiveServicesOpenAIContributorRole')
  scope: aiSearch
  properties: {
    principalId: containerAppUserManagedIdentity.properties.principalId
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/a001fd3d-188f-4b5d-821b-7da978bf7442'
    principalType: 'ServicePrincipal'
  }
}

// Allows managing AI Search Services
resource openAiDeveloperRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiSearch.id, containerAppUserManagedIdentity.id, 'openAiDeveloperRole')
  scope: openAi
  properties: {
    principalId: aiSearchUserManagedIdentity.properties.principalId
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/64702f94-c441-49e6-a78b-ef80e0188fee'
    principalType: 'ServicePrincipal'
  }
}

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' = {
  name: '${prefix}-cosmosdb'
  location: location
  tags: tags
  properties: {
    ipRules: [
      {
        ipAddressOrRange: clientIpAddress
      }
    ]
    networkAclBypass: 'AzureServices'
    databaseAccountOfferType: 'Standard'
    locations: [
      {
        locationName: location
        isZoneRedundant: false
      }
    ]
    publicNetworkAccess: 'Enabled'
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

resource sqlRoleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2023-04-15' = {
  name: guid(
    cosmosDataContributorRoleDefinitionId,
    containerAppUserManagedIdentity.id,
    cosmosDbAccount.id,
    'sqlDbDataContributorRoleAssignment'
  )
  parent: cosmosDbAccount
  properties: {
    principalId: containerAppUserManagedIdentity.properties.principalId
    roleDefinitionId: '/${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.DocumentDB/databaseAccounts/${cosmosDbAccount.name}/sqlRoleDefinitions/${cosmosDataContributorRoleDefinitionId}'
    scope: cosmosDbAccount.id
  }
}

resource aiSearchSqlRoleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2023-04-15' = {
  name: guid(
    cosmosDataContributorRoleDefinitionId,
    containerAppUserManagedIdentity.id,
    cosmosDbAccount.id,
    'aiSearchSqlRoleAssignment'
  )
  parent: cosmosDbAccount
  properties: {
    principalId: aiSearchUserManagedIdentity.properties.principalId
    roleDefinitionId: '/${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.DocumentDB/databaseAccounts/${cosmosDbAccount.name}/sqlRoleDefinitions/${cosmosDataContributorRoleDefinitionId}'
    scope: cosmosDbAccount.id
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
output apimName string = apim.name
output containerAppName string = backendContainerApp.name
output containerAppFqdn string = backendContainerApp.properties.configuration.ingress.fqdn
output storageAccountName string = storage.name
output storageAccountUrl string = storage.properties.primaryEndpoints.blob
output storageContainerUrl string = '${storage.properties.primaryEndpoints.blob}${storageContainerName}/'
