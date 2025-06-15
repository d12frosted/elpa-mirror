This library provides infrastructure for building Model Context Protocol
(MCP) servers in Emacs Lisp.  MCP is an open standard for communication
between
AI applications and language models.

Architecture:
- mcp-server-lib.el: Core protocol implementation and tool/resource registry
- mcp-server-lib-commands.el: Interactive commands for users
- mcp-server-lib-metrics.el: Usage tracking and performance monitoring
- mcp-server-lib-ert.el: Test utilities for packages using this library

The library handles JSON-RPC 2.0 communication, manages tool and resource
registration, and provides error handling suitable for LLM interactions.

See https://modelcontextprotocol.io/ for the protocol specification.
