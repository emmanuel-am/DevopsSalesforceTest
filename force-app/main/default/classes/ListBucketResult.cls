public with sharing class ListBucketResult {
    public String name;
    public List<Contents> items;
    
    public class Contents {
        public String key;
        public String size;
    }
}