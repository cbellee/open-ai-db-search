location='eastasia'
resourceGroupName='open-ai-search-app-ea-rg'
subscription=$(az account show --query id --output tsv)
entraIdUsername=$(az ad signed-in-user show --query userPrincipalName -o tsv)
entraIdObjectId=$(az ad signed-in-user show --query id -o tsv)
publisherName=$(echo $entraIdUsername | cut -d "@" -f 1)
sqlAdminLogin='sqldbadmin'
repoUrl='https://github.com/cbellee/open-ai-db-search'
repoBranch='main'

source ../.env

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
    --parameters sqlAdminLogin=$sqlAdminLogin \
    --parameters repoUrl=$repoUrl \
    --parameters repoBranch=$repoBranch \
    --parameters gitHubToken=$GITHUB_TOKEN \
    --parameters isPrivate='true'

# get deployment output
SQL_SERVER_NAME=$(az deployment group show --resource-group $resourceGroupName --name main-deployment --query properties.outputs.sqlServerName.value --output tsv)
SQL_DB_NAME=$(az deployment group show --resource-group $resourceGroupName --name main-deployment --query properties.outputs.sqlDbName.value --output tsv)
FUNC_UMID_NAME=$(az deployment group show --resource-group $resourceGroupName --name main-deployment --query properties.outputs.funcUmidName.value --output tsv)
FUNC_NAME=$(az deployment group show --resource-group $resourceGroupName --name main-deployment --query properties.outputs.funcName.value --output tsv)

sed "s/<UMID_NAME>/$FUNC_UMID_NAME/g" ./database-permissions.sql.template > ./database-permissions.sql
# sqlcmd --server=$SQL_SERVER_NAME.database.windows.net -d=$SQL_DB_NAME --input-file=./database-permissions.sql --authentication-method=activeDirectoryDefault

dotnet clean ../func/func.csproj --runtime linux-x64
dotnet restore ../func/func.csproj --runtime linux-x64
dotnet publish ../func/func.csproj -c Release --framework net8.0 --no-restore --runtime linux-x64 -o ../func/publish

cd ../func/publish
zip -r ../publish.zip .
cd ../../infra

az functionapp deployment source config-zip \
    --resource-group $resourceGroupName \
    --name $FUNC_NAME \
    --src ../func/publish.zip

 curl https://${FUNC_NAME}.azurewebsites.net/api/getproducts/Red | jq

:'
# scaffold react app

npm create vite@latest app -- --template react -y
cd ./app
npm install
npm run dev
'
