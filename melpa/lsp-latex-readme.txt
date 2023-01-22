Table of Contents
_________________

1. lsp-mode client for LaTeX.
2. How to Use?
3. Variables
.. 1. `lsp-latex-texlab-executable'
.. 2. `lsp-latex-texlab-executable-argument-list'
.. 3. Others, provided by texlab server
4. Build
.. 1. `lsp-latex-build'
5. Forward/inverse search
.. 1. Forward search
.. 2. Inverse search
.. 3. Examples
..... 1. SumatraPDF
..... 2. Evince
..... 3. Okular
..... 4. Zathura
..... 5. qpdfview
..... 6. Skim
..... 7. `pdf-tools' integration
6. License


[https://img.shields.io/github/tag/ROCKTAKEY/lsp-latex.svg?style=flat-square]
[https://img.shields.io/github/license/ROCKTAKEY/lsp-latex.svg?style=flat-square]
[https://img.shields.io/github/actions/workflow/status/ROCKTAKEY/lsp-latex/CI.yml.svg?style=flat-square]
[file:https://melpa.org/packages/lsp-latex-badge.svg]


[https://img.shields.io/github/tag/ROCKTAKEY/lsp-latex.svg?style=flat-square]
<https://github.com/ROCKTAKEY/lsp-latex>

[https://img.shields.io/github/license/ROCKTAKEY/lsp-latex.svg?style=flat-square]
<file:LICENSE>

[https://img.shields.io/github/actions/workflow/status/ROCKTAKEY/lsp-latex/CI.yml.svg?style=flat-square]
<https://github.com/ROCKTAKEY/lsp-latex/actions>

[file:https://melpa.org/packages/lsp-latex-badge.svg]
<https://melpa.org/#/lsp-latex>


1 lsp-mode client for LaTeX.
============================


2 How to Use?
=============

  - First, you have to install `texlab'.  Please install this [here].
  - Next, you should make `lsp-mode' available.  See [lsp-mode].
  - Now, you can use Language Server Protocol (LSP) on (la)tex-mode or
    yatex-mode just to evaluate this:

  ,----
  |  1  (add-to-list 'load-path "/path/to/lsp-latex")
  |  2  (require 'lsp-latex)
  |  3  ;; "texlab" must be located at a directory contained in `exec-path'.
  |  4  ;; If you want to put "texlab" somewhere else,
  |  5  ;; you can specify the path to "texlab" as follows:
  |  6  ;; (setq lsp-latex-texlab-executable "/path/to/texlab")
  |  7
  |  8  (with-eval-after-load "tex-mode"
  |  9   (add-hook 'tex-mode-hook 'lsp)
  | 10   (add-hook 'latex-mode-hook 'lsp))
  | 11
  | 12  ;; For YaTeX
  | 13  (with-eval-after-load "yatex"
  | 14   (add-hook 'yatex-mode-hook 'lsp))
  | 15
  | 16  ;; For bibtex
  | 17  (with-eval-after-load "bibtex"
  | 18   (add-hook 'bibtex-mode-hook 'lsp))
  `----


[here] <https://github.com/latex-lsp/texlab/releases>

[lsp-mode] <https://github.com/emacs-lsp/lsp-mode>


3 Variables
===========

3.1 `lsp-latex-texlab-executable'
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  Where texlab server located.


3.2 `lsp-latex-texlab-executable-argument-list'
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  Argument list passed to texlab server.


3.3 Others, provided by texlab server
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  These variables are connected to texlab configuration variables.  See
  also texlab [documentation].
   Custom variable in Emacs                  Configuration provided by texlab
  -------------------------------------------------------------------------------
   lsp-latex-root-directory                  texlab.rootDirectory
   lsp-latex-build-executable                texlab.build.executable
   lsp-latex-build-args                      texlab.build.args
   lsp-latex-build-aux-directory             texlab.build.outputDirectory
   lsp-latex-build-forward-search-after      texlab.build.forwardSearchAfter
   lsp-latex-build-on-save                   texlab.build.onSave
   lsp-latex-forward-search-executable       texlab.forwardSearch.executable
   lsp-latex-forward-search-args             texlab.forwardSearch.args
   lsp-latex-chktex-on-edit                  texlab.chktex.onEdit
   lsp-latex-chktex-on-open-and-save         texlab.chktex.onOpenAndSave
   lsp-latex-diagnostics-delay               texlab.diagnosticsDelay
   lsp-latex-diagnostics-allowed-patterns    texlab.diagnostics.allowedPatterns
   lsp-latex-diagnostics-ignored-patterns    texlab.diagnostics.ignoredPatterns
   lsp-latex-bibtex-formatter-line-length    texlab.formatterLineLength
   lsp-latex-bibtex-formatter                texlab.bibtexFormatter
   lsp-latex-latex-formatter                 texlab.latexFormatter
   lsp-latex-latexindent-local               texlab.latexindent.local
   lsp-latex-latexindent-modify-line-breaks  texlab.latexindent.modifyLineBreaks


[documentation]
<https://github.com/latex-lsp/texlab/blob/master/docs/options.md>


4 Build
=======

4.1 `lsp-latex-build'
~~~~~~~~~~~~~~~~~~~~~

  Build .tex files with texlab.  It use latexmk by default, so add
  .latexmkrc if you want to customize latex commands or options.  You can
  change build command and option to other such as `make`, by changing
  `lsp-latex-build-executable' and `lsp-latex-build-args'.

  This command build asynchronously by default, while it build
  synchronously with prefix argument(C-u).


5 Forward/inverse search
========================

  Forward search and inverse search are available.  See also [document of
  texlab].


[document of texlab]
<https://github.com/latex-lsp/texlab/blob/master/docs/previewing.md>

5.1 Forward search
~~~~~~~~~~~~~~~~~~

  You can move from Emacs to current position on pdf viewer by the
  function `lsp-latex-forward-search'.  To use, you should set
  `lsp-latex-forward-search-executable' and
  `lsp-latex-forward-search-args' according to your pdf viewer.

  You can see [document of texlab], but you should replace some VSCode
  words with Emacs words.  `latex.forwardSearch.executable' should be
  replaced with `lsp-latex-forward-search-executable', and
  `latex.forwardSearch.args' with `lsp-latex-forward-search-args'.  You
  should setq each variable instead of writing like json, and vector in
  json is replaced to list in Emacs Lisp.  So the json:
  ,----
  | {
  |        "texlab.forwardSearch.executable": "FavoriteViewer",
  |        "texlab.forwardSearch.args": [ "%p", "%f", "%l" ]
  | }
  `----
  should be replaced with the Emacs Lisp code:
  ,----
  | (setq lsp-latex-forward-search-executable "FavoriteViewer")
  | (setq lsp-latex-forward-search-args '("%p" "%f" "%l"))
  `----

  In `lsp-latex-forward-search-args', the string "%f" is replaced with
  "The path of the current TeX file", "%p" with "The path of the current
  PDF file", "%l" with "The current line number", by texlab (see
  [here]).

  For example of SumatraPDF, write in init.el:
  ,----
  | (setq lsp-latex-forward-search-executable "C:/Users/{User}/AppData/Local/SumatraPDF/SumatraPDF.exe")
  | (setq lsp-latex-forward-search-args '("-reuse-instance" "%p" "-forward-search" "%f" "%l"))
  `----
  while VSCode config with json (see [document of texlab]) is:
  ,----
  | {
  |   "texlab.forwardSearch.executable": "C:/Users/{User}/AppData/Local/SumatraPDF/SumatraPDF.exe",
  |   "texlab.forwardSearch.args": [
  |     "-reuse-instance",
  |     "%p",
  |     "-forward-search",
  |     "%f",
  |     "%l"
  |   ]
  | }
  `----

  Then, you can jump to the current position on pdf viewer by command
  `lsp-latex-forward-search'.


[document of texlab]
<https://github.com/latex-lsp/texlab/blob/master/docs/previewing.md>

[here]
<https://github.com/latex-lsp/texlab/blob/master/docs/options.md#texlabforwardsearchargs>

[document of texlab]
<https://github.com/latex-lsp/texlab/blob/master/docs/previewing.md#forward-search>


5.2 Inverse search
~~~~~~~~~~~~~~~~~~

  You can go to the current position on Emacs from pdf viewer.  Whatever
  pdf viewer you use, you should start Emacs server by writing in
  init.el:
  ,----
  | (server-start)
  `----
  Then, you can jump to line {{LINE-NUMBER}} in file named {{FILENAME}}
  with the command:
  ,----
  | 1  emacsclient +{{LINE-NUMBER}} {{FILENAME}}
  `----
  {{LINE-NUMBER}} and {{FILENAME}} should be replaced with line number
  and filename you want to jump to.  Each pdf viewer can provide some
  syntax to replace.

  For example of SmatraPDF (see [document of texlab]), "Add the
  following line to your SumatraPDF settings file (Menu -> Settings ->
  Advanced Options):"
  ,----
  | 1  InverseSearchCmdLine = C:\path\to\emacsclient.exe +%l %f
  `----
  Then, "You can execute the search by pressing Alt+DoubleClick in the
  PDF document".


[document of texlab]
<https://github.com/latex-lsp/texlab/blob/master/docs/previewing.md#inverse-search>


5.3 Examples
~~~~~~~~~~~~

  These examples are according to [document of texlab].  Especially,
  quoted or double-quoted sentences are citation from [document of
  texlab].


[document of texlab]
<https://github.com/latex-lsp/texlab/blob/master/docs/previewing.md#inverse-search>

5.3.1 SumatraPDF
----------------

        We highly recommend SumatraPDF on Windows because Adobe
        Reader locks the opened PDF file and will therefore
        prevent further builds.


* 5.3.1.1 Forward search

  Write to init.el:
  ,----
  | (setq lsp-latex-forward-search-executable "C:/Users/{User}/AppData/Local/SumatraPDF/SumatraPDF.exe")
  | (setq lsp-latex-forward-search-args '("-reuse-instance" "%p" "-forward-search" "%f" "%l"))
  `----


* 5.3.1.2 Inverse Search

        Add the following line to your [SumatraPDF] settings file
        (Menu -> Settings -> Advanced Options):
  ,----
  | 1  InverseSearchCmdLine = C:\path\to\emacsclient.exe +%l "%f"
  `----
        You can execute the search by pressing `Alt+DoubleClick'
        in the PDF document.


  [SumatraPDF] <https://www.sumatrapdfreader.org/>


5.3.2 Evince
------------

        The SyncTeX feature of [Evince] requires communication via
        D-Bus.  In order to use it from the command line, install
        the [evince-synctex] script.


[Evince] <https://wiki.gnome.org/Apps/Evince>

[evince-synctex] <https://github.com/latex-lsp/evince-synctex>

* 5.3.2.1 Forward search

  Write to init.el:
  ,----
  | (setq lsp-latex-forward-search-executable "evince-synctex")
  | (setq lsp-latex-forward-search-args '("-f" "%l" "%p" "\"emacsclient +%l %f\""))
  `----


* 5.3.2.2 Inverse search

        The inverse search feature is already configured if you
        use `evince-synctex'.  You can execute the search by
        pressing `Ctrl+Click' in the PDF document.


5.3.3 Okular
------------

* 5.3.3.1 Forward search

  Write to init.el:
  ,----
  | (setq lsp-latex-forward-search-executable "okular")
  | (setq lsp-latex-forward-search-args '("--unique" "file:%p#src:%l%f"))
  `----


* 5.3.3.2 Inverse search

        Change the editor of Okular (Settings -> Configure
        Okular... -> Editor) to "Custom Text Editor" and set the
        following command:
  ,----
  | emacsclient +%l "%f"
  `----
  You can execute the search by pressing `Shift+Click' in the PDF
  document.


5.3.4 Zathura
-------------

* 5.3.4.1 Forward search

  Write to init.el:
  ,----
  | (setq lsp-latex-forward-search-executable "zathura")
  | (setq lsp-latex-forward-search-args '("--synctex-forward" "%l:1:%f" "%p"))
  `----


* 5.3.4.2 Inverse search

        Add the following lines to your
        `~/.config/zathura/zathurarc' file:
  ,----
  | 1  set synctex true
  | 2  set synctex-editor-command "emacsclient +%{line} %{input}"
  `----
        You can execute the search by pressing `Alt+Click' in the
        PDF document.


5.3.5 qpdfview
--------------

* 5.3.5.1 Forward search

  Write to init.el:
  ,----
  | (setq lsp-latex-forward-search-executable "qpdfview")
  | (setq lsp-latex-forward-search-args '("--unique" "%p#src:%f:%l:1"))
  `----


* 5.3.5.2 Inverse search

        Change the source editor setting (Edit -> Settings... ->
        Behavior -> Source editor) to:
  ,----
  | 1  emacsclient +%2 "%1"
  `----
        and select a mouse button modifier (Edit -> Settings... ->
        Behavior -> Modifiers -> Mouse button modifiers -> Open in
        Source Editor)of choice.  You can execute the search by
        pressing Modifier+Click in the PDF document.


5.3.6 Skim
----------

        We recommend [Skim] on macOS since it is the only native
        viewer that supports SyncTeX.  Additionally, enable the
        "Reload automatically" setting in the Skim preferences
        (Skim -> Preferences -> Sync -> Check for file changes).


[Skim] <https://skim-app.sourceforge.io/>

* 5.3.6.1 Forward search

  Write to init.el:
  ,----
  | (setq lsp-latex-forward-search-executable "/Applications/Skim.app/Contents/SharedSupport/displayline")
  | (setq lsp-latex-forward-search-args '("%l" "%p" "%f"))
  `----
  "If you want Skim to stay in the background after executing the
  forward search, you can add the `-g' option to"
  `lsp-latex-forward-search-args'.


* 5.3.6.2 Inverse search

  Select Emacs preset "in the Skim preferences (Skim -> Preferences ->
  Sync -> PDF-TeX Sync support).  You can execute the search by pressing
  `Shift+⌘+Click' in the PDF document."


5.3.7 `pdf-tools' integration
-----------------------------

  If you want to use forward search with `pdf-tools', follow the
  setting:
  ,----
  | ;; Start Emacs server
  | (server-start)
  | ;; Turn on SyncTeX on the build.
  | ;; If you use `lsp-latex-build', it is on by default.
  | ;; If not (for example, YaTeX or LaTeX-mode building system),
  | ;; put to init.el like this:
  | (setq tex-command "platex --synctex=1")
  |
  | ;; Setting for pdf-tools
  | (setq lsp-latex-forward-search-executable "emacsclient")
  | (setq lsp-latex-forward-search-args
  |       '("--eval"
  |         "(lsp-latex-forward-search-with-pdf-tools \"%f\" \"%p\" \"%l\")"))
  `----
  Inverse research is not provided by texlab, so please use
  `pdf-sync-backward-search-mouse'.


6 License
=========

  This package is licensed by GPLv3. See [LICENSE].


[LICENSE] <file:LICENSE>
