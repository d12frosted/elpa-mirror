
ack is a tool like grep, aimed at programmers with large trees of
heterogeneous source code.
It is available at <http://betterthangrep.com/>.

Add the following to your .emacs:

(add-to-list 'load-path "/path/to/full-ack")
(autoload 'ack-same "full-ack" nil t)
(autoload 'ack "full-ack" nil t)
(autoload 'ack-find-same-file "full-ack" nil t)
(autoload 'ack-find-file "full-ack" nil t)

Run `ack' to search for all files and `ack-same' to search for files of the
same type as the current buffer.

`next-error' and `previous-error' can be used to jump to the matches.

`ack-find-file' and `ack-find-same-file' use ack to list the files in the
current project.  It's a convenient, though slow, way of finding files.
