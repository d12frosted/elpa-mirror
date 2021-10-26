			    ━━━━━━━━━━━━━━━━
			     FLYMAKE-KONDOR
			    ━━━━━━━━━━━━━━━━


Table of Contents
─────────────────

1. MELPA
2. GitHub
3. Local
4. Note about Flymake


This package integrates clj-kondo a Clojure linter into Emacs'
Flymake. To use it get clj-kondo following [installation instructions];
then proceed with your preferred way of adding packages.


[installation instructions]
<https://github.com/borkdude/clj-kondo/blob/master/doc/install.md>


1 MELPA
═══════

  ┌────
  │ (use-package flymake-kondor
  │   :ensure t
  │   :hook (clojure-mode . flymake-kondor-setup))
  └────


2 GitHub
════════

  ┌────
  │ (el-get-bundle flymake-kondor
  │ 	       :url "https://raw.githubusercontent.com/turbo-cafe/flymake-kondor/master/flymake-kondor.el"
  │ 	       (add-hook 'clojure-mode-hook #'flymake-kondor-setup))
  └────


3 Local
═══════

  ┌────
  │ (add-to-list 'load-path "~/path/to/flymake-kondor")
  │ (require "flymake-kondor")
  │ (add-hook 'clojure-mode-hook #'flymake-kondor-setup)
  └────


4 Note about Flymake
════════════════════

  To start linting activate `M-x flymake-mode' in a Clojure buffer; even
  better assign hook and keys so you could navigate to the previous or
  next error in the buffer instantly.

  ┌────
  │ (use-package flymake
  │   :ensure nil
  │   :bind (([f8] . flymake-goto-next-error)
  │ 	 ([f7] . flymake-goto-prev-error))
  │   :hook (prog-mode . (lambda () (flymake-mode t)))
  │   :config (remove-hook 'flymake-diagnostic-functions #'flymake-proc-legacy-flymake))
  └────

  There is a [sister project] that integrates clj-kondo into Flycheck.


[sister project] <https://github.com/borkdude/flycheck-clj-kondo>
