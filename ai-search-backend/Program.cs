using ai_search_backend;
using Microsoft.Extensions.Azure;
using Microsoft.AspNetCore.Mvc;
using Azure;
using Azure.Search.Documents.Models;
using Azure.Search.Documents.Indexes.Models;
using Aspire.Azure.AI.OpenAI;
using System.Dynamic;

var builder = WebApplication.CreateBuilder(args);

var endpoint = builder.Configuration.GetSection("SearchClient:endpoint").Value;
var openAiEndpoint = builder.Configuration.GetSection("SearchClient:openaiendpoint").Value;
var key = builder.Configuration.GetSection("SearchClient:credential:key").Value;
var indexName = builder.Configuration.GetSection("SearchClient:indexname").Value;
var openApiKey = builder.Configuration.GetSection("SearchClient:credential:openapikey").Value;

AzureKeyCredential credential = new AzureKeyCredential(key);

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.AddAzureOpenAIClient("OpenAI");
builder.Services.AddScoped<IProductSearchService, ProductSearchService>();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddAzureClients(clients =>
{
    clients.AddSearchClient(new Uri(endpoint), indexName, credential);
    clients.AddSearchIndexClient(new Uri(endpoint), credential);
});

builder.Services.AddCors(o => o.AddDefaultPolicy(builder =>
{
    builder.AllowAnyOrigin()
    .AllowAnyMethod()
    .AllowAnyHeader();
}));

var app = builder.Build();
app.UseStatusCodePages();
app.UseCors();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.MapGet("/products", ([FromQuery(Name = "query")] string query,
    [FromServices] IProductSearchService productService)
    =>
{
    Task<List<Product>> products = productService.SearchProducts(query);
    return products;
});

app.MapGet("/stats", (
    [FromServices] IProductSearchService productService)
    =>
{
    Task<SearchServiceStatistics> stats = productService.GetSearchServiceStatistics();
    return stats.Result;
});

app.MapGet("/count", (
    [FromServices] IProductSearchService productService)
    =>
{
    Task<long> documentCount = productService.GetDocumentIndexCount();
    return documentCount.Result;
});

app.Run();
