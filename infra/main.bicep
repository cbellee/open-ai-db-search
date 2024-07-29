param location string = 'eastus'
param publisherEmail string
param publisherName string
param entraIdObjectId string
param addressPrefix string = '10.100.0.0/16'
param repoUrl string = ''
param sqlAdminLogin string

param tags object = {
  environment: 'dev'
}

var prefix = uniqueString(resourceGroup().id)
var storageName = 'stor${prefix}'
var staticWebAppName = '${prefix}-static-web-app'
var apimPip = '${prefix}-apim-ip'
var umidName = '${prefix}-umid'
var planName = '${prefix}-plan'
var apimName = '${prefix}-apim'
var funcName = '${prefix}-func'
var sqlServerName = '${prefix}-sql-server'
var storagePrivateEndpointName = '${prefix}-storage-pe'
var sqlPrivateEndpointName = '${prefix}-sql-pe'
var apimNsgName = '${prefix}-apim-nsg'
var cosmosDbPrivateEndpointName = '${prefix}-cosmosdb-pe'
var sampleSqlDatabaseName = 'sqldb-adventureworks'

resource userManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: umidName
  location: location
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
      {
        name: 'Deny_All_Internet_Outbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Internet'
          access: 'Deny'
          priority: 1000
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
          addressPrefix: cidrSubnet(addressPrefix, 24, 0)
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
        name: 'funcSubnet'
        properties: {
          addressPrefix: cidrSubnet(addressPrefix, 24, 1)
          delegations: [
            {
              name: 'funcDelegation'
              type: 'Microsoft.Web/serverFarns'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: 'dataSubnet'
        properties: {
          addressPrefix: cidrSubnet(addressPrefix, 24, 2)
        }
      }
      {
        name: 'storageSubnet'
        properties: {
          addressPrefix: cidrSubnet(addressPrefix, 24, 3)
        }
      }
      {
        name: 'privateEndpoontSubnet'
        properties: {
          addressPrefix: cidrSubnet(addressPrefix, 24, 4)
        }
      }
    ]
  }
}

resource plan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: planName
  location: location
  kind: 'linux,function'
  sku: {
    name: 'EP1'
  }
  tags: tags
  properties: {
    reserved: true
  }
}

resource func 'Microsoft.Web/sites@2023-12-01' = {
  name: funcName
  location: location
  tags: tags
  kind: 'functionapp'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userManagedIdentity.id}': {}
    }
  }
  properties: {
    serverFarmId: plan.id
    siteConfig: {
      appSettings: [
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
      ]
    }
  }
}

resource funcVnetIntegration 'Microsoft.Web/sites/networkConfig@2023-12-01' = {
  parent: func
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: vnet.properties.subnets[1].id
    swiftSupported: true
  }
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
      domainNameLabel: apimName
    }
  }
}

resource apim 'Microsoft.ApiManagement/service@2023-09-01-preview' = {
  name: apimName
  location: location
  tags: tags
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
    path: '/api'
    apiType: 'http'
    displayName: 'api'
    type: 'http'
    subscriptionRequired: false
    protocols: [
      'https'
    ]
    serviceUrl: 'https://${func.properties.defaultHostName}'
  }
}

resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: sqlServerName
  location: location
  tags: tags
  properties: {
    publicNetworkAccess: 'Disabled'
    administrators: {
      login: sqlAdminLogin
      administratorType: 'ActiveDirectory'
      azureADOnlyAuthentication: true
      sid: entraIdObjectId
      principalType: 'User'
      tenantId: tenant().tenantId
    }
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2021-11-01' = {
  name: sampleSqlDatabaseName
  parent: sqlServer
  location: location

  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
  tags: {
    displayName: sampleSqlDatabaseName
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 104857600
    sampleName: 'AdventureWorksLT'
  }
}

resource sqlPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: sqlPrivateEndpointName
  location: location
  tags: tags
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'sqlServer'
        properties: {
          privateLinkServiceId: sqlServer.id
          groupIds: [
            'sqlServer'
          ]
        }
      }
    ]
    subnet: {
      id: vnet.properties.subnets[4].id
    }
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource storageDefault 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storage
  name: 'default'
}

resource storageContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: storageDefault
  name: 'test'
  properties: {
    publicAccess: 'None'
  }
}

resource storagePrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: storagePrivateEndpointName
  location: location
  tags: tags
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'blob'
        properties: {
          privateLinkServiceId: storage.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
    subnet: {
      id: vnet.properties.subnets[4].id
    }
  }
}

/* resource staticWebApp 'Microsoft.Web/staticSites@2023-12-01' = {
  name: staticWebAppName
  location: location
  tags: tags
  properties: {
    repositoryUrl: repoUrl
    branch: 'main'
    buildProperties: {}
    publicNetworkAccess: 'Enabled'
  }
} */

resource aiSearch 'Microsoft.Search/searchServices@2024-06-01-preview' = {
  name: '${prefix}-search'
  location: location
  sku: {
    name: 'standard'
  }
  tags: tags
  properties: {
    semanticSearch: 'standard'
    networkRuleSet: {
      bypass: 'AzureServices'
    }
  }
}

resource cosmosDb 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' = {
  name: '${prefix}-cosmosdb'
  location: location
  tags: tags
  properties: {
    databaseAccountOfferType: 'Standard'
    locations: [
      {
        locationName: location
        isZoneRedundant: false
      }
    ]
    publicNetworkAccess: 'Disabled'
    capabilities: []
  }
}

resource cosmosDbPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: cosmosDbPrivateEndpointName
  location: location
  tags: tags
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'Sql'
        properties: {
          privateLinkServiceId: cosmosDb.id
          groupIds: [
            'Sql'
          ]
        }
      }
    ]
    subnet: {
      id: vnet.properties.subnets[4].id
    }
  }
}

resource storagePrivateLinkServiceGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-01-01' = {
  parent: storagePrivateEndpoint
  name: '${prefix}-storage-plsg'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'blob'
        properties: {
          privateDnsZoneId: storagePrivateDnsZone.id
        }
      }
    ]
  }
}

resource sqlPrivateLinkServiceGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-01-01' = {
  parent: sqlPrivateEndpoint
  name: '${prefix}-sqlserver-plsg'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'sqlServer'
        properties: {
          privateDnsZoneId: sqlServerPrivateDnsZone.id
        }
      }
    ]
  }
}

resource cosmosDbPrivateLinkServiceGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-01-01' = {
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

resource storagePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.core.windows.net'
  location: 'global'
  tags: tags
}

resource sqlServerPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.database.windows.net'
  location: 'global'
  tags: tags
}

resource cosmosDbPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.documents.azure.com'
  location: 'global'
  tags: tags
}

resource storagePrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: storagePrivateDnsZone
  location: 'global'
  name: '${prefix}-storage-vnet-link'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource sqlServerPrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
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

resource cosmosDbPrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
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
