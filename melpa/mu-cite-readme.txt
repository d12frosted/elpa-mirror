- How to use
  1. Bytecompile this file and copy it to the apropriate directory.
  2. Put the following lines in your ~/.emacs file:
     For EMACS 19 or later and XEmacs
	(autoload 'mu-cite-original "mu-cite" nil t)
	;; for all but message-mode
	(add-hook 'mail-citation-hook (function mu-cite-original))
	;; for message-mode only
	(setq message-cite-function (function mu-cite-original))
     For EMACS 18
	;; for all but mh-e
	(add-hook 'mail-yank-hooks (function mu-cite-original))
	;; for mh-e only
	(add-hook 'mh-yank-hooks (function mu-cite-original))
