location='australiaeast'
resourceGroupName='open-ai-search-rg'
subscription=$(az account show --query id --output tsv)
entraIdUsername=$(az ad signed-in-user show --query userPrincipalName -o tsv)
entraIdObjectId=$(az ad signed-in-user show --query id -o tsv)
publisherName=$(echo $entraIdUsername | cut -d "@" -f 1)
version=v0.0.9
aiSearchIndexName='products-index'
semanticConfigName='semantic-config'
embeddingClientName='text-embedding-ada-002'
partitionKey='/Id'

source ./.env

# create resource group
az group create --location $location --name $resourceGroupName

# deploy ACR
az deployment group create \
    --name 'acr-deployment' \
    --resource-group $resourceGroupName \
    --template-file ./acr.bicep \
    --parameters location=$location

# get deployment output
acrName=$(az deployment group show --resource-group $resourceGroupName --name acr-deployment --query properties.outputs.acrName.value --output tsv)
imageName=$acrName.azurecr.io/ai-search-api:$version
jobImageName=$acrName.azurecr.io/ai-search-python-job:$version

cd ../api/ProductSearchAPI
az acr login -n $acrName

docker build -t $imageName .
docker push $imageName

# docker build -t $jobImageName .
# docker push $jobImageName

cd ../../infra



# deploy resources
az deployment group create \
    --name 'main-deployment' \
    --resource-group $resourceGroupName \
    --template-file ./main.bicep \
    --parameters location=$location \
    --parameters publisherEmail=$entraIdUsername \
    --parameters publisherName=$publisherName \
    --parameters isPrivate='true' \
    --parameters acrName=$acrName \
    --parameters imageName=$imageName \
    --parameters aiSearchIndex=$aiSearchIndexName \
    --parameters semanticConfigName=$semanticConfigName \
    --parameters embeddingClientName=$embeddingClientName \
    --parameters partitionKey=$partitionKey \
    --parameters systemPromptFileName='query.txt' \
    --parameters model='gpt-4' \
    --parameters storageContainerName='product-images' \
    --parameters gpt4Key=$GPT4_KEY \
    --parameters jobImageName=$containerAppJobName

# get deployment output
backendFqdn=$(az deployment group show --resource-group $resourceGroupName --name main-deployment --query properties.outputs.containerAppFqdn.value --output tsv)
swaName=$(az deployment group show --resource-group $resourceGroupName --name main-deployment --query properties.outputs.swaName.value --output tsv)
storageContainerUrl=$(az deployment group show --resource-group $resourceGroupName --name main-deployment --query properties.outputs.storageContainerUrl.value --output tsv)

# update backend uri for React frontend
echo "VITE_API_URI=https://$backendFqdn/products" >> ../spa/.env
echo "VITE_STORAGE_ACCOUNT_URL=$storageContainerUrl" >> ../spa/.env

# build & deploy front end to SWA
cd ../spa

deploymentToken=$(az staticwebapp secrets list --name $swaName --query "properties.apiKey" -o tsv)

# build to ./dist
swa build --output-location . --app-build-command "npm run build"

# deploy app
swa deploy ./dist \
    --app-location . \
    -d $deploymentToken \
    --resource-group $resourceGroupNameb\
    --app-name $swaName

cd ..