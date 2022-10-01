; lsp-mode client for LaTeX.
; How to Use?
  - First, you have to install ~texlab~.
    Please install this [[https://github.com/latex-lsp/texlab/releases][here]].
  - Next, you should make ~lsp-mode~ available.  See [[https://github.com/emacs-lsp/lsp-mode][lsp-mode]].
  - Now, you can use Language Server Protocol (LSP) on (la)tex-mode or yatex-mode just to evaluate this:


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

  ;; For bibtex
  (with-eval-after-load "bibtex"
   (add-hook 'bibtex-mode-hook 'lsp))

; Build
;; ~lsp-latex-build~
   Build .tex files with texlab.
   It use latexmk by default, so add .latexmkrc if you want to customize
   latex commands or options.  You can change build command and option to other
   such as `make`, by changing ~lsp-latex-build-executable~ and
   ~lsp-latex-build-args~.

   This command build asynchronously by default, while it build synchronously
   with prefix argument(C-u).
; Forward/inverse search
  Forward search and inverse search are available.  See also [[https://github.com/latex-lsp/texlab/blob/master/docs/previewing.md][document of texlab]].

;; Forward search
   You can move from Emacs to current position on pdf viewer
   by the function ~lsp-latex-forward-search~.
   To use, you should set ~lsp-latex-forward-search-executable~ and
   ~lsp-latex-forward-search-args~ according to your pdf viewer.

   You can see [[https://github.com/latex-lsp/texlab/blob/master/docs/previewing.md][document of texlab]], but you should replace some VSCode words with Emacs words.
   ~latex.forwardSearch.executable~ should be replaced with  ~lsp-latex-forward-search-executable~,
   and ~latex.forwardSearch.args~ with ~lsp-latex-forward-search-args~.  You should setq each variable
   instead of writing like json, and vector in json is replaced to list in Emacs Lisp.  So the json:

     {
            "texlab.forwardSearch.executable": "FavoriteViewer",
            "texlab.forwardSearch.args": [ "%p", "%f", "%l" ]
     }

   should be replaced with the Emacs Lisp code:

     (setq lsp-latex-forward-search-executable "FavoriteViewer")
     (setq lsp-latex-forward-search-args '("%p" "%f" "%l"))


   In ~lsp-latex-forward-search-args~, the string "%f" is replaced with
   "The path of the current TeX file", "%p" with "The path of the current PDF file",
   "%l" with "The current line number", by texlab (see [[https://github.com/latex-lsp/texlab/blob/master/docs/options.md

   For example of SumatraPDF, write in init.el:

     (setq lsp-latex-forward-search-executable "C:/Users/{User}/AppData/Local/SumatraPDF/SumatraPDF.exe")
     (setq lsp-latex-forward-search-args '("-reuse-instance" "%p" "-forward-search" "%f" "%l"))

   while VSCode config with json (see [[https://github.com/latex-lsp/texlab/blob/master/docs/previewing.md

     {
       "texlab.forwardSearch.executable": "C:/Users/{User}/AppData/Local/SumatraPDF/SumatraPDF.exe",
       "texlab.forwardSearch.args": [
         "-reuse-instance",
         "%p",
         "-forward-search",
         "%f",
         "%l"
       ]
     }


   Then, you can jump to the current position on pdf viewer by command ~lsp-latex-forward-search~.

;; Inverse search
   You can go to the current position on Emacs from pdf viewer.
   Whatever pdf viewer you use, you should start Emacs server by writing in init.el:

     (server-start)

   Then, you can jump to line {{LINE-NUMBER}} in file named {{FILENAME}} with the command:

     emacsclient +{{LINE-NUMBER}} {{FILENAME}}

  {{LINE-NUMBER}} and {{FILENAME}} should be replaced with line number and filename you want
  to jump to.  Each pdf viewer can provide some syntax to replace.

  For example of SmatraPDF (see [[https://github.com/latex-lsp/texlab/blob/master/docs/previewing.md
  "Add the following line to your SumatraPDF settings file (Menu -> Settings -> Advanced Options):"

    InverseSearchCmdLine = C:\path\to\emacsclient.exe +%l %f

  Then, "You can execute the search by pressing Alt+DoubleClick in the PDF document".

;; Examples
   These examples are according to [[https://github.com/latex-lsp/texlab/blob/master/docs/previewing.md
   sentences are citation from [[https://github.com/latex-lsp/texlab/blob/master/docs/previewing.md
;;; SumatraPDF

        We highly recommend SumatraPDF on Windows
        because Adobe Reader locks the opened PDF file and will therefore prevent further builds.

;;;; Forward search
     Write to init.el:

       (setq lsp-latex-forward-search-executable "C:/Users/{User}/AppData/Local/SumatraPDF/SumatraPDF.exe")
       (setq lsp-latex-forward-search-args '("-reuse-instance" "%p" "-forward-search" "%f" "%l"))

;;;; Inverse Search

     Add the following line to your [[https://www.sumatrapdfreader.org/][SumatraPDF]] settings file (Menu -> Settings -> Advanced Options):


       InverseSearchCmdLine = C:\path\to\emacsclient.exe +%l "%f"


     You can execute the search by pressing `Alt+DoubleClick' in the PDF document.

;;; Evince

    The SyncTeX feature of [[https://wiki.gnome.org/Apps/Evince][Evince]] requires communication via D-Bus.
    In order to use it from the command line, install the [[https://github.com/latex-lsp/evince-synctex][evince-synctex]] script.

;;;; Forward search
     Write to init.el:

       (setq lsp-latex-forward-search-executable "evince-synctex")
       (setq lsp-latex-forward-search-args '("-f" "%l" "%p" "\"emacsclient +%l %f\""))

;;;; Inverse search

     The inverse search feature is already configured if you use `evince-synctex'.
     You can execute the search by pressing `Ctrl+Click' in the PDF document.

;;; Okular
;;;; Forward search
     Write to init.el:

       (setq lsp-latex-forward-search-executable "okular")
       (setq lsp-latex-forward-search-args '("--unique" "file:%p

;;;; Inverse search

     Change the editor of Okular (Settings -> Configure Okular... -> Editor)
     to "Custom Text Editor" and set the following command:


       emacsclient +%l "%f"

     You can execute the search by pressing `Shift+Click' in the PDF document.
;;; Zathura
;;;; Forward search
     Write to init.el:

       (setq lsp-latex-forward-search-executable "zathura")
       (setq lsp-latex-forward-search-args '("--synctex-forward" "%l:1:%f" "%p"))

;;;; Inverse search

     Add the following lines to your =~/.config/zathura/zathurarc= file:


       set synctex true
       set synctex-editor-command "emacsclient +%{line} %{input}"


     You can execute the search by pressing `Alt+Click' in the PDF document.

;;; qpdfview
;;;; Forward search
     Write to init.el:

       (setq lsp-latex-forward-search-executable "qpdfview")
       (setq lsp-latex-forward-search-args '("--unique" "%p

;;;; Inverse search

     Change the source editor setting (Edit -> Settings... -> Behavior -> Source editor) to:


       emacsclient +%2 "%1"


     and select a mouse button modifier (Edit -> Settings... -> Behavior -> Modifiers ->
     Mouse button modifiers -> Open in Source Editor)of choice.
     You can execute the search by pressing Modifier+Click in the PDF document.

;;; Skim

    We recommend [[https://skim-app.sourceforge.io/][Skim]] on macOS since it is the only native viewer that supports SyncTeX.
    Additionally, enable the "Reload automatically" setting in the Skim preferences
    (Skim -> Preferences -> Sync -> Check for file changes).

;;;; Forward search
     Write to init.el:

       (setq lsp-latex-forward-search-executable "/Applications/Skim.app/Contents/SharedSupport/displayline")
       (setq lsp-latex-forward-search-args '("%l" "%p" "%f"))

     "If you want Skim to stay in the background after executing the forward search,
     you can add the =-g= option to" `lsp-latex-forward-search-args'.
;;;; Inverse search
     Select Emacs preset "in the Skim preferences
     (Skim -> Preferences -> Sync -> PDF-TeX Sync support).
     You can execute the search by pressing `Shift+⌘+Click' in the PDF document."
;;; ~pdf-tools~ integration
    If you want to use forward search with ~pdf-tools~,
    follow the setting:

      ;; Start Emacs server
      (server-start)
      ;; Turn on SyncTeX on the build.
      ;; If you use `lsp-latex-build', it is on by default.
      ;; If not (for example, YaTeX or LaTeX-mode building system),
      ;; put to init.el like this:
      (setq tex-command "platex --synctex=1")

      ;; Setting for pdf-tools
      (setq lsp-latex-forward-search-executable "emacsclient")
      (setq lsp-latex-forward-search-args
            '("--eval"
              "(lsp-latex-forward-search-with-pdf-tools \"%f\" \"%p\" \"%l\")"))

    Inverse research is not provided by texlab,
    so please use ~pdf-sync-backward-search-mouse~.

