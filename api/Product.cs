﻿namespace ProductSearchAPI
{
    public class Product
    {
        public string? Id { get; set; }
        public string? Type { get; set; }
        public string? Brand { get; set; }
        public string? Name { get; set; }
        public string? Description { get; set; }
        public double? Price { get; set; }
        //public ReadOnlyMemory<float> Description_V { get; set; }
        //public string rid { get; set; }
    }
}