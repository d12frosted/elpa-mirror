Execute DuckDB queries and return results as Elisp data structures.

Basic usage:

    (duckdb-query "SELECT 42 as answer, 'hello' as greeting")
    ;; => (((answer . 42) (greeting . "hello")))

    (duckdb-query "SELECT * FROM 'data.csv'" :format :columnar)
    ;; => ((id . [1 2 3]) (name . ["Alice" "Bob" "Carol"]))

Inline reference syntax for binding Elisp data into SQL:

    (duckdb-query "SELECT * FROM @data:users WHERE age > @val:min"
                  :data `((users . ,my-data))
                  :val '((min . 18)))

Query fragment composition:

    (duckdb-query "SELECT @sql:cols FROM (@sql:base)"
                  :sql '((cols . "id, name")
                         (base . "SELECT * FROM users")))

Database context management:

    (duckdb-query-with-database "app.db"
      (duckdb-query "SELECT * FROM users"))

Session-based execution for low-latency queries:

    (duckdb-query-with-transient-session
      (duckdb-query "CREATE TABLE t AS SELECT 1")
      (duckdb-query "SELECT * FROM t"))

The package provides:
- `duckdb-query' - Execute queries with format conversion
- `duckdb-query-value' - Extract single scalar value
- `duckdb-query-row' - Extract single row as alist
- `duckdb-query-column' - Extract single column as list
- `duckdb-query-describe' - Schema introspection
- `duckdb-query-with-database' - Scoped database context
- `duckdb-query-with-transient-database' - Temporary file-based database
- `duckdb-query-with-session' - Scoped session execution
- `duckdb-query-with-transient-session' - Ephemeral session

Reference types in SQL strings:
- @val:name        Literal value from :val parameter (safe quoting)
- @data:name       Elisp data from :data parameter (serialized to JSON)
- @sql:name        SQL fragment from :sql parameter (text substitution)
- @org:name        Org table from current buffer
- @org:file:name   Org table from specific file

Output formats via :format parameter:
- :alist (default), :plist, :hash, :vector, :columnar, :org-table
- :single, :row, :column (cardinality-enforced extraction)
- :raw (unprocessed JSON string)

Execution strategies via :executor parameter:
- :cli (default) - Direct CLI invocation
- :session - Persistent process via `duckdb-query-with-session'
- function - Custom executor function
- Custom objects via `cl-defmethod'

For fontification of references, see `duckdb-query-font-lock-mode'.
For completion of references and SQL, see `duckdb-query-complete-mode'.
For benchmarking, see duckdb-query-bench.el.
