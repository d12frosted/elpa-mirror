Execute DuckDB queries and return results as Elisp data structures.

Basic usage:

    (duckdb-query "SELECT 42 as answer, 'hello' as greeting")
    ;; => (((answer . 42) (greeting . "hello")))

    (duckdb-query "SELECT * FROM 'data.csv'" :format :columnar)
    ;; => ((id . [1 2 3]) (name . ["Alice" "Bob" "Carol"]))

Database context management:

    (duckdb-query-with-database "app.db"
      (duckdb-query "SELECT * FROM users"))

The package provides:
- `duckdb-query' - Execute queries with format conversion
- `duckdb-query-value' - Extract single scalar value
- `duckdb-query-column' - Extract single column as list
- `duckdb-query-describe' - Schema introspection
- `duckdb-query-with-database' - Scoped database context
- `duckdb-query-with-transient-database' - Temporary file-based database

Output formats via :format parameter:
- :alist (default), :plist, :hash, :vector, :columnar, :org-table

Execution strategies via :executor parameter:
- :cli (default) - Direct CLI invocation
- function - Custom executor function
- Custom objects via `cl-defmethod'

For benchmarking, see duckdb-query-bench.el.
