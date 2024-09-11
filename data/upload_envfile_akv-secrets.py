# this is sample code

import os 
import json
from azure.identity import DefaultAzureCredential

if __name__ == "__main__":

    default_credential = DefaultAzureCredential()

    with open('.env', 'r') as file:
        lines = file.readlines()
        for line in lines:
            try:
                key, value = line.split('=')
                # remove the spaces
                key = key.strip()
                value = value.strip()
                # replace "_" with "-" for the key
                key = key.replace("_", "-")
                #remove " from the value 
                value = value.replace('"', '')
                secret = secret_client.set_secret(key, value)
            except Exception as e:
                print(e)
                print(f"Error in setting the secret {key} in the key vault")

    