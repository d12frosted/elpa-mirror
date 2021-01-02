Integrating multiple commands into one command is sometimes
useful. Pressing C-e at the end of line is useless and adding the
other behavior in this situation is safe.

For example, defining `my-end': if point is at the end of line, go
to the end of buffer, otherwise go to the end of line. Just evaluate it!

(define-sequential-command my-end  end-of-line end-of-buffer)
(global-set-key "\C-e" 'my-end)

Consequently, pressing C-e C-e is `end-of-buffer'!

`define-sequential-command' is a macro that defines a command whose
behavior is changed by sequence of calls of the same command.

`seq-return' is a command to return to the position when sequence
of calls of the same command was started.

See sequential-command-config.el if you want examples.

http://www.emacswiki.org/cgi-bin/wiki/download/sequential-command-config.el
