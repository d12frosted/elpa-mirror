Provides a number of functions for interacting with the AppNexus
API from Emacs.  This package doesn't provide a 'mode'; rather, it
uses Emacs as a user interface for the API.

How it Works:

Every time you make a request to the API, the response data (JSON)
is converted to Lisp and opened in a new buffer.  You can trivially
convert between Lisp, JSON, and escaped JSON strings (which are
also valid Lisp strings). The conversions are also opened in new
buffers.

The idea behind opening every API response and data format
conversion in its own buffer is three-fold:

* History: you never lose the ability to view or modify data

* Visibility: you can always inspect and change data

* Convenience: leverage the existing Emacs UI paradigms (buffers,
keychords, &c.)

This package uses global keybindings (prefixed with 'C-x C-a') for
convenience and speed of access.  However, they aren't turned on by
default. To turn them on, put the following in your .emacs:

(setq anx-use-global-keybindings t)

Getting Started:

First, call `M-x anx-get-user-authentication-credentials', bound to
'C-x C-a a'.  Type in your username and password at the prompt.

'C-x C-a w' displays the current API URL.  The default is the
sandbox environment at http://sand.api.appnexus.com, but you can
toggle between sand and production environments with 'C-x C-a T'.

'C-x C-a A' authenticates.  A new buffer will pop up with the
server's response converted from JSON to Elisp.

'C-x C-a G' makes a GET request. 'C-x C-a P' PUTs or POSTs the
current buffer's data -- currently this must be Lisp, but this
should probably be changed to accept either Lisp or JSON and
toggle-able with a prefix argument.

At any time you can convert Elisp to (an escaped) JSON string using
'C-x C-a J'.  To unescape the JSON, use 'C-x C-a U'. To escape it
again (required for conversion back to Elisp), use 'C-x C-a E'.

The roundtrip workflow from Lisp to an JSON to Lisp is as follows:

C-x C-a J        Convert to an escaped JSON string (valid Lisp or JSON).
C-x C-a U        Unescape the string to reveal the JSON.
C-x C-a E        Escape the JSON; it's a Lisp/JSON string again.
C-x C-a L        Convert the escaped string back to Lisp.

Here's the full list of keybindings:

Keybinding                    Function
----------------------------------------------------------------
C-x C-a A                     'anx-authenticate
C-x C-a a                     'anx-get-user-authentication-credentials
C-x C-a S                     'anx-switch-users

C-x C-a W                     'anx-who-am-i
C-x C-a w                     'anx-display-current-api-url
C-x C-a T                     'anx-toggle-current-api-url

C-x C-a J                     'anx-lisp-to-json
C-x C-a L                     'anx-json-to-lisp

C-x C-a P                     'anx-send-buffer
C-x C-a G                     'anx-get
C-x C-a g                     'anx-raw-get
C-x C-a D                     'anx-delete

C-x C-a U                     'anx-unescape-json
C-x C-a E                     'anx-escape-json

C-x C-a s                     'anx-save-buffer-contents

C-x C-a d                     'anx-browse-api-docs

Known Issues:

* This package assumes all API responses are JSON that needs to be
converted to Lisp.  This doesn't work for things like reporting.

* There is no convenient reporting workflow yet.  You have to
resort to curl/wget or `anx-raw-get' ('C-x C-a g').

* The URL retrieval functionality is synchronous and blocks Emacs.
This hasn't been an issue for me yet because the API servers are
fast.  However, it's not the right way to do things and needs
rewriting.

* There are too many others to list; I can't remember them all
right now.  Feel free to open an issue at Github:
https://github.com/rmloveland/emacs-appnexus-api
