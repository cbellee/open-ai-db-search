param location string
param tags object = {
  environment: 'dev'
}

var prefix = uniqueString(resourceGroup().id)
var acrName = '${prefix}acr'

resource acr 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
}

output acrName string = acrName
