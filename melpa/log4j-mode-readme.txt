This package provides a major mode for viewing log files, including syntax
highlighting, filtering, and source code browsing.

Log records are syntax highlighted using customizable regular expressions
that contain keywords such as INFO and ERROR. Other customizable regular
expressions are used to find the beginning and end of multi-line log
records.

To filter a log file buffer, type `C-c C-s', and enter the desired filter
criteria - any number of keywords separated by spaces. Log records that
contain any of the words in the include list, and none of the words in the
exclude list, will be copied to the filter buffer. All other log records
will be discarded. If the include list is blank, all log records will be
included. If the exclude list is blank, no records will be excluded. If the
log file buffer is auto reverted, the filter buffer will be updated too. To
stop filtering the log file buffer, just type `C-c C-s' again.

To show the source code for a Java identifier found in the log file, place
the point in the identifier, and type `C-c C-b'. Log4j mode will parse the
expression around point, and look up the Java identifier found using jtags
- an Emacs package for editing and browsing Java source code.

This command is only enabled if package jtags is loaded. Note that this
version of Log4j mode requires jtags version 0.95 or later. For more
information about jtags, see http://jtags.sourceforge.net.

Finally, the commands `M-}' and `M-{' are redefined to move to the end
and beginning of the current log record.

Installation:

Place "log4j-mode.el" in your `load-path' and place the following lines
of code in your init file:

(autoload 'log4j-mode "log4j-mode" "Major mode for viewing log files." t)
(add-to-list 'auto-mode-alist '("\\.log\\'" . log4j-mode))

To enable source code browsing, place "jtags.el" in your `load-path' too.

Configuration:

You can customize the faces that are used for syntax highlighting.
Type `M-x customize-group' and enter group name "log4j-mode".

To customize the regular expressions used to identify log records for
syntax highlighting, change the variables `log4j-match-error-regexp'
etc.

You can also customize the regular expressions that are used to find the
beginning and end of multi-line log records. However, in many cases this
will not be necessary. Log4j mode can automatically detect single-line and
multi-line log records created by Log4j and JDK's built-in logging package.

Log file buffers are auto reverted by default. If you don't like that,
set `log4j-auto-revert-flag' to nil.

If you use the arrow keys to move around in the text, you can define `C-up'
and `C-down' to move to the end and beginning of the current log record.
Put the following lines of code in your init file:

(add-hook
 'log4j-mode-hook
 (lambda ()
   (define-key log4j-mode-local-map [(control down)] 'log4j-forward-record)
   (define-key log4j-mode-local-map [(control up)] 'log4j-backward-record)))

XEmacs:

XEmacs tends to move the point to `point-min' when auto reverting a buffer.
Setting the customizable variable `log4j-restore-point-flag' to 't leaves
the point at its original position.

To tell XEmacs which tags table files to use for log files, modify variable
`tag-table-alist' to include log files. Using the example in file "jtags.el"
you could put the following lines of code in your init file:

(setq tag-table-alist '(("\\.\\(java\\|log\\)$" . "c:/java/j2sdk1.4.2/src")
                        ("\\.\\(java\\|log\\)$" . "c:/projects/tetris/src")))
