Org Babel support for AWS Athena. Provides a source block backend
to evaluate Athena SQL queries from Org-mode using the AWS CLI.
submitted via the AWS CLI and monitored asynchronously in a
dedicated buffer. Results can be displayed as CSV, Org tables, or JSON.

Features include:
- Asynchronous query execution and live polling
- Real-time execution status and cost estimation
- Console-style Org table rendering of query results
- CSV-to-JSON conversion with cleaning and pretty-printing
- Full AWS Console URL for the running query
- Local raw CSV file saved to system temporary directory
- Result reuse support using Athena workgroups
- Integrated keybindings for interacting with queries:
  - C-c C-k: Cancel running query
  - C-c C-c: Show raw CSV output
  - C-c C-j: Show JSON output (especially useful for CloudTrail)
  - C-c C-a: Open AWS Console link in browser
  - C-c C-l: Open downloaded local CSV file in Emacs

By default, result files are saved to the system temporary directory
returned by `temporary-file-directory`. These CSV files are downloaded
from S3 and can be opened directly or transformed into Org and JSON views.

This package has been tested primarily with CloudTrail query outputs,
but it supports any dataset that is queryable via Athena.
