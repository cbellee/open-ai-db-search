using System;
using System.Collections.Generic;
using Microsoft.Azure.Functions.Worker.Http;
using System.Threading.Tasks;
using Microsoft.Azure.Functions.Worker;
// using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.Azure.Functions.Worker.Extensions.Sql;

namespace api
{
    public static class GetProductsAsyncEnumerable
    {
        [Function("GetProductsAsyncEnumerable")]
        public static async Task<List<Product>> Run(
            [Microsoft.Azure.Functions.Worker.HttpTrigger(Microsoft.Azure.Functions.Worker.AuthorizationLevel.Anonymous, "get", Route = "getproducts/{color}")]
            HttpRequestData req,
            [SqlInput("select * from [SalesLT].[Product] where color = @Color",
                "SqlConnectionString",
                 parameters: "@Cost={color}")]
             IAsyncEnumerable<Product> products)
        {
            IAsyncEnumerator<Product> enumerator = products.GetAsyncEnumerator();
            var productList = new List<Product>();
            while (await enumerator.MoveNextAsync())
            {
                productList.Add(enumerator.Current);
            }
            await enumerator.DisposeAsync();
            //var jsonProductList = JsonSerializer.Serialize(productList, Context.Default.ListProduct);
            return productList;
        }
    }



    [JsonSerializable(typeof(List<Product>))]
    internal partial class Context : JsonSerializerContext
    {
    }

    public class Product
    {
        public int? ProductID { get; set; }
        public string Name { get; set; }
        public int? ProductNumber { get; set; }
        public string Color { get; set; }
        public decimal? StandardCost { get; set; }
        public decimal? ListPrice { get; set; }
        public string Size { get; set; }
        public decimal? Weight { get; set; }
        public int? ProductCategory { get; set; }
        public int? ProductModelID { get; set; }
        public DateTime? SellStartDate { get; set; }
        public DateTime? SellEndDate { get; set; }
        public DateTime? DiscontinuedDate { get; set; }
        public byte[] ThumbNailPhoto { get; set; }
        public string ThumbnailPhotoFileName { get; set; }
        public Guid rowguid { get; set; }
        public DateTime? ModifiedDate { get; set; }
    }
}