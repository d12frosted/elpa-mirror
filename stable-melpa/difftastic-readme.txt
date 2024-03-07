The difftastic Emacs package is designed to integrate difftastic - a
structural diff tool - (https://github.com/wilfred/difftastic) into your
Emacs workflow, enhancing your code review and comparison experience.  This
package automatically displays difftastic's output within Emacs using faces
from your user theme, ensuring consistency with your overall coding
environment.

Configuration

To configure `difftastic` commands in `magit-diff` prefix, use the following
code snippet in your Emacs configuration:

(require 'difftastic)

;; Add commands to a `magit-difftastic'
(eval-after-load 'magit-diff
  '(transient-append-suffix 'magit-diff '(-1 -1)
     [("D" "Difftastic diff (dwim)" difftastic-magit-diff)
      ("S" "Difftastic show" difftastic-magit-show)]))
(add-hook 'magit-blame-read-only-mode-hook
          (lambda ()
            (keymap-set magit-blame-read-only-mode-map
                        "D" #'difftastic-magit-show)
            (keymap-set magit-blame-read-only-mode-map
                        "S" #'difftastic-magit-show)))

Or, if you use `use-package':

(use-package difftastic
  :demand t
  :bind (:map magit-blame-read-only-mode-map
         ("D" . difftastic-magit-show)
         ("S" . difftastic-magit-show))
  :config
  (eval-after-load 'magit-diff
    '(transient-append-suffix 'magit-diff '(-1 -1)
       [("D" "Difftastic diff (dwim)" difftastic-magit-diff)
        ("S" "Difftastic show" difftastic-magit-show)])))

Usage

The following commands are meant to help to interact with
difftastic.  Commands are followed by their default keybindings in
`difftastic-mode' (in parenthesis).

- `difftastic-magit-diff' - show the result of 'git diff ARGS -- FILES' with
  difftastic.  This is the main entry point for DWIM action, so it tries to
  guess revision or range.

- `difftastic-magit-show' - show the result of 'git show ARG' with
  difftastic.  It tries to guess ARG, and ask for it when can't. When called
  with prefix argument it will ask for ARG.

- `difftastic-files' - show the result of 'difft FILE-A FILE-B'.  When
  called with prefix argument it will ask for language to use, instead of
  relaying on difftastic's detection mechanism.

- `difftastic-buffers' - show the result of 'difft BUFFER-A BUFFER-B'.
  Language is guessed based on buffers modes.  When called with prefix
  argument it will ask for language to use.

- `difftastic-dired-diff' - same as `dired-diff', but with
  `difftastic-files' instead of the built-in `diff'.

- `difftastic-rerun' ('g') - rerun difftastic for the current buffer.  It
  runs difftastic again in the current buffer, but respects the window
  configuration.  It uses `difftastic-rerun-requested-window-width-function'
  which, by default, returns current window width (instead of
  `difftastic-requested-window-width-function').  It will also reuse current
  buffer and will not call `difftastic-display-buffer-function'.  When
  called with prefix argument it will ask for language to use.

- `difftastic-next-chunk' ('n'), `difftastic-next-file' ('N') - move point
  to a next logical chunk or a next file respectively.

- `difftastic-previous-chunk' ('p'), `difftastic-previous-file' ('P') - move
  point to a next logical chunk or a previous file respectively.

- `difftastic-git-diff-range' - transform ARGS for difftastic and show the
  result of 'git diff ARGS REV-OR-RANGE -- FILES' with difftastic.
