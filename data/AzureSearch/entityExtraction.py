# this is sample code

from dotenv import load_dotenv
from azure.identity import ClientSecretCredential
from azure.search.documents import SearchClient
from azure.search.documents.indexes import SearchIndexClient
from azure.search.documents.models import VectorizedQuery
from azure.search.documents import SearchClient
from azure.search.documents.models import VectorizableTextQuery
from openai import AzureOpenAI
from msal import ConfidentialClientApplication
import logging
import os

def get_sp_access_token(client_id, client_secret, tenant_id, scopes):
    logging.info('Attempting to obtain an access token...')
    result = None
    print(tenant_id)
    app = ConfidentialClientApplication(
        client_id=client_id,
        client_credential=client_secret,
        authority=f"https://login.microsoftonline.com/{tenant_id}",
    )
    result = app.acquire_token_for_client(scopes=scopes)

    if "access_token" in result:
        logging.info('Access token successfully acquired')
        return result['access_token']
    else:
        # logging.error('Unable to obtain access token')
        # logging.error(f"Error was: {result['error']}")
        # logging.error(f"Error description was: {result['error_description']}")
        # logging.error(f"Error correlation_id was: {result['correlation_id']}")
        raise Exception('Failed to obtain access token')
    

load_dotenv()

question = "Give me the tent related products"
# Question = "what is the top 3 highest price product in the category of 'hiking'?"

service_endpoint = os.environ["AZURE_SEARCH_SERVICE_ENDPOINT"]
tenant_id = os.environ["TENANT_ID"]
client_id = os.environ["CLIENT_ID"]
client_secret = os.environ["CLIENT_SECRET"]
azure_openai_endpoint = os.environ["AZURE_OPENAI_ENDPOINT"]

credential = ClientSecretCredential(tenant_id, client_id, client_secret)

with open("config/config.json") as file:
    config = json.load(file)
search_index_name = config["ai-search-config"]["search-index-config"]["name"]


# Pure Vector Search
search_client = SearchClient(endpoint=service_endpoint, index_name=search_index_name, credential=credential)
vector_query = VectorizableTextQuery(text=question, k_nearest_neighbors=3, fields="description_vectorized")
  
# results = search_client.search(  
#     search_text=None,  
#     vector_queries= [vector_query],
#     select=["price", "name", "brand", "category", "description"],
# )  

# print (" Question: ", question)  
# for result in results:  
#     print("Product: ", result["name"])
#     print("Price: ", result["price"])
#     print("Brand: ", result["brand"])
#     print("Category: ", result["category"])
#     print("Description: ", result["description"])



# OpenAI
token = get_sp_access_token(client_id, client_secret, tenant_id,  scopes=["https://cognitiveservices.azure.com/.default"])

openai_client = AzureOpenAI(
    azure_ad_token=token,
    api_version="2024-02-01",
    
        )
completion = openai_client.chat.completions.create(
    model="gpt35",
    messages= [
    {
      "role": "user",
      "content": question
    }],
    max_tokens=800,
    temperature=0.7,
    top_p=0.95,
    frequency_penalty=0,
    presence_penalty=0,
    stop=None,
    stream=False

)
print(completion.choices[0].message.content)

