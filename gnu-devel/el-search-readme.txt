This package implements an expression based interactive search tool
for Emacs Lisp files and buffers.  The pattern language used is a
superset of `pcase' patterns.

"el-search" is multi file/buffer search capable.  It is designed to
be fast and easy to use.  It offers an occur-like overview of
matches and can do query-replace based on the same set of patterns.
All searches are added to a history and can be resumed or restarted
later.  Finally, it allows you to define your own kinds of search
patterns and your own multi-search commands.


Key bindings
============

Loading this file doesn't install any key bindings - but you maybe
want some.  There are two predefined installable schemes of key
bindings.  The first scheme defines bindings mostly of the form
"Control-Shift-Letter", e.g. C-S, C-R, C-% etc.  These can be
installed by calling (el-search-install-shift-bindings) - typically
from your init file.  For console users (and others), the function
`el-search-install-bindings-under-prefix' installs bindings of the
form PREFIX LETTER.  If you call

  (el-search-install-bindings-under-prefix [(meta ?s) ?e])

you install bindings M-s e s, M-s e r, M-s e % etc.  When using
this function to install key bindings, installed bindings are
"repeatable" where it makes sense so that you can for example hit
M-s e j s s s a % to reactive the last search, go to the next match
three times, then go back to the first match in the current buffer,
and finally invoke `el-search-query-replace'.

It follows a complete list of key bindings installed when
you call

  (el-search-install-shift-bindings)

or

  (el-search-install-bindings-under-prefix [(meta ?s) ?e])

respectively.  If you don't want to install any key bindings, you
want to remember the command name "el-search-pattern" or its alias
"el-search" to get a start, and that after starting a search C-h
will give you access to some help commands; among other things C-h
b listing the relevant key bindings for controlling a search.

  C-S, M-s e s (`el-search-pattern')
    Start a search in the current buffer/go to the next match.

    While searching, the searched buffer is current (not the
    minibuffer).  All commands that are not search or scrolling
    commands terminate the search, while the state of the search is
    always automatically saved.  Like in isearch you can also just
    hit RET to exit or C-g to abort and jump back to where you
    started.

    By using the prefix arg this command can be used to reactivate
    the last or a former search and to restart searches from the
    beginning.

  C-h (aka the `help-char')

    C-h offers access to some help commands special to el-search
    when a search is active.  Among other things C-h b (or ?) gives
    you a list of bindings to control the search.

  C-R, M-s e r (`el-search-pattern-backward')
    Search backward.

  C-%, M-s e % (`el-search-query-replace')
    Start a query-replace session.  Resume or restart sessions with
    prefix arg.

  M-x el-search-directory
    Prompt for a directory name and start a multi el-search for all
    Emacs-Lisp files in that directory.  With prefix arg,
    recursively search files in subdirectories.

  C-S, M-s e s in Dired (`el-search-dired-marked-files')
    Like above but uses the marked files and directories.

  C-S, M-s e s in Ibuffer (`el-search-ibuffer-marked-buffers')
    Search marked buffers in *Ibuffer*.

  C-O, M-s e o (`el-search-occur')
    Pop up an occur buffer for the current search.

  C-O or M-RET (from a search pattern prompt)
    Execute this search command as occur.

  C-X, M-s e x (`el-search-continue-in-next-buffer')
    Skip over current buffer or file.

  C-D, M-s e d (`el-search-skip-directory')
    Prompt for a directory name and skip all subsequent files
    located under this directory.

  C-A, M-s e a, M-s e < (`el-search-from-beginning')
    Go back to the first match in this buffer.
    With prefix arg or with M-s e >, go to the last match in
    the current buffer.

  C-J, M-s e j (`el-search-jump')
    Convenience command to move by matches.  Resumes the last
    search if necessary.
    Without prefix arg, jump (back) to the current match.
    With prefix arg 0, resume from the position of the match
    following point instead.
    With prefix arg 1 or -1, jump to the first or last match
    visible in the selected window.

  C-S-next, v   when search is active (`el-search-scroll-down')
  C-S-prior, V  when search is active (`el-search-scroll-up')
    Scrolling by matches: Select the first match after
    `window-end', or select the first match before `window-start',
    respectively.

  C-H, M-s e h (`el-search-this-sexp')
    Grab the symbol or sexp under point and initiate an el-search
    for other occurrences.

  M-x el-search-to-register
  M-x el-search-query-replace-to-register
    Save the current el-search or el-search-query-replace session
    to an Emacs register.  Use `jump-to-register' (C-x r j) to
    continue that search or query-replace session.


The setup you need for your init file is trivial: you only need to
install key bindings if you want some (see above).  All important
commands are autoloaded.


Usage
=====

The main user entry point `el-search-pattern' (C-S or M-s e s) is
analogue to `isearch-forward'.  You are prompted for a
`pcase'-style search pattern using an `emacs-lisp-mode' minibuffer.
After hitting RET it searches the current buffer from point for
matching expressions.  For any match, point is put at the beginning
of the expression found (unlike isearch which puts point at the end
of matches).  Hit C-S or s again to go to the next match etc.

Syntax and semantics of search patterns are identical to that of
`pcase' patterns, plus additionally defined pattern types
especially useful for matching parts of programs.

It doesn't matter how code is formatted.  Comments are
ignored, and strings are treated as atomic objects (their contents
are not being searched).


Example 1: if you enter

   97

at the prompt, el-search will find any occurrence of the integer 97
in the code, but not 97.0 or 977 or (+ 90 7) or "My string
containing 97" or symbol_97.  OTOH it will find any printed
representation of 97, e.g. #x61 or ?a.


Example 2: If you enter the pattern

  `(defvar ,_)

you search for all `defvar' forms that don't specify an init value.

The following pattern will search for `defvar's with a docstring
whose first line is longer than 70 characters:

  `(defvar ,_ ,_
     ,(and (pred stringp)
           s
           (guard (< 70 (length (car (split-string s "\n")))))))

Put simply, el-search is a tool for matching representations of
symbolic expressions written in a buffer or file.  Most of the
time, but not necessarily, this is Elisp code.  El-search has no
semantic understanding of the meaning of these s-exps as a program
per se.  If you define a macro `my-defvar' that expands to `defvar'
forms, the pattern `(defvar ,_) will not match any equivalent
`my-defvar' form, it just matches any lists of two elements with
the first element being the symbol `defvar'.

You can define your own pattern types with macro
`el-search-defpattern' which is analogue to `defmacro' (and
`pcase-defmacro').  See C-h f `el-search-defined-patterns' for a
list of predefined additional pattern types, and C-h f pcase for
the basic pcase patterns.

Some additional pattern definitions can be found in the file
"el-search-x.el" which is part of this package but not
automatically loaded.


Multi Searching
===============

"el-search" is capable of performing "multi searches" - searches
spanning multiple files or buffers.  When no more matches can be
found in the current file or buffer, the search automatically
switches to the next one.  Examples for search commands that start
a multi search are `el-search-buffers' (search all live elisp mode
buffers), `el-search-directory' (search all elisp files in a
specified directory), `el-search-emacs-elisp-sources',
`el-search-dired-marked-files' and `el-search-repository'.
Actually, every search is internally a multi search.

You can pause any search by just doing something different (no
explicit quitting needed); the state of the search is automatically
saved.  You can later continue searching by calling
`el-search-pattern' (C-S; M-s e s) with a prefix arg.

`el-search-continue-in-next-buffer' (C-X; x) skips all remaining
matches in the current buffer and continues searching in the next
buffer.  `el-search-skip-directory' (C-D; d) even skips all
subsequent files under a specified directory.


El-Occur
========

To get an occur-like overview you can use the usual commands.  You
can either hit C-O or M-RET from the pattern prompt instead of RET
to confirm your input and start the search as noninteractive occur
search in the first place.  Alternatively, you can always call
`el-search-occur' (C-O or o) to start an occur for the latest
started search.

The *El Occur* buffer uses an adjusted emacs-lisp-mode.  RET on a
match gives you a pop-up window displaying the position of the
match in that buffer or file.  With S-tab you can (un)collapse all
file sections like in `org-mode' to see only file names and the
number of matches, or everything.  Tab folds and unfolds
expressions (this uses hideshow) and also sections at the beginning
of headlines.


Multiple multi searches
=======================

Every search is stored in a history.  You can resume older searches
from the position of the last match by calling `el-search-pattern'
(C-S; M-s e s) with a prefix argument.  That let's you select an
older search to resume and switches to the buffer and position
where this search had been suspended.


Query-replace
=============

You can replace expressions with command `el-search-query-replace'.
You are queried for a pattern and a replacement expression.  For
each match of the pattern, the replacement expression is evaluated
with the bindings created by pattern matching in effect and printed
to a string to produce the replacement.

Example: In some buffer you want to swap the two expressions at the
places of the first two arguments in all calls of function `foo',
so that e.g.

  (foo 'a (* 2 (+ 3 4)) t)

becomes

  (foo (* 2 (+ 3 4)) 'a t).

This will do it:

   C-%  (or M-s e %)
   `(foo ,a ,b . ,rest) RET
   `(foo ,b ,a . ,rest) RET

Type y to replace a match and go to the next one, r to replace
without moving (hitting r again restores that match), n to go to
the next match without replacing and ! to replace all remaining
matches automatically.  q quits.  ? shows a quick help summarizing
all of these keys.

It is possible to replace a match with an arbitrary number of
expressions using "splicing mode".  When it is active, the
replacement expression must evaluate to a list, and this list is
spliced into the buffer for any match.  Hit s from the prompt to
toggle splicing mode in an `el-search-query-replace' session.

Much like `el-search' sessions, `el-search-query-replace' sessions
are also internally represented as objects with state, and are also
collected in a history.  That means you can pause, resume and
restart query-replace sessions, store them in registers, etc.

There are two ways to edit replacements directly while performing
an el-search-query-replace:

(1) Without suspending the search: hit e at the prompt to show the
replacement of the current match in a separate buffer.  You can
edit the replacement in this buffer.  Confirming with C-c C-c will
make el-search replace the current match with this buffer's
contents.

(2) At any time you can interrupt a query-replace session by
hitting RET.  You can resume the query-replace session by calling
`el-search-query-replace' with a prefix argument.


Multi query-replace
===================

To query-replace in multiple files or buffers at once, call
`el-search-query-replace' directly after starting a search whose
search domain is the set of files and buffers you want to treat.
Answer "yes" to the prompt asking whether you want the started
search to drive the query-replace.  The user interface is
self-explanatory.


Advanced usage: Replacement rules for semi-automatic code rewriting
===================================================================

When you want to rewrite larger code parts programmatically, it can
often be useful to define a dedicated pattern type to perform the
replacement.  Here is an example:

You heard that in many situations, `dolist' is faster than an
equivalent `mapc'.  You use `mapc' quite often in your code and
want to query-replace many occurrences in your stuff.  Instead of
using an ad hoc replacing rule, it's cleaner to define a dedicated
named pattern type using `el-search-defpattern'.  Make this pattern
accept an argument and use it to bind a replacement expression to a
variable you specify.  In query-replace, specify that variable as
replacement expression.

In our case, the pattern could look like this:

  (el-search-defpattern el-search-mapc->dolist (new)
    (let ((var  (make-symbol "var"))
          (body (make-symbol "body"))
          (list (make-symbol "list")))
      `(and `(mapc (lambda (,,var) . ,,body) ,,list)
            (let ,new `(dolist (,,var ,,list) . ,,body)))))

The first condition in the `and' performs the matching and binds
the essential parts of the `mapc' form to helper variables.  The
second, the `let', part, binds the specified variable NEW to the
rewritten expression - in our case, a `dolist' form is constructed
with the remembered code parts filled in.

Now after this preparatory work, for `el-search-query-replace' you
can simply specify (literally!) the following rule:

  (el-search-mapc->dolist repl) -> repl


Acknowledgments
===============

Thanks to Manuela for our review sessions.
Thanks to Stefan Monnier for corrections and advice.


Known Limitations and Bugs
==========================

- Replacing: in some cases the read syntax of forms is changing due
  to reading-printing.  "Some" because we can handle this problem
  in most cases.

- Something like (1 #1#) is unmatchable (because it is un`read'able
  without context).

- In el-search-query-replace, replacements are not allowed to
  contain uninterned symbols.

- The `l' pattern type is very slow for very long lists.
  E.g. C-S-e (l "test")

- Emacs bug#30132: 27.0.50; "scan-sexps and ##": Occurrences of the
  syntax "##" (a syntax for an interned symbol whose name is the
  empty string) can lead to errors while searching.


TODO:

- Add org and/or Info documentation

- Could we profit from the edebug-read-storing-offsets reader?

- Make currently hardcoded bindings in
  `el-search-loop-over-bindings' configurable

- When reading input, bind up and down to
  next-line-or-history-element and
  previous-line-or-history-element?

- Make searching work in comments, too? (->
  `parse-sexp-ignore-comments').  Related: should the pattern
  `symbol' also match strings that contain matches for a symbol so
  that it's possible to replace occurrences of a symbol in
  docstrings?

- Port this package to non Emacs Lisp modes?  How?  Would it
  already suffice using only syntax tables, sexp scanning and
  font-lock?

- There could be something much better than pp to format the
  replacement, or pp should be improved.


NEWS:

NEWS are listed in the separate NEWS file.