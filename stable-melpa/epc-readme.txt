This program is an asynchronous RPC stack for Emacs.  Using this
RPC stack, the Emacs can communicate with the peer process.
Because the protocol is S-expression encoding and consists of
asynchronous communications, the RPC response is fairly good.

Current implementations for the EPC are followings:
- epcs.el : Emacs Lisp implementation
- RPC::EPC::Service : Perl implementation
