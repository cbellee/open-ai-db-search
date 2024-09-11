using System;

public class AppConfiguration
{
    public string? Endpoint { get; set; }
    public string? Key { get; set; }
    public string? IndexName { get; set; }
    public string? SemanticConfigName { get; set; }
    public string? VectorFieldName { get; set; }
    public int? NearestNeighbours { get; set; }
    public string? EmbeddingClientName { get; set; }
    public string? ChatGptModelName { get; set; }
    public string? ChatGptKey { get; set; }
    public string? SystemPromptFileName { get; set; }
}

public class SearchClient
{

}
