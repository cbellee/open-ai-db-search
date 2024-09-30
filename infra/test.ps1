$products = get-content -Path ./data/AzureSearch/Data/catalog.json | ConvertFrom-Json
$id = 0
$newProducts = @()

$products | ForEach-Object {
    $newProduct = @{
        "id" = [int]$_.Id
        "name" = $_.Name
        "description" = """$($_.Description)"""
        "brand" = $_.Brand
        "price" = $_.Price
        "category" = $_.Type
        "image" = $_.ImageName
    }
    $newProducts += $newProduct
}

$newProducts | Export-Csv -UseQuotes Never -Path ./data/AzureSearch/Data/catalog.csv 
