This library provides functions to resolve JSON pointers, as defined in
RFC6901 (https://datatracker.ietf.org/doc/html/rfc6901),
within parsed JSON objects, also supporting remote resolution (fetching
JSON from a URI).

JSON pointers can be resolved whether your JSON is parsed as an alist,
plist or a hash table.

It also includes functions to replace JSON references ("$ref" properties)
commonly used in JSON schema and OpenAPI specs.
