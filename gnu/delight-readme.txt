Enables you to customise the mode names displayed in the mode line.

For major modes, the buffer-local `mode-name' variable is modified.
For minor modes, the associated value in `minor-mode-alist' is set.

Example usage:

(require 'delight)

(delight 'abbrev-mode " Abv" "abbrev")

(delight '((abbrev-mode " Abv" "abbrev")
           (smart-tab-mode " \\t" "smart-tab")
           (eldoc-mode nil "eldoc")
           (rainbow-mode)
           (overwrite-mode " Ov" t)
           (emacs-lisp-mode "Elisp" :major)))

The first argument is the mode symbol.

The second argument is the replacement name to use in the mode line
(or nil to hide it).

The third argument is either the keyword :major for major modes or,
for minor modes, the library which defines the mode.  This is passed
to ‘eval-after-load’ and so should be either the name (as a string)
of the library file which defines the mode, or the feature (symbol)
provided by that library.  If this argument is nil, the mode symbol
will be passed as the feature.  If this argument is either t or 'emacs
then it is assumed that the mode is already loaded (you can use this
with standard minor modes that are pre-loaded by default when Emacs
starts).

To determine which library defines a mode, use e.g.: C-h f
eldoc-mode RET.  The name of the library is displayed in the first
paragraph, with an “.el” suffix (in this example it displays
“eldoc.el”, and therefore we could use the value “eldoc” for the
library).

Important note:

Although strings are common, any mode-line construct is permitted
as the value (for both minor and major modes); so before you
override a value you should check the existing one, as you may
want to replicate any structural elements in your replacement
if it turns out not to be a simple string.

For major modes, M-: mode-name
For minor modes, M-: (cadr (assq 'MODE minor-mode-alist))
for the minor MODE in question.

Conversely, you may incorporate additional mode-line constructs in
your replacement values, if you so wish. e.g.:

(delight 'emacs-lisp-mode
         '("Elisp" (lexical-binding ":Lex" ":Dyn"))
         :major)

See `mode-line-format' for information about mode-line constructs,
and M-: (info "(elisp) Mode Line Format") for further details.

Also bear in mind that some modes may dynamically update these
values themselves (for instance dired-mode updates mode-name if
you change the sorting criteria) in which cases this library may
prove inadequate.