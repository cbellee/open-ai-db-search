using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using System.Text.Json;
using System.Net;
using Microsoft.Azure.Functions.Worker.Extensions.Sql;
using Microsoft.Azure.Functions.Worker.Http;

namespace Demo.Product
{
    public class GetProducts
    {
        private readonly ILogger<GetProducts> _logger;

        public GetProducts(ILogger<GetProducts> logger)
        {
            _logger = logger;
        }

        [Function("GetProducts")]
        public async Task<HttpResponseData> Run([HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "getproducts/{color}")]
        HttpRequestData req,
        [SqlInput(commandText: "select * from [SalesLT].[Product] where color = @Color",
            connectionStringSetting: "SQL_CXN_STRING",
            commandType: System.Data.CommandType.Text,
            parameters: "@Color={color}")]
        IAsyncEnumerable<Product> products)

        {
            IAsyncEnumerator<Product> enumerator = products.GetAsyncEnumerator();
            var productList = new List<Product>();
            while (await enumerator.MoveNextAsync())
            {
                productList.Add(enumerator.Current);
            }
            await enumerator.DisposeAsync();

            var json = JsonSerializer.Serialize(productList);
            _logger.LogInformation($"json: {json}");
  
            var response = req.CreateResponse(HttpStatusCode.OK);
            response.Headers.Add("Content-Type", "application/json");
            await response.WriteStringAsync(json);

            return response;
        }
    }
}

