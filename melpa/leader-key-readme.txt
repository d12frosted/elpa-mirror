Simple helper to add leader key functionality (e.g. for god-mode)

The idea is to replicate a vim/evil leader key concept, but be independent of
any other mode.  This has been developed and tested together with god-mode
but should work without it or even without any modal mode.  It works together
with which-key, but the dependency is optional.

With the configuration below we can do shortcuts like:

SPC x q       ;; quits Emacs
SPC p p       ;; opens projectile project list
SPC <left>    ;; moves to the left window
SPC m         ;; opens magit
SPC SPC       ;; starts selection
SPC x SPC     ;; starts rectangle selection
SPC q c       ;; (vdiff)-close-fold, only when major vdiff-mode active
SPC q c       ;; (rust-mode)-rust-compile, only when major rust-mode active

To configure (an example with god-mode):

(require 'which-key)                     ;; optional
(require 'leader-key)                    ;; only in case of no auto-loads

Define the main/root leader key that will trigger the leader map (make sure
the key is not bound to anything in situations we want it to trigger, in this
case when god-mode is active):

(setq leader-key-root-key "SPC")         ;; redundant, "SPC" is default
(with-eval-after-load 'god-mode
  (define-key god-local-mode-map (kbd leader-key-root-key) nil))

Configure the predicament that must be true for the leader-key to be
triggered.  Otherwise the key should fall back to its default function.  In
case of god-mode the below is a usable choice (activate when god-mode is
active or the buffer is read only):

(defun +leader-key-pred ()
  (or buffer-read-only
      god-local-mode))
(setq leader-key-pred #'+leader-key-pred)

Turn on the global minor mode:

(leader-key-mode t)

There are some major-modes that don't play well with leader, e.g. modes that
are marked as read only yet we need the leader key to do its original job.
One of such modes is vterm-mode.  To handle such cases add this mode to
exceptions:

(add-to-list 'leader-key-exempt-major-modes 'vterm-mode t)

There might also be some major-modes that can have our leader key already
mapped to something else and it conflicts with the leader-key in leader minor
map.  In such a case there is a helper function that will add our leader key
directly to such a map.  The second parameter for (leader-key-do-map) is
optional, it will basically do (eval-after-load 2ND-PARAM) for that
expression so we don't need to handle the loading order.

(leader-key-do-map 'custom-mode-map 'cus-edit)
(leader-key-do-map 'magit-blame-read-only-mode-map 'magit-blame)

An alternative configuration without any modal mode, where the leader key is
always active with a M-SPC shortcut:

(global-set-key (kbd "M-SPC") nil)       ;; so it doesn't conflict
(setq leader-key-root-key "M-SPC")
(setq leader-key-pred #'(lambda () t))   ;; always active
(leader-key-mode t)

There is no default for the map that will be triggered with leader-key, we
need to build it ourselves.  We can add whole submaps or just specific
functions.  Examples below:

(with-eval-after-load 'projectile
  (leader-key-define-key "p" projectile-command-map "projectile"))
(with-eval-after-load 'flycheck
  (leader-key-define-key "f" flycheck-command-map "flycheck"))

(leader-key-define-key "m" #'magit-status)
(leader-key-define-key "g" #'magit-file-dispatch)

(leader-key-define-key "<left>" #'window-jump-left)
(leader-key-define-key "<right>" #'window-jump-right)
(leader-key-define-key "<up>" #'window-jump-up)
(leader-key-define-key "<down>" #'window-jump-down)
(leader-key-define-key "0" #'+switch-window-then-delete-window-and-balance "delete-window")
(leader-key-define-key "1" #'switch-window-then-maximize "maximize")
(leader-key-define-key "2" #'+switch-window-then-split-below-switch-and-balance "split-below")
(leader-key-define-key "3" #'+switch-window-then-split-right-switch-and-balance "split-right")

(leader-key-define-key "SPC" #'set-mark-command)

(leader-key-describe-key "x" "emacs")       ;; optional, for which-key
(leader-key-define-key "x SPC" #'rectangle-mark-mode)
(leader-key-define-key "x ;" #'eval-expression)
(leader-key-define-key "x e" #'eval-last-sexp)
(leader-key-define-key "x p" #'paradox-list-packages)
(leader-key-define-key "x q" #'save-buffers-kill-terminal)
(leader-key-define-key "x s" #'save-some-buffers)
(leader-key-define-key "x w" #'write-file)
(leader-key-define-key "x x" #'execute-extended-command)

We can also have a sub map assigned that will be different dependent on the
currently active major mode.  This requires key and specific map assignment.

(setq leader-key-major-mode-key "q")        ;; redundant, "q" is default

The first parameter for (leader-key-major-mode-map) defines the major mode
map where our leader will be active (basically the major mode map assigned to
major mode), the second parameter is the map we want to have assigned under
leader key (might be provided externally, some packages provide usable maps,
might be built manually), the third parameter is optional, it basically does
(eval-after-load 3RD-PARAM) so we don't need to bother with loading order.

(leader-key-major-mode-map 'vdiff-mode-map 'vdiff-mode-prefix-map 'vdiff)

(setq rust-mode-map (make-sparse-keymap))   ;; optional, to clean up unusable default
(defvar rust-command-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "d") #'rust-dbg-wrap-or-unwrap)
    (define-key map (kbd "c") #'rust-compile)
    (define-key map (kbd "k") #'rust-check)
    (define-key map (kbd "t") #'rust-test)
    (define-key map (kbd "r") #'rust-run)
    (define-key map (kbd "l") #'rust-run-clippy)
    (define-key map (kbd "f") #'rust-format-buffer)
    (define-key map (kbd "n") #'rust-goto-format-problem)
    map))
(leader-key-major-mode-map 'rust-mode-map 'rust-command-map 'rust-mode)
