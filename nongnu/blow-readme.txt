		    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
		     BLOW - BLOW AWAY MODE LIGHTERS
		    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


Table of Contents
─────────────────

1. Usage
2. Installation
.. 1. Quelpa
.. 2. Straight.el
.. 3. Manual


Mode lighters are indicator that make us aware that a mode is enabled.
This is helpful, but when there are too many of them, it becomes a
problem, because often lighters with the important information gets
truncated due to the non-important lighters.  So we blow them, and they
are usually the lighters of the important, perhaps indispensible, modes
for you, so that you can see and focus on what matters.


1 Usage
═══════

  Using this package is simple:

  ┌────
  │ ;; Enable `blow-mode'.
  │ (blow-mode +1)
  │ 
  │ ;; Blow the lighter of `gcmh-mode'.
  │ (blow 'gcmh-mode)
  │ 
  │ ;; Change the lighter of `eldoc-mode' to `ELispDoc' (with a preceding
  │ ;; space to differentiate from other lighters.
  │ (blow 'eldoc-mode " ElispDoc")
  │ 
  │ ;; Show the lighter of `paredit-mode' unless the major mode is
  │ ;; `emacs-lisp-mode'.
  │ (blow 'paredit-mode '(:eval (unless (eq major-mode 'emacs-lisp-mode)
  │ 			      (blow-original-lighter 'paredit-mode))))
  │ 
  │ ;; Revert `eldoc-mode' lighter.
  │ (blow-revert 'eldoc-mode)
  └────

  Or, if you prefer customizing variable, set `blow-mode-list' from
  custom, or customize it from your init file like the following:

  ┌────
  │ ;; You can also use `setq', but you would need to reenable `blow-mode'
  │ ;; for changes to effect.
  │ (customize-set-variable
  │  blow-mode-list
  │ 
  │  ;; Blow the lighter of `gcmh-mode'.
  │  '((gcmh-mode nil)
  │ 
  │    ;; Change the lighter of `eldoc-mode' to `ELispDoc' (with a
  │    ;; preceding space to differentiate from other lighters.
  │    (eldoc-mode " ElispDoc")
  │ 
  │    ;; Show the lighter of `paredit-mode' unless the major mode is
  │    ;; `emacs-lisp-mode'.
  │    (paredit-mode (:eval (unless (eq major-mode 'emacs-lisp-mode)
  │ 			  (blow-original-lighter 'paredit-mode))))))
  │ 
  │ ;; Enable mode to take effect.
  │ (blow-mode +1)
  └────


2 Installation
══════════════

  `blow' isn't available on any ELPA right now.  So, you have to follow
  one of the following methods:


2.1 Quelpa
──────────

  ┌────
  │ (quelpa '(blow :fetcher git
  │ 	       :url "https://codeberg.org/akib/emacs-blow.git"))
  └────


2.2 Straight.el
───────────────

  ┌────
  │ (straight-use-package
  │  '(blow :type git :repo "https://codeberg.org/akib/emacs-blow.git"))
  └────


2.3 Manual
──────────

  Download the `blow.el' file and put it in your `load-path'.
