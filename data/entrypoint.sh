#! /bin/sh

echo "Running Python scripts..."
python3 -v AzureSearch/combinedScript.py
echo "Scripts completed..."

# python3 AzureSearch/uploadDatatoCosmosDB.py && python3 AzureSearch/createAzureSearchIndex.py
