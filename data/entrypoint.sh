#!/bin/sh

# run the python script
echo "Running Python scripts..."
python3 AzureSearch/uploadDatatoCosmosDB.py && python3 AzureSearch/createAzureSearchIndex.py
