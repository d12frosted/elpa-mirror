A major mode for editing q (the language written by Kx Systems, see
URL `https://code.kx.com') in Emacs.

Some of its major features include:

 - syntax highlighting (font-lock-mode),

 - syntax checking (flymake-mode),

 - interaction with inferior q[con] instance (comint-mode),

 - inline eval results next to the code that produced them (`q-inline-mode'),

 - native Emacs qcon replacement supporting TLS (`q-con'),

 - secure password retrieval (auth-source),

 - named remote connections (q-connections),

 - incremental, project-wide indexing (imenu, xref),

 - completion at point (CAPF),

 - signature help (eldoc),

 - current function in the mode line (which-function-mode),

 - code folding (hideshow).

To load `q-mode' on-demand, instead of at startup, add this to your
initialization file

(autoload 'q-mode "q-mode")

Then add the following to your initialization file to open all .k
and .q files with q-mode as major mode automatically:

(add-to-list 'auto-mode-alist '("\\.[kq]\\'" . q-mode))

If you load ess-mode, it will attempt to associate the .q extension
with S-mode.  To stop this, add the following lines to your
initialization file.

(defun remove-ess-q-extn ()
  (when (assoc "\\.[qsS]\\'" auto-mode-alist)
   (setq auto-mode-alist
         (remassoc "\\.[qsS]\\'" auto-mode-alist))))
(add-hook 'ess-mode-hook 'remove-ess-q-extn)
(add-hook 'inferior-ess-mode-hook 'remove-ess-q-extn)

Use `M-x q' to start an inferior q shell.  Or use `M-x q-qcon' to
create an inferior qcon shell to communicate with an existing q
process.  Both can be prefixed with the universal-argument `C-u' to
customize the arguments used to start the processes.

`M-x q-con' talks to an existing q process the same way `q-qcon'
does, but without executing an external qcon binary: Emacs opens
the TCP connection itself.  This matters for the password - qcon
receives it as a literal command-line argument, so it's visible to
anyone on the machine running `ps'; `q-con' resolves it from
auth-source only for the instant it takes to write it to the
socket, and it never becomes a command-line argument at all.
`q-con' also supports TLS: prefix a host with `tcps://' - in
`q-connection-host', a `q-connections' entry, or typed ad-hoc at the
prompt - to connect over TLS instead of plain tcp.

When prompted this way, `q-qcon' and `q-con' both offer named
connections from `q-connections' as completion candidates,
alongside the option of typing an ad-hoc "host:port[:user]" string.
Each entry in `q-connections' is a (NAME HOST PORT USER) list,
letting you refer to a remote q server by a short name instead of
retyping its host/port/user every time.  In every case, the
password itself is never typed or stored in `q-connections' - it's
always resolved from auth-source.  `.netrc'/`.authinfo' is the
common case, but auth-source is backend-agnostic: anything
registered as an `auth-source-backend' (e.g. the system Secret
Service/macOS Keychain via `auth-source-pass' or `secrets.el', or a
custom backend you write yourself) is consulted the same way, so
the password need not live in a plaintext file at all.

The first q[con] session opened becomes the activated buffer.
To open a new session and send code to the new buffer, it must be
activated.  Switch to the desired buffer and type `C-c M-RET' to
activate it.

Displaying tables with many columns will wrap around the buffer -
making the data hard to read.  You can use the
`toggle-truncate-lines' function to prevent the wrapping.  You can
then scroll left and right in the buffer to see all the columns.

The following commands are available to interact with an inferior
q[con] process/buffer.  `C-c C-j' (as well as `C-c C-l' and
`C-M-x') sends a single line, `C-c C-f' sends the surrounding
function, `C-c C-s' sends the symbol at point, `C-c C-r' sends
the selected region and `C-c C-b' sends the whole buffer.  If
prefixed with `C-u C-u', or pressing `C-c M-j' `C-c M-f' `C-c
M-s' `C-c M-r' respectively, will also switch point to the active
q process buffer for direct interaction.

If the source file exists on the same machine as the q process,
`C-c M-l' can be used to load the file associated with the active
buffer.

`M-x q-inline-mode' toggles showing eval results as an overlay next
to the code that produced them, in addition to the usual q[con]
buffer output.  `C-c C-.' pops up the full, untruncated reply for
the result at point (useful for tables, which are shown truncated
to their first line inline); `C-c C-k' clears the result at point,
and `C-u C-c C-k' clears every result in the buffer.  Editing the
code a result is attached to clears that result automatically.  The
`q-inline-duration' variable controls how long a result stays
visible: nil (the default) leaves it until the code is edited or
explicitly cleared, a number of seconds auto-clears it after that
long, and the symbol `command' clears it as soon as any command
runs.

`C-c C-g' triggers a manual rescan of the project, re-scanning only
files whose mtime has changed.  Prefix with `C-u' to force all files
to be re-scanned regardless of mtime, which is useful after a branch
switch where file timestamps may be preserved.

Quick access to variable and function definitions can be obtained
using the `imenu' binding `M-g i'.  Completion is available via
`completion-at-point' (usually `M-TAB').  Candidates are annotated
with their kind (<function>, <variable>, <keyword>, or <builtin>).
Eldoc displays signatures while you type, and xref provides `M-.'
for definitions, `M-?' for references, and `C-M-.' for apropos
search across all known identifiers in the project.

Code folding is available via `hs-minor-mode'.  Once enabled, use
the standard hideshow bindings to fold and unfold {} blocks.

`which-function-mode' is supported and will display the name of the
enclosing function in the mode line as you move point.  Enable it
globally with (which-function-mode 1) in your initialization file,
or per-buffer with M-x which-function-mode.


`M-x customize-group' can be used to customize the `q' group.
Specifically, the `q-program' and `q-qcon-program' variables can be
changed depending on your environment.  The `q-rescan-idle-delay'
variable controls how long to wait after a save before rescanning;
it debounces rapid saves and defers the check for out-of-band disk
changes such as those made by git pull.

Q-mode indents each level based on `q-indent-step'.  To indent code
based on {}-, ()-, and []-groups instead of equal width tabs, you
can set this value to nil.

The variables `q-msg-prefix' and `q-msg-postfix' can be customized
to prefix and postfix every msg sent to the inferior q[con]
process.  This can be used to change directories before evaluating
definitions within the q process and then changing back to the root
directory.  To make the variables change values depending on which
file they are sent from, values can be defined in a single line at
the top of each .q file:

/ -*- q-msg-prefix: "system \"d .jnp\";"; q-msg-postfix: ";system \"d .\"";-*-

or at the end:

/ Local Variables:
/ q-msg-prefix: "system \"d .jnp\";"
/ q-msg-postfix: ";system \"d .\""
/ End:
