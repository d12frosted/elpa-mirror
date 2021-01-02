Defines a major mode for editing gnuplot scripts.  I wanted to keep
it simpler than other modes -- just syntax highlighting, indentation,
and a command to plot the file.

Some of this code is adapted from a more full-featured version by
Bruce Ravel (available here https://github.com/bruceravel/gnuplot-mode;
GPLv2).

Thanks to everyone, including Christopher Gilbreth and Ralph Möritz,
for sending suggestions, improvements, and fixes.

; Installation:

Use package.el. You'll need to add MELPA to your archives:

(require 'package)
(add-to-list 'package-archives
'("melpa" . "https://melpa.org/packages/") t)

Alternatively, you can just save this file and do the standard
(add-to-list 'load-path "/path/to/gnuplot-mode.el")

; Configuration:

If you installed this via `package.el', you should take advantage
of autoloading.  You can customize features using `defvar' and
`eval-after-load', as illustrated below:

;; specify the gnuplot executable (if other than "gnuplot")
(defvar gnuplot-program "/sw/bin/gnuplot")

;; set gnuplot arguments (if other than "-persist")
(defvar gnuplot-flags "-persist -pointsize 2")

;; if you want, add a mode hook.  e.g., the following turns on
;; spell-checking for strings and comments and automatically cleans
;; up whitespace on save.
(eval-after-load 'gnuplot-mode
'(add-hook 'gnuplot-mode-hook
(lambda ()
(flyspell-prog-mode)
(add-hook 'before-save-hook
'whitespace-cleanup nil t))))

If you installed this file manually, you probably don't want to
muck around with autoload commands.  Instead, add something like
the following to your .emacs:

(require 'gnuplot-mode)

;; specify the gnuplot executable (if other than "gnuplot")
(setq gnuplot-program "/sw/bin/gnuplot")

;; set gnuplot arguments (if other than "-persist")
(setq gnuplot-flags "-persist -pointsize 2")

;; if you want, add a mode hook.  e.g., the following turns on
;; spell-checking for strings and comments and automatically cleans
;; up whitespace on save.
(add-hook 'gnuplot-mode-hook
(lambda ()
(flyspell-prog-mode)
(add-hook 'before-save-hook
'whitespace-cleanup nil t)))
