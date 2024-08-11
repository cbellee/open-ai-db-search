using ProductSearchAPI;
using Microsoft.Extensions.Azure;
using Microsoft.AspNetCore.Mvc;
using Azure;
using Azure.Search.Documents.Models;
using Azure.Search.Documents.Indexes.Models;
using Aspire.Azure.AI.OpenAI;
using System.Dynamic;

var builder = WebApplication.CreateBuilder(args);

var aiSearchEndpoint = builder.Configuration.GetSection("SearchClient:endpoint").Value;
var aiSearchKey = builder.Configuration.GetSection("SearchClient:credential:key").Value;
var aiSearchIndexName = builder.Configuration.GetSection("SearchClient:indexname").Value;

AzureKeyCredential credential = new AzureKeyCredential(aiSearchKey);

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.AddAzureOpenAIClient("OpenAI");
builder.Services.AddScoped<IProductSearchService, ProductSearchService>();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddAzureClients(clients =>
{
    clients.AddSearchClient(new Uri(aiSearchEndpoint), aiSearchIndexName, credential);
    clients.AddSearchIndexClient(new Uri(aiSearchEndpoint), credential);
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

app.Logger.LogInformation("AI Search Endpoint: " + aiSearchEndpoint);
app.Logger.LogInformation("Key: "+ aiSearchKey);
app.Logger.LogInformation("Index Name: " + aiSearchIndexName);

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.MapGet("/products", ([FromQuery(Name = "query")] string query, [FromQuery(Name = "top")] int topResults,
    [FromServices] IProductSearchService productService)
    =>
{
    Task<List<Product>> products = productService.SearchProducts(query, topResults);
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
