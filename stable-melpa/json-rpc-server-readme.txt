This is a full implementation of the JSON-RPC 2.0 protocol[1] for Emacs. You
pass in a JSON string, Emacs executes the specified function(s), and a
JSON-RPC 2.0 response is returned.

It was originally part of Porthole, a full-fledged HTTP-based RPC server for
Emacs:

http://www.github.com/jcaw/porthole

The underlying JSON-RPC protocol was extracted into a separate package so
that it could serve as a framework on which other RPC servers could be built.

*No transport logic is included.* This package is designed to sit underneath
a transport layer, which is responsible for communicate with external
clients. Since JSON-RPC provides no inbuilt mechanism for authenticating
requests, the transport layer should also handle authentication.

Here's en example request:

{
  "jsonrpc": "2.0",
  "method": "insert",
  "params": ["some text to insert"],
  "id": "3140983184"
}

Pass this as a string to `json-rpc-server-handle' - the specified text will
be inserted and the return value of the call to `insert' will be encoded into
a response.

Symbols and keywords can be passed by abusing the JSON-RPC syntax as follows:

{
  "a symbol": "'a-symbol",
  "a keyword": ":a-keyword"
}

This is a simplified explanation of the package that glosses over a lot of
details. Please refer to the full README[3] for an up-to-date and thorough
explanation.

[1] https://www.jsonrpc.org/specification

[2] https://groups.google.com/d/msg/json-rpc/PN462g49yL8/DdMa93870_o

[3] http://www.github.com/jcaw/json-rpc-server.el/README.md
