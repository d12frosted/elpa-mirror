Description
===========

The `difftastic' Emacs package is designed to integrate [difftastic] - a
structural diff tool - into your Emacs workflow, enhancing your code review
and comparison experience.  This package automatically displays
`difftastic''s output within Emacs using faces from your user theme,
ensuring consistency with your overall coding environment.


[difftastic] <https://github.com/wilfred/difftastic>


Features
========

- Configure faces to your likening.  By default `magit-diff-*' faces from
  your user them are used for consistent visual experience.
- Chunks and file navigation using `n' / `N' and `p' / `P' in generated
  diffs.
- DWIM workflows from `magit'.
- Rerun `difftastic' with `g' to use current window width to "reflow"
  content and/or to force language change (when called with prefix).


Installation
============

Installing from MELPA
~~~~~~~~~~~~~~~~~~~~~

The easiest way to install and keep `difftastic' up-to-date is using Emacs'
built-in package manager.  `difftastic' is available in the MELPA
repository.  Refer to <https://melpa.org/#/getting-started> for how to
install a package from MELPA.


Installing from GitHub
~~~~~~~~~~~~~~~~~~~~~~

1. Clone this repository to a directory of your choice.
2. Add the following lines to your Emacs configuration file (usually
   `~/.emacs' or `~/.emacs.d/init.el'):

(add-to-list 'load-path "/path/to/difftastic.el")
(require 'difftastic)


Configuration
=============

To configure `difftastic' commands in `magit-diff' prefix, use the
following code snippet in your Emacs configuration:

(require 'difftastic)

;; Add commands to a `magit-difftastic'
(with-eval-after-load 'magit-diff
    (when-let* ((suffix [("D" "Difftastic diff (dwim)" difftastic-magit-diff)
                         ("S" "Difftastic show" difftastic-magit-show)])
                ((not (equal (transient-parse-suffix 'magit-diff suffix)
                             (transient-get-suffix 'magit-diff '(-1 -1))))))
      (transient-append-suffix 'magit-diff '(-1 -1) suffix)))
(with-eval-after-load 'magit-blame
  (keymap-set magit-blame-read-only-mode-map
              "D" #'difftastic-magit-show)
  (keymap-set magit-blame-read-only-mode-map
              "S" #'difftastic-magit-show))

Or, if you use `use-package':

(use-package difftastic
  :defer t
  :init
  (use-package transient
    :autoload (transient-get-suffix
               transient-parse-suffix))
  (use-package magit-blame
    :defer t :ensure magit
    :bind
    (:map magit-blame-read-only-mode-map
     ("D" . #'difftastic-magit-diff)
     ("S" . #'difftastic-magit-show)))
  (with-eval-after-load 'magit-diff
    (when-let* ((suffix [("D" "Difftastic diff (dwim)" difftastic-magit-diff)
                         ("S" "Difftastic show" difftastic-magit-show)])
                ((not (equal (transient-parse-suffix 'magit-diff suffix)
                             (transient-get-suffix 'magit-diff '(-1 -1))))))
      (transient-append-suffix 'magit-diff '(-1 -1) suffix))))


Usage
=====

The following commands are meant to help to interact with `difftastic'.
Commands are followed by their default keybindings in `difftastic-mode' (in
parenthesis).

- `difftastic-magit-diff' - show the result of `git diff ARGS -- FILES'
  with `difftastic'.  This is the main entry point for DWIM action, so it
  tries to guess revision or range.
- `difftastic-magit-show' - show the result of `git show ARG' with
  `difftastic'.  It tries to guess `ARG', and ask for it when can't. When
  called with prefix argument it will ask for `ARG'.
- `difftastic-files' - show the result of `difft FILE-A FILE-B'.  When
  called with prefix argument it will ask for language to use, instead of
  relaying on `difftastic''s detection mechanism.
- `difftastic-buffers' - show the result of `difft BUFFER-A BUFFER-B'.
  Language is guessed based on buffers modes.  When called with prefix
  argument it will ask for language to use.
- `difftastic-dired-diff' - same as `dired-diff', but with
  `difftastic-files' instead of the built-in `diff'.
- `difftastic-rerun' (`g') - rerun difftastic for the current buffer.  It
  runs difftastic again in the current buffer, but respects the window
  configuration.  It uses
  `difftastic-rerun-requested-window-width-function' which, by default,
  returns current window width (instead of
  `difftastic-requested-window-width-function').  It will also reuse
  current buffer and will not call `difftastic-display-buffer-function'.
  When called with prefix argument it will ask for language to use.
- `difftastic-next-chunk' (`n'), `difftastic-next-file' (`N') - move point
  to a next logical chunk or a next file respectively.
- `difftastic-previous-chunk' (`p'), `difftastic-previous-file' (`P') -
  move point to a previous logical chunk or a previous file respectively.
- `difftastic-toggle-chunk' (`TAB' or `C-i') - toggle visibility of a chunk
  at point.  The point has to be in a chunk header.  When called with a
  prefix all file chunks from the header to the end of the file.  See also
  `difftastic-hide-chunk' and `difftastic=show-chunk'.
- `difftastic-git-diff-range' - transform `ARGS' for difftastic and show
  the result of `git diff ARGS REV-OR-RANGE -- FILES' with `difftastic'.


Customization
=============

Face Customization
~~~~~~~~~~~~~~~~~~

You can customize the appearance of `difftastic' output by adjusting the
faces used for highlighting.  To customize a faces, use the following code
snippet in your configuration:

;; Customize faces used to display difftastic output.
(setq difftastic-normal-colors-vector
  (vector
   ;; use black face from `ansi-color'
   (aref ansi-color-normal-colors-vector 0)
   ;; use face for removed marker from `difftastic'
   (aref difftastic-normal-colors-vector 1)
   ;; use face for added marker from `difftastic'
   (aref difftastic-normal-colors-vector 2)
   'my-section-face
   'my-comment-face
   'my-string-face
   'my-warning-face
   ;; use white face from `ansi-color'
   (aref ansi-color-normal-colors-vector 7)))

;; Customize highlight faces
(setq difftastic-highlight-alist
  `((,(aref difftastic-normal-colors-vector 2) . my-added-highlight)
    (,(aref difftastic-normal-colors-vector 1) . my-removed-highlight)))

;; Disable highlight faces (use difftastic's default)
(setq difftastic-highlight-alist nil)


Window management
~~~~~~~~~~~~~~~~~

The `difftastic' relies on the `difft' command line tool to produce an
output that can be displayed in an Emacs buffer window.  In short: it runs
the `difft', converts ANSI codes into user defined colors and displays it
in window.  The `difft' can be instructed with a hint to help it produce a
content that can fit into user output, by specifying a requested width.
However, the latter is not always respected.

The `difftastic' provides a few variables to let you customize these
aspects of interaction with `difft':
- `difftastic-requested-window-width-function' - this function is called
  for a first (i.e., not a rerun) call to `difft'.  It shall return the
  requested width of the output.  For example this can be a half of a
  current frame (or a window) if the output is meant to be presented side
  by side.
- `difftastic-rerun-requested-window-width-function' - this function is
  called for a rerun (i.e., not a first) call to `difft'.  It shall return
  requested window width of the output.  For example this can be a current
  window width if the output is meant to fill the whole window.
- `difftastic-display-buffer-function' - this function is called after a
  first call to `difft'.  It is meant to select an appropriate Emacs
  mechanism to display the `difft' output.


Contributing
============

Contributions are welcome! Feel free to submit issues and pull requests on
the [GitHub repository].


[GitHub repository] <https://github.com/pkryger/difftastic.el>

Testing
~~~~~~~

When creating a pull request make sure all tests in
<file:test/difftastic.t.el> are passing.  When adding a new functionality,
please strive to add tests for it as well.

To run tests:
- open the <file:test/difftastic.t.el>
- type `M-x eval-buffer <RET>'
- type `M-x ert <RET> t <RET>'
