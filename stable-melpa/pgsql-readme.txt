pgsql.el is a PostgreSQL protocol 3.0 client for synchronous and
asynchronous requests.  It keeps framing, authentication, request
synchronization, type conversion, and cancellation behind a small public
API.  A request completes only after its ReadyForQuery message has been
consumed.
