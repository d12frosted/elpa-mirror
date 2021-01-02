`annotate-depth-mode' annotates buffer if indentation depth is beyond threshold (see
`annotate-depth-threshold' which defaults to 5). An idle timer is started when entering the mode
and disabled when exiting it. The face `annotate-depth-face' is applied at indentation level and
to end-of-line for each line on or beyond threshold.

Usage:
(add-hook 'prog-mode-hook 'annotate-depth-mode)

The threshold can be fine-tuned for specific modes if necessary:
(add-hook 'annotate-depth-mode-hook
(lambda ()
(if (equal major-mode 'emacs-lisp-mode)
(setq-local annotate-depth-threshold 10)
(when (equal major-mode 'c++-mode)
(setq-local annotate-depth-threshold 4)))))
