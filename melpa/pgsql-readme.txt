pgsql.el is a synchronous PostgreSQL protocol 3.0 client.  It keeps
framing, authentication, request synchronization, type conversion, and
cancellation behind a small public API.  A request returns or signals only
after its ReadyForQuery message has been consumed.
