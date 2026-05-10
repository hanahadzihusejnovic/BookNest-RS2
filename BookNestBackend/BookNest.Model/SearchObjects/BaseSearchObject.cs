namespace BookNest.Model.SearchObjects
{
    public class BaseSearchObject
    {
        public int? Page { get; set; } = 0;

        private int? _pageSize = 20;
        public int? PageSize
        {
            get => _pageSize;
            set => _pageSize = value.HasValue ? Math.Min(value.Value, 100) : 20;
        }

        public string SortBy { get; set; } = "Id";
        public bool Desc { get; set; } = false;
        public bool IncludeTotalCount { get; set; } = true;
        public bool RetrieveAll { get; set; } = false;
    }
}