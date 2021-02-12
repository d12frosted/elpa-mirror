If you have not installed this from a package such as those on
Marmalade or MELPA, then save kanban.el to a directory in your
load-path and add

(require 'kanban)

to your Emacs start-up files.

Usage:

* Zero state Kanban: Directly displaying org-mode todo states as kanban board

Use the functions kanban-headers and kanban-zero in TBLFM lines to
get your org-mode todo states as kanban table.  Update with C-c C-c
on the TBLFM line.

Example:

|   |   |   |
|---+---+---|
|   |   |   |
|   |   |   |
#+TBLFM: @1$1='(kanban-headers)::@2$1..@>$>='(kanban-zero @# $# "TAG" '(list-of-files))

"TAG" and the list of files are optional. To get all tags, use ""
or nil. To only show entries from the current file, use 'file
instead of '(list-of-files).

* Stateful Kanban: Use org-mode to retrieve tasks, but track their state in the Kanban board

|   |   |   |
|---+---+---|
|   |   |   |
|   |   |   |
#+TBLFM: @1$1='(kanban-headers)::@2$1..@>$1='(kanban-todo @# @2$2..@>$> "TAG" '(list-of-files))
"TAG" and the list of files are optional

Faster Example with kanban-fill (fills fields into their starting
state but does not change them):

|   |   |   |
|---+---+---|
|   |   |   |
|   |   |   |
#+TBLFM: @2='(kanban-fill "TAG" '(list-of-files))::@1$1='(kanban-headers $#)::
"TAG" and the list of files are optional

More complex use cases are described in the file sample.org

TODO: kanban-todo sometimes inserts no tasks at all if there are multiple tasks in non-standard states.

TODO: bold text in headlines breaks the parser (*bold*).

ChangeLog:

 - tip:   cleanup of titles from remote files
 - 0.2.1: document usage of "" to get all tags and 'file
 - 0.2.0: Finally merge the much faster kanban-fill from stackeffect.
          I’m sorry that it took me 3 years to get there.
 - 0.1.7: strip keyword from link for org-version >= 9 and
          avoid stripping trailing "* .*" in lines
 - 0.1.6: defcustom instead of defvar
 - 0.1.5: Allow customizing the maximum column width with
          kanban-max-column-width
 - 0.1.4: Test version to see whether the marmalade upload works.
