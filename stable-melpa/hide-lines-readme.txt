
The simplest way to make hide-lines work is to add the following
lines to your .emacs file:

(autoload 'hide-lines "hide-lines" "Hide lines based on a regexp" t)
(global-set-key (kbd "C-c /") 'hide-lines)

Now, when you type C-c /, you will be prompted for a regexp
(regular expression).  All lines matching this regexp will be
hidden in the buffer.

Alternatively, you can type C-u C-c / (ie. provide a prefix
argument to the hide-lines command) to hide all lines that *do not*
match the specified regexp.  If you want to reveal previously hidden
lines you can use any other prefix, e.g. C-u C-u C-c /
