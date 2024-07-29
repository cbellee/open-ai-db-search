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
    --parameters sqlAdminPassword=$SQL_ADMIN_PASSWORD \
    --parameters repoUrl=$repoUrl \
    --parameters repoBranch=$repoBranch \
    --parameters gitHubToken=$GITHUB_TOKEN \
    --parameters entraIdUsername=$entraIdUsername

# get deployment output
SQL_SERVER_NAME=$(az deployment group show --resource-group $resourceGroupName --name main-deployment --query properties.outputs.sqlServerName.value --output tsv)
SQL_DB_NAME=$(az deployment group show --resource-group $resourceGroupName --name main-deployment --query properties.outputs.sqlDbName.value --output tsv)
FUNC_UMID_NAME=$(az deployment group show --resource-group $resourceGroupName --name main-deployment --query properties.outputs.funcUmidName.value --output tsv)

sed "s/<UMID_NAME>/$FUNC_UMID_NAME/g" ./database-permissions.sql.template > ./database-permissions.sql
sqlcmd --server=$SQL_SERVER_NAME.database.windows.net -d=$SQL_DB_NAME --input-file=./database-permissions.sql --authentication-method=activeDirectoryDefault

dotnet clean ../api/api.csproj --runtime linux-x64
dotnet restore ../api/api.csproj --runtime linux-x64
dotnet publish ../api/api.csproj -c Release --framework net8.0 --no-restore --runtime linux-x64 --no-self-contained -o ../publish

cd ../publish
zip -r ../publish.zip .
cd ../iac

az functionapp deployment source config-zip \
    --resource-group $resourceGroupName \
    --name $FUNC_APP_NAME \
    --src ./func.zip

:'
npm create vite@latest app -- --template react -y
cd ./app
npm install
npm run dev
'
