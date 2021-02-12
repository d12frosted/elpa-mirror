
This file provides `git-time-metric-record', which records time with gtm. Essentially it calls `gtm record [options] <file_name>'.

Usage:
    M-x git-time-metric-record

    To automatically record time after saving:
    (Choose depending on your favorite mode.)

(eval-after-load 'js-mode
	'(add-hook 'js-mode-hook (lambda () (add-hook 'after-save-hook 'git-time-metric-record))))

(eval-after-load 'js2-mode
	'(add-hook 'js-mode-hook (lambda () (add-hook 'after-save-hook 'git-time-metric-record))))

    Or track all your files:

(add-hook 'after-save-hook 'git-time-metric-record)
