location='australiaeast'
resourceGroupName='open-ai-search-app-rg'
subscription=$(az account show --query id --output tsv)
entraIdUsername=$(az ad signed-in-user show --query userPrincipalName -o tsv)
entraIdObjectId=$(az ad signed-in-user show --query id -o tsv)
publisherName=$(echo $entraIdUsername | cut -d "@" -f 1)

source ./.env

# create resource group
az group create --location $location --name $resourceGroupName

# deploy resources
az deployment group create \
    --name 'main-deployment' \
    --resource-group $resourceGroupName \
    --template-file ./main.bicep \
    --parameters location=$location \
    --parameters publisherEmail=$entraIdUsername \
    --parameters publisherName=$publisherName \
    --parameters entraIdObjectId=$entraIdObjectId \
    --parameters sqlAdminLogin=$sqlAdminLogin

# get deployment output
outputs=$(az deployment group show \
    --name 'main-deployment' \
    --resource-group $resourceGroupName \
    --query 'properties.outputs' \
    --output json)

npm create vite@latest app -- --template react -y
cd ./app
npm install
npm run dev