location='australiaeast'
resourceGroupName='open-ai-search-rg'
subscription=$(az account show --query id --output tsv)
entraIdUsername=$(az ad signed-in-user show --query userPrincipalName -o tsv)
entraIdObjectId=$(az ad signed-in-user show --query id -o tsv)
publisherName=$(echo $entraIdUsername | cut -d "@" -f 1)
version=v0.0.20
aiSearchIndexName='contoso-product-index'
semanticConfigName='product-semantic-config'
embeddingClientName='text-embedding-ada-002'
embeddingDeploymentName='text-embedding-ada-002'
partitionKey='/Id'
clientIpAddress=$(curl ifconfig.me)
isPrivate=false

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
spaJobImageName=$acrName.azurecr.io/ai-search-spa-job:$version

az acr login -n $acrName

# build & push api image
cd ../src/api/ProductSearchAPI
az acr build --platform=linux/amd64 -r $acrName -t $imageName .

# re-tag & upload to dockerHub
docker pull $imageName
docker tag $imageName belstarr/ai-search-api:$version
docker push belstarr/ai-search-api:$version

# build & push job image
cd ../../../data
az acr build --platform=linux/amd64 -r $acrName -t $jobImageName .

# re-tag & upload to dockerHub
docker pull $jobImageName
docker tag $jobImageName belstarr/ai-search-python-job:$version
docker push belstarr/ai-search-python-job:$version

# build & push spa job image
cd ../src/spa
az acr build --platform=linux/amd64 -r $acrName -t $spaJobImageName .

# re-tag & upload to dockerHub
docker pull $spaJobImageName
docker tag $spaJobImageName belstarr/ai-search-spa-job:$version
docker push belstarr/ai-search-spa-job:$version

cd ../../infra

# deploy resources
az deployment group create \
    --name 'main-deployment' \
    --resource-group $resourceGroupName \
    --template-file ./main.bicep \
    --parameters location=$location \
    --parameters isPrivate=$isPrivate \
    --parameters acrName=$acrName \
    --parameters imageName=$imageName \
    --parameters aiSearchIndex=$aiSearchIndexName \
    --parameters semanticConfigName=$semanticConfigName \
    --parameters embeddingClientName=$embeddingClientName \
    --parameters partitionKey=$partitionKey \
    --parameters systemPromptFileName='system_prompt.txt' \
    --parameters chatGptDeploymentName='gpt-4o' \
    --parameters storageContainerName='product-images' \
    --parameters jobImageName=$jobImageName \
    --parameters clientIpAddress=$clientIpAddress \
    --parameters openAiEmbeddingDeploymentName=$embeddingDeploymentName \
    --parameters containerSpaJobImageName=$spaJobImageName

# get deployment output
backendFqdn=$(az deployment group show --resource-group $resourceGroupName --name main-deployment --query properties.outputs.containerAppFqdn.value --output tsv)
swaName=$(az deployment group show --resource-group $resourceGroupName --name main-deployment --query properties.outputs.swaName.value --output tsv)
storageContainerUrl=$(az deployment group show --resource-group $resourceGroupName --name main-deployment --query properties.outputs.storageContainerUrl.value --output tsv)

# update backend uri for React frontend
echo "VITE_API_URI=https://$backendFqdn/products" >> ../src/spa/.env
echo "VITE_STORAGE_ACCOUNT_URL=$storageContainerUrl" >> ../src/spa/.env

# build & deploy front end to SWA
cd ../src/spa

deploymentToken=$(az staticwebapp secrets list --name $swaName --query "properties.apiKey" -o tsv)

# install node, nvm & npm 
# curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
# nvm install 20
# node -v
# npm -v

# build to ./dist
swa build --output-location . --app-build-command "npm run build"

# deploy app
swa deploy ./dist \
    --app-location . \
    -d $deploymentToken \
    --resource-group $resourceGroupNameb\
    --app-name $swaName

cd ..