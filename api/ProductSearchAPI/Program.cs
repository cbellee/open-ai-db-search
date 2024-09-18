using ProductSearchAPI;
using Microsoft.Extensions.Azure;
using Microsoft.AspNetCore.Mvc;
using Azure;
using Azure.Search.Documents.Indexes.Models;
using Microsoft.AspNetCore.Http.HttpResults;

var builder = WebApplication.CreateBuilder(args);

// NOTE: if the App won't start in VS, take a look at excluded ports list & change your default ports to outside of the ranges returned.
// $ netsh interface ipv4 show excludedportrange protocol=tcp

var c = new AppConfiguration();
builder.Configuration.GetSection("AppConfiguration").Bind(c);

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.AddAzureOpenAIClient("OpenAI");
builder.Services.AddScoped<IProductSearchService, ProductSearchService>();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddProblemDetails();
builder.Services.AddDatabaseDeveloperPageExceptionFilter();
builder.Services.AddAzureClients(clients =>
{
    clients.AddSearchClient(
        new Uri(c.AISearchClient.Endpoint),
        c.AISearchClient.IndexName,
        new AzureKeyCredential(c.AISearchClient.Credential.Key)
        );

    clients.AddSearchIndexClient(new Uri(
        c.AISearchClient.Endpoint),
        new AzureKeyCredential(c.AISearchClient.Credential.Key)
        );
});

builder.Services.AddCors(o => o.AddDefaultPolicy(builder =>
{
    builder.AllowAnyOrigin()
    .AllowAnyMethod()
    .AllowAnyHeader();
}));

builder.Services.AddCors(options =>
{
    options.AddPolicy(name: "OpenPolicy",
    policy =>
    {
        policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod();
    });

    options.AddPolicy(name: "RestrictedPolicy",
    policy =>
    {
        policy.WithOrigins("https://server.com", "https://anotherserver.com")
        .AllowAnyHeader()
        .WithMethods("GET", "HEAD", "POST", "OPTIONS");
    });
});

var app = builder.Build();

app.UseStatusCodePages(statusCodeHandlerApp =>
{
    statusCodeHandlerApp.Run(async httpContext =>
    {
        var pds = httpContext.RequestServices.GetService<IProblemDetailsService>();
        if (pds == null
          || !await pds.TryWriteAsync(new() { HttpContext = httpContext }))
        {
            await httpContext.Response.WriteAsync("Fallback: An error occurred.");
        }
    });
});

if (app.Environment.IsProduction())
{
    app.UseExceptionHandler(exceptionHandlerApp =>
    {
        exceptionHandlerApp.Run(async httpContext =>
        {
            var pds = httpContext.RequestServices.GetService<IProblemDetailsService>();
            if (pds == null
              || !await pds.TryWriteAsync(new() { HttpContext = httpContext }))
            {
                await httpContext.Response.WriteAsync("Fallback: An error occurred.");
            }
        });
    });
};

app.UseStatusCodePages();
app.UseCors();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.MapGet("/products", async Task<Results<Ok<List<Product>>, NotFound>> (
    [FromQuery(Name = "query")] string query,
    [FromServices] IProductSearchService productService
    ) =>
{
    var products = await productService.SearchProducts(
         query,
         c.AISearchClient.SemanticConfigName,
         c.OpenAIClient.EmbeddingClientName,
         c.AISearchClient.VectorFieldName,
         c.OpenAIClient.Model,
         c.AISearchClient.NearestNeighbours,
         c.OpenAIClient.SystemPromptFileName,
         new List<string> { "Name", "Description", "Brand", "Type" }
     );

    if (products.Count <= 0)
    {
        return TypedResults.NotFound();
    }

    return TypedResults.Ok(products);
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
