using Azure.Search.Documents;
using Azure.Search.Documents.Indexes;
using Azure.Search.Documents.Models;
using Azure.Search.Documents.Indexes.Models;
using Azure;
using Azure.AI.OpenAI;
using OpenAI.Embeddings;

namespace ai_search_backend
{
    public interface IProductSearchService
    {
        Task<List<Product>> SearchProducts(string queryText);
        Task<SearchServiceStatistics> GetSearchServiceStatistics();
        Task<long> GetDocumentIndexCount();
    }

    public class ProductSearchService : IProductSearchService
    {
        private readonly ILogger<ProductSearchService> _logger;
        private readonly SearchClient _searchClient;
        private readonly SearchIndexClient _searchIndexClient;
        private readonly AzureOpenAIClient _openAIClient;

        public ProductSearchService(ILogger<ProductSearchService> logger, SearchClient searchClient, SearchIndexClient searchIndexClient, AzureOpenAIClient openAIClient)
        {
            _logger = logger;
            _searchClient = searchClient;
            _searchIndexClient = searchIndexClient;
            _openAIClient = openAIClient;
        }

        public ReadOnlyMemory<float> GetEmbeddings(string input)
        {
            EmbeddingClient embeddingClient = _openAIClient.GetEmbeddingClient("text-embedding-ada-002");
            Embedding embedding = embeddingClient.GenerateEmbedding(input);
            return embedding.Vector;
        }

        public async Task<List<Product>> SearchProducts(string queryText)
        {
            int numTopHits = 5;
            string vectorFieldName = "Description_V";

            ReadOnlyMemory<float> vectorizedResult = GetEmbeddings(queryText);
            List<Product> products = new List<Product>();

            SearchResults<Product> response = await _searchClient.SearchAsync<Product>(
                new SearchOptions
                {
                    VectorSearch = new()
                    {
                        Queries = { new VectorizedQuery(vectorizedResult) { KNearestNeighborsCount = numTopHits, Fields = { vectorFieldName } } }
                    }
                });

            int documentCount = 0 ;
            await foreach (SearchResult<Product> result in response.GetResultsAsync())
            {
                documentCount++;
                Product doc = result.Document;
                products.Add(doc);
                _logger.LogInformation($"Name: {doc.Name}");
            }

            _logger.LogInformation($"Found '{documentCount}' documents");
            return products;
        }

        public async Task<SearchServiceStatistics> GetSearchServiceStatistics()
        {
            Response<SearchServiceStatistics> stats = await _searchIndexClient.GetServiceStatisticsAsync();
            return stats;
        }

        public async Task<long> GetDocumentIndexCount()
        {
            Response<long> count = await _searchClient.GetDocumentCountAsync();
            return count;
        }
    }
}
