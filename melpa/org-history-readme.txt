Track and display modification dates automatically in `org-mode`
buffers with this minor mode.

It uses Git version control to make automatic commits whenever you
save a buffer (per-day with --amend).

A special feature allows auto-enabling the mode for current opened
file in current directory by using `.dir-locals.el`, removing the
need to manually list tracked files.

;; Features:

- Automatically commits buffer changes to a per-file Git repository
in the background (using `--amend` to group daily changes)
- Prompts for confirmation only once per file
- Efficient performance even with large files, thanks to caching
and asynchronous Git operations

;; Configuration:

(add-to-list 'load-path "/path-to/emacs-org-history")
(require 'org-history)

If you dont like using .dir-locals.el, you may disable this feature
 in ~/.emacs:
(setopt org-history-dir-locals-flag nil)

;; Activation: M-x org-history

;; Customization: M-x customize-group RET org-history

Hint: You may use "C-h ." at the end of header to get hint without
 using “mouse over” to see it.

Built-in Emacs alternative: M-x vc-annotate

;; How this works:

For every visible header, we get a range of line numbers like
21-34; from .git/, we get the last modification in this range.
We put a read-only overlay on the last character of the Org header
with the date.
We accurately do "git commit --amend" if the current day is the day
of the last commit with the "org-history" message, or just add a new
commit.

When saving, we check .dir-locals.el to see if there is a record
for the current file and if .git exists.  If not, we ask the user and
add the line:
("subfolder-maybe/current-file" (org-mode (mode . org-history)))
Which checks 1) the path of the file relative to the Git directory
2) Org mode for the buffer.
