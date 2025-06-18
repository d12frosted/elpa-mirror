This library enables Emacs packages to expose their functionality to AI
applications via the Model Context Protocol (MCP).

For users of MCP-enabled Emacs packages:
1. Run M-x mcp-server-lib-install to install the stdio transport script
2. Run M-x mcp-server-lib-start to start the MCP server
3. Register your MCP server with an AI client using the installed script
   (see your specific MCP server's documentation for details)

Additional commands:
- M-x mcp-server-lib-stop: Stop the MCP server
- M-x mcp-server-lib-show-metrics: View usage statistics
- M-x mcp-server-lib-uninstall: Remove the stdio transport script

The library handles JSON-RPC 2.0 communication, manages tool and resource
registration, and provides error handling suitable for LLM interactions.

See https://modelcontextprotocol.io/ for the protocol specification.
