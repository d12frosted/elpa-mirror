Porthole lets you start RPC servers in Emacs. These servers allow Elisp to be
invoked remotely via HTTP requests.

You can expose data that exists within Emacs, or control Emacs from an
external program. You can also execute Elisp functions on data (such as text)
that exists outside Emacs.

---

Porthole servers are designed to "just work." All your server needs is a name
and clients will be able to find it automatically. Here's a typical workflow:

In Emacs:

  1. Pick a name and start your server.
  2. Tell it which functions you want to be available to RPC calls.

  Now, continue using Emacs.

In the Client:

  1. Load the connection information from your server's session file (this
     file has a known path).
  2. POST a JSON-RPC request to the server.

  *Emacs executes your RPC call and returns the result.*

  3. Parse the JSON-RPC 2.0 object you received.

There's even a Python Client to handle the client-side automatically.

See README.md for more information and usage examples.

---

README.md:     https://github.com/jcaw/porthole

Python Client: https://github.com/jcaw/porthole-python-client
