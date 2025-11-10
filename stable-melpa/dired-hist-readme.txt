dired-hist is a minor mode for Emacs that keeps track of visited
Dired buffers or paths and lets you go back and forwards across
them.  This is similar to the facility provided in Info, EWW and
in modern filemanagers.

This package require Emacs "26.1" actually, "27.1" reqqired by
`dired-hist-tl'

Personal note: I don't use it, I found that recentf package with
history of folders is better.

Commands:

`dired-hist-mode'       : Turn on Dired history tracking
`dired-hist-go-back'    : Go back in Dired history
`dired-hist-go-forward' : Go forward in Dired history

Features:

- supported for  two Dired modes: open  folder in new buffer  or in
  the same (dired-kill-when-opening-new-dired-buffer)
- if buffer is closed we remove his record from history
- history is global

Configuration:

(require 'dired-hist)
(add-hook 'dired-mode-hook #'dired-hist-mode)
(define-key dired-mode-map (kbd "l") #'dired-hist-go-back)
(define-key dired-mode-map (kbd "r") #'dired-hist-go-forward)

Consider instead "C-M-a" and "C-M-e".

Customization:

There are no customization options at this time.

There is alternative implementation based on tab-line-mode.
Pros: less code, history is visible in tabs
Cons:
- support for only ```dired-kill-when-opening-new-dired-buffer``` is nil.
- tab-line modified globally for now

Configuration for alternative implementation:

(require 'dired-hist-tl)
(add-hook 'dired-mode-hook #'dired-hist-tl-dired-mode-hook)
(define-key dired-mode-map (kbd "RET") #'dired-hist-tl-dired-find-file)
(global-set-key (kbd "l") #'tab-line-switch-to-prev-tab)
(global-set-key (kbd "r") #'tab-line-switch-to-next-tab)

How it works:

There are two stacks: with history and for Forward key.
When we navigate the history grows, when we press back button
we transfer last record from history to forward stack.
Forward button do reverse - transfer from forward stack back to
history.
          .-> |-| -- Back >
        -/    | |   \---     <--.
-- Open/      |-|       \----    \-- Forward
              | |            \---
              | |                \->
              |-|                    |-|
              | |                    | |
              |-|                    |-|
              | |                    | |
              +-+                    +-+
        For Back <           For Forward >

About two modes:
Dired have two modes `dired-kill-when-opening-new-dired-buffer':
1) create new buffer when visit folder
2) recreate buffer every time, to keep only one
In 1) we are moves in history is switching between buffers
In 2) we are sitching between directories in one buffer
When in 1) we go to a new directory we just add new item to
hist-stack.
When in 2) we go to a new directory we also clear forward-stack.

Special cases for nil `dired-kill-when-opening-new-dired-buffer':
- If buffer is closed then removed from history.
- When we change buffer manually history stay the same.
- if we changed manually buffer and go back we don't add it to
  stack.
Special case for t `dired-kill-when-opening-new-dired-buffer':
If two buffer opened: another will be deleted with
  `dired-hist-go-back' command at the end of the history stack by
  `find-alternate-file'.
