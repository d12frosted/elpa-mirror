GEBEN is a software package that interfaces Emacs to DBGp protocol
with which you can debug running scripts interactively.  At this
present time, DBGp protocols are supported in several script
languages with help of custom extensions.

; Usage

1. Insert autoload hooks into your .Emacs file.
   -> (autoload 'geben "geben" "DBGp protocol frontend, a script debugger" t)
2. Start GEBEN.  By default, M-x geben will start it.
   GEBEN starts to listening to DBGp protocol session connection.
3. Run debuggee script.
   When the connection is established, GEBEN loads the entry script
   file in geben-mode.
4. Start debugging.  To see geben-mode key bindings, type ?.

; Requirements:

[Server side]
- PHP with Xdebug 2.0.3
   http://xdebug.org/
- Perl, Python, Ruby, Tcl with Komodo Debugger Extension
   http://aspn.activestate.com/ASPN/Downloads/Komodo/RemoteDebugging

[Client side]
- Emacs 24 and later
