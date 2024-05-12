                                ━━━━━━━
                                 DREPL
                                ━━━━━━━


dREPL is a collection of fully featured language shells for Emacs.  At
the moment it supports the following interpreters:

• *Python*: requires [IPython].
• *Lua*: requires [luarepl] and [dkjson].
• Various *SQL and NoSQL* databases: based on [usql], requires a Go
  compiler.
• *Node.js*: uses the built-in REPL library.

The following features are available, subject to variations across
different REPLs (IPython supports all of them):

• Completion, including annotations and also on continuation lines
• Multi-line input editing
• Eldoc integration
• Normal pty interaction during code evaluation (e.g. debuggers)
• Graphics support via [comint-mime]

In fancier terms, dREPL can be described as a REPL protocol for the dumb
terminal.  One Elisp library defines the user interface and the client
code; support for a new programming language requires only writing some
backend code in the target language, plus a tiny bit of glue code in
Elisp.  If the target language provides a good embeddable REPL library,
then the backend implementation is also reasonably straightforward.


[IPython] <https://pypi.org/project/ipython/>

[luarepl] <https://luarocks.org/modules/hoelzro/luarepl>

[dkjson] <https://luarocks.org/modules/dhkolf/dkjson>

[usql] <https://github.com/xo/usq>

[comint-mime] <https://github.com/astoff/comint-mime>


1 Usage
═══════

  To start a REPL, use one of the `M-x drepl-*' commands (making sure
  first that you have the target language dependencies installed, as
  described above).  The rest should look familiar.

  It is also possible to interact with a REPL from another buffer, say
  to evaluate a region of text.  The relevant commands are the
  following:

  • `drepl-associate': By default, dREPL tries to guess which REPL is
    the right one for any given buffer; an error is raised if there is
    no good guess.  In this case, you can manually create an association
    with this command.
  • `drepl-pop-to-repl': Go to the REPL associated (implicitly or
    explicitly) to the current buffer.
  • `drepl-eval': Evaluate a string read from the minibuffer.
  • `drepl-eval-region' and `drepl-eval-buffer': Evaluate text of the
    current buffer.
  • `drepl-restart': Restart the interpreter.  In IPython this is a soft
    reset; use a prefix argument to kill and start again the
    interpreter.

  Documentation on a symbol in the REPL buffer, if available, can be
  accessed with `eldoc-doc-buffer'.


2 Protocol
══════════

  This package extends Comint and so the communication between Emacs and
  the interpreter happens through a pseudoterminal.  The conundrum is
  how to multiplex control messages and regular IO.

  • From the subprocess to Emacs, control messages travel in JSON
    objects inside an OSC escape sequence (code 5161).
  • From Emacs to the subprocess, control messages are passed as lines
    of the form `ESC = <JSON object> LF'.  If the subprocess
    communicates over a PTY and the encoded message is too long to fit a
    line (this is an OS-dependent limit), then the message payload is
    split into fragments.  All fragments except the last are transmitted
    as `ESC + <JSON fragment> LF'.

  At any given point in time, the subprocess expects either a framed
  messages like this or regular IO.  Emacs keeps track of the state of
  the subprocess through `status' notifications as described below.

  There are three types of message: /requests/, to which a /response/ is
  expected, and /notifications/, to which no response is expected.  A
  message contains the following fields:

  • `op': The operation name.  It must be present in every notification
    and request but is absent in response messages.
  • `id': A unique number which should be present in every request and
    repeated in the response message.  It is absent in notification
    messages.
  • Further fields are parameters specific to each type of request,
    notification or response.

  The following operations are defined:


2.1 `status' (interpreter notification)
───────────────────────────────────────

  The interpreter indicates whether or not it is ready to receive a
  framed operation message.

  Parameters:
  • `status': Either `ready' (subprocess is expecting a framed message),
    `rawio' (IO, if it occurs, should not be framed) or `busy' (no IO is
    allowed).

  Note: The editor keeps track of the interpreter status and implicitly
  switches to `busy' every time a request is sent.  It is the
  interpreter's responsibility to notify about all other status changes.


2.2 `eval' (editor request)
───────────────────────────

  Evaluate some code, blocking until the computation is complete.

  Parameters:
  • `code': The code to be evaluated

  Result: The response contains no data (that is, it includes only the
  original request id).  The REPL should evaluate the code and print the
  result.


2.3 `complete' (editor request)
───────────────────────────────

  Get completions at point.

  Parameters:
  • `code': A code snippet containing the completion point.
  • `pos': The offset (zero-based) from start of `code' to the point of
    completion.

  Response:
  • `prefix' (optional): The portion of code that is being completed.
  • `candidates' (optional): A list of completion candidates, either
    strings or objects containing the following attributes:
    • `text': The completed text, including the existing prefix.
    • `annot': Annotation text to be displayed next to the candidate in
      the completion UI.


2.4 `checkinput' (editor request)
─────────────────────────────────

  Check if a continuation line is needed.

  Parameters:
  • `code' (string): A code snippet.

  Result:
  • `status': One of `complete' (the code is valid), `incomplete' (the
    code is syntactically invalid, but may become so by adding more
    text) or `invalid' (there is a syntax error in the existing portion
    of code).
  • `indent' (optional): If present, this is the expected indentation of
    a continuation line, as a string.
  • `prompt': The prompt of a continuation line.


2.5 `describe' (editor request)
───────────────────────────────

  Obtain information on the symbol at point.

  Parameters:
  • `code': A code snippet.
  • `pos': An offset (zero-based) from start of `code' containing the
    symbol of interest.

  Result: The response may be empty (no information on the symbol) or as
  follows.
  • `name': The symbol name.
  • `type' (optional): The symbol type or function signature.
  • `text' (optional): Free-form documentation on the symbol.


2.6 `setoptions' (editor request)
─────────────────────────────────

  Set configuration options.  The parameters are arbitrary and
  interpreter-specific.  The interpreter must send an empty response.


2.7 `getoptions' (interpreter notification)
───────────────────────────────────────────

  Indicates that the editor should send a `setoptions' request.
  Typically emitted when the interpreter is initialized but before
  printing the first prompt.  Implicitly changes the tracked interpreter
  state to `ready'.


3 Why
═════

  This package is intended to do what the good old Comint does, but
  polishing some rough edges.  For example, completion in Comint is
  spotty and one is able to edit only the last line of a multi-line
  input.
