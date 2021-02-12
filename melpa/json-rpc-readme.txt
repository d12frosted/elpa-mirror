The two important functions are `json-rpc-connect' and `json-rpc'.
The first one returns a connection object and the second one makes
synchronous requests on the connection, returning the result or
signaling an error.

Here's an example using the bitcoind JSON-RPC API:

(setf rpc (json-rpc-connect "localhost" 8332 "bitcoinrpc" "mypassword"))
(json-rpc rpc "getblockcount")  ; => 285031
(json-rpc rpc "setgenerate" t 3)

TODO:
 * asynchronous requests
 * response timeout
 * detect auth rejection
