; lsp-mode client for LaTeX.
; How to Use?
  - First, you have to install ~texlab~.
    Please install this from https://github.com/latex-lsp/texlab/releases .
  - Next, you should make ~lsp-mode~ available.
    See https://github.com/emacs-lsp/lsp-mode.
  - Now, you can use Language Server Protocol (LSP) on (la)tex-mode or
    yatex-mode just to evaluate this:

  (add-to-list 'load-path "/path/to/lsp-latex")
  (require 'lsp-latex)
  ;; "texlab" must be located at a directory contained in `exec-path'.
  ;; If you want to put "texlab" somewhere else,
  ;; you can specify the path to "texlab" as follows:
  ;; (setq lsp-latex-texlab-executable "/path/to/texlab")

  (with-eval-after-load "tex-mode"
   (add-hook 'tex-mode-hook 'lsp)
   (add-hook 'latex-mode-hook 'lsp))

  ;; For YaTeX
  (with-eval-after-load "yatex"
   (add-hook 'yatex-mode-hook 'lsp))

; Functions
;; ~lsp-latex-build~
   Build .tex files with texlab.
   It use latexmk internally, so add .latexmkrc if you want to customize
   build commands or options.

   This command build asynchronously by default, while it build synchronously
   with prefix argument(C-u).
; Note
  In this package, you can use even texlab v0.4.2 or older, written with Java,
  though it is not recommended.  If you want to use them, you can write like:

  ;; Path to Java executable.  If it is added to environmental PATH,
  ;; you don't have to write this.
  (setq lsp-latex-java-executable "/path/to/java")

  ;; "texlab.jar" must be located at a directory contained in `exec-path'
  ;; "texlab" must be located at a directory contained in `exec-path'.
  (setq lsp-latex-texlab-jar-file 'search-from-exec-path)
  ;; If you want to put "texlab.jar" somewhere else,
  ;; you can specify the path to "texlab.jar" as follows:
  ;; (setq lsp-latex-texlab-jar-file "/path/to/texlab.jar")

; License
  This package is licensed by GPLv3. See the file "LICENSE".
