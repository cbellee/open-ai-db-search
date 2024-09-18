from azure.cosmos import CosmosClient, exceptions, PartitionKey
from azure.identity import DefaultAzureCredential
import os, json, sys
import pandas as pd
from typing import List, Dict

if __name__ == "__main__":
    print("Running 'AzureSearch/uploadDatatoCosmosDB.py'...")

    COSMOS_ENDPOINT = os.environ["COSMOS_ENDPOINT"]
    DATABASE_NAME = os.environ["COSMOS_DATABASE"]
    print(f"DATABASE_NAME: {DATABASE_NAME}")
    print(f"COSMOS_ENDPOINT: {COSMOS_ENDPOINT}")
    print(f"AZURE_CLIENT_ID: {os.environ["AZURE_CLIENT_ID"]}")

    # create default credential
    default_credential = DefaultAzureCredential()
    print("Inserting products into CosmosDB database...")

# read the config file
with open(f"{os.getcwd()}/AzureSearch/config/config.json") as file:
    config = json.load(file)

CONTAINER_NAME = config["cosmos-config"]["cosmos_db_container_name"]
COSMOS_DB_PARTITION_KEY = config["cosmos-config"]["cosmos_db_partition_key"]

# authentication using Default Credential
client = CosmosClient(url=COSMOS_ENDPOINT, credential=default_credential)

try:
    print(f"Getting Database: {DATABASE_NAME}")
    db = client.get_database_client(DATABASE_NAME)
except exceptions.CosmosHttpResponseError as error:
    print(f"Exception getting database. {error}")
    sys.exit(1)

try:
    print(f"Getting container client.")
    container = db.get_container_client(CONTAINER_NAME)
except exceptions.CosmosHttpResponseError as error:
    print(f"Error creating container: {error}")
    sys.exit(1)

# read the products.csv file from (AzureSearch\data\products.csv), remove spaces and new lines from the column values
# convert the id column from int to string before uploading to Cosmos DB
products_df = pd.read_csv(f"{os.getcwd()}/AzureSearch/Data/products.csv")
products_df["id"] = products_df["id"].astype(str)
products_df = products_df.apply(lambda x: x.str.strip() if x.dtype == "object" else x)
products_dict = products_df.to_dict(orient="records")

# get the schema and data types of the products_dict
for product in products_dict:
    try:
        print(f"Inserting product ID: {product['id']} to Cosmos DB")
        container.upsert_item(body=product)
        print(f"Product {product['id']} uploaded to Cosmos DB")
    except exceptions.CosmosHttpResponseError as error:
        print(f"Exception inserting product {product['id']} into database. {error}")
        sys.exit(1)
