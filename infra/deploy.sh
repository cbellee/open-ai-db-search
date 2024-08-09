location='eastasia'
resourceGroupName='open-ai-search-app-aue-rg'
subscription=$(az account show --query id --output tsv)
entraIdUsername=$(az ad signed-in-user show --query userPrincipalName -o tsv)
entraIdObjectId=$(az ad signed-in-user show --query id -o tsv)
publisherName=$(echo $entraIdUsername | cut -d "@" -f 1)
sqlAdminLogin='sqldbadmin'
repoUrl='https://github.com/cbellee/open-ai-db-search'
repoBranch='main'
version=v0.0.2

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
ACR_NAME=$(az deployment group show --resource-group $resourceGroupName --name acr-deployment --query properties.outputs.acrName.value --output tsv)
IMAGE_NAME=$ACR_NAME.azurecr.io/ai-search-api:$version

cd ../ai-search-backend
az acr login -n $ACR_NAME
docker build -t $IMAGE_NAME .
docker push $IMAGE_NAME

# deploy resources
az deployment group create \
    --name 'main-deployment' \
    --resource-group $resourceGroupName \
    --template-file ./main.bicep \
    --parameters location=$location \
    --parameters publisherEmail=$entraIdUsername \
    --parameters publisherName=$publisherName \
    --parameters entraIdObjectId=$entraIdObjectId \
    --parameters sqlAdminLogin=$sqlAdminLogin \
    --parameters repoUrl=$repoUrl \
    --parameters repoBranch=$repoBranch \
    --parameters gitHubToken=$GITHUB_TOKEN \
    --parameters isPrivate='true' \
    --parameters acrName=$ACR_NAME \
    --parameters imageName=$IMAGE_NAME \
    --parameters aiSearchEndpoint=$AI_SEARCH_ENDPOINT \
    --parameters aiSearchKey=$AI_SEARCH_KEY \
    --parameters aiSearchIndex=$AI_SEARCH_INDEX \
    --parameters openAiConnection=$OPEN_AI_CXN

# get deployment output
SQL_SERVER_NAME=$(az deployment group show --resource-group $resourceGroupName --name main-deployment --query properties.outputs.sqlServerName.value --output tsv)
SQL_DB_NAME=$(az deployment group show --resource-group $resourceGroupName --name main-deployment --query properties.outputs.sqlDbName.value --output tsv)
CONTAINER_APP_FQDN=$(az deployment group show --resource-group $resourceGroupName --name main-deployment --query properties.outputs.containerAppFqdn.value --output tsv)
CONTAINER_APP_UMID_NAME=$(az deployment group show --resource-group $resourceGroupName --name main-deployment --query properties.outputs.containerAppUmidName.value --output tsv)

sed "s/<UMID_NAME>/$CONTAINER_APP_UMID_NAME/g" ./database-permissions.sql.template > ./database-permissions.sql
sqlcmd --server=$SQL_SERVER_NAME.database.windows.net -d=$SQL_DB_NAME --input-file=./database-permissions.sql --authentication-method=activeDirectoryDefault

curl https://${CONTAINER_APP_FQDN}/products
curl https://${CONTAINER_APP_FQDN}/swagger
curl https://${CONTAINER_APP_FQDN}/swagger/v1/swagger.json > openapi.json

:'
# scaffold react app

npm create vite@latest app -- --template react -y
cd ./app
npm install
npm run dev
'
