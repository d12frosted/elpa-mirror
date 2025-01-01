Table of Contents
_________________

1. lsp-mode client for Texlab.
2. How to Use?
3. Variables
.. 1. `lsp-latex-texlab-executable'
.. 2. `lsp-latex-texlab-executable-argument-list'
.. 3. Others, provided by texlab server
4. Build
.. 1. `lsp-latex-build'
5. Workspace commands
.. 1. `lsp-latex-clean-auxiliary'
.. 2. `lsp-latex-clean-artifacts'
.. 3. `lsp-latex-change-environment'
.. 4. `lsp-latex-find-environments'
..... 1. `lsp-latex-complete-environment'
.. 5. `lsp-latex-show-dependency-graph'
.. 6. `lsp-latex-cancel-build'
6. Commands with `lsp-latex-complete-environment'
.. 1. `lsp-latex-goto-environment'
.. 2. `lsp-latex-select-and-change-environment'
7. Forward/inverse search
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
8. License


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


1 lsp-mode client for Texlab.
=============================

  While `lsp-tex.el', included by [lsp-mode], provides minimal setting
  for [Texlab], `lsp-latex.el' provides full features of [Texlab]
  v5.21.0.


[lsp-mode] <https://github.com/emacs-lsp/lsp-mode>

[Texlab] <https://github.com/latex-lsp/texlab>


2 How to Use?
=============

  - First, you have to install Texlab.  Please install this [here].
  - Next, you should make `lsp-mode' available.  See [lsp-mode].
  - Now, you can use Language Server Protocol (LSP) on (la)tex-mode or
    yatex-mode just to evaluate this:

  ,----
  |  1  (add-to-list 'load-path "/path/to/lsp-latex")
  |  2  (require 'lsp-latex)
  |  3  ;; "texlab" executable must be located at a directory contained in `exec-path'.
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

  Where Texlab server executable located.


3.2 `lsp-latex-texlab-executable-argument-list'
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  Argument list passed to Texlab server.


3.3 Others, provided by texlab server
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  These variables are connected to Texlab configuration variables.  See
  also [Texlab official wiki].
   Custom variable in Emacs                          Configuration provided by Texlab
  -----------------------------------------------------------------------------------------------
   lsp-latex-build-executable                        texlab.build.executable
   lsp-latex-build-args                              texlab.build.args
   lsp-latex-build-forward-search-after              texlab.build.forwardSearchAfter
   lsp-latex-build-on-save                           texlab.build.onSave
   lsp-latex-build-use-file-list                     texlab.build.useFileList
   lsp-latex-build-aux-directory                     texlab.build.auxDirectory
   lsp-latex-build-log-directory                     texlab.build.logDirectory
   lsp-latex-build-pdf-directory                     texlab.build.pdfDirectory
   lsp-latex-forward-search-executable               texlab.forwardSearch.executable
   lsp-latex-forward-search-args                     texlab.forwardSearch.args
   lsp-latex-chktex-additional-args                  texlab.chktex.additionalArgs
   lsp-latex-chktex-on-open-and-save                 texlab.chktex.onOpenAndSave
   lsp-latex-chktex-on-edit                          texlab.chktex.onEdit
   lsp-latex-diagnostics-delay                       texlab.diagnosticsDelay
   lsp-latex-diagnostics-allowed-patterns            texlab.diagnostics.allowedPatterns
   lsp-latex-diagnostics-ignored-patterns            texlab.diagnostics.ignoredPatterns
   lsp-latex-symbol-allowed-patterns                 texlab.symbol.allowedPatterns
   lsp-latex-symbol-ignored-patterns                 texlab.symbol.ignoredPatterns
   lsp-latex-bibtex-formatter-line-length            texlab.formatterLineLength
   lsp-latex-bibtex-formatter                        texlab.bibtexFormatter
   lsp-latex-latex-formatter                         texlab.latexFormatter
   lsp-latex-latexindent-local                       texlab.latexindent.local
   lsp-latex-latexindent-modify-line-breaks          texlab.latexindent.modifyLineBreaks
   lsp-latex-latexindent-replacement                 texlab.latexindent.replacement
   lsp-latex-completion-matcher                      texlab.completion.matcher
   lsp-latex-inlay-hints-label-definitions           texlab.inlayHints.labelDefinitions
   lsp-latex-inlay-hints-label-references            texlab.inlayHints.labelReferences
   lsp-latex-inlay-hints-max-length                  texlab.inlayHints.maxLength
   lsp-latex-experimental-math-environments          texlab.experimental.mathEnvironments
   lsp-latex-experimental-enum-environments          texlab.experimental.enumEnvironments
   lsp-latex-experimental-verbatim-environments      texlab.experimental.verbatimEnvironments
   lsp-latex-experimental-citation-commands          texlab.experimental.citationCommands
   lsp-latex-experimental-label-reference-commands   texlab.experimental.labelReferenceCommands
   lsp-latex-experimental-label-definition-commands  texlab.experimental.labelDefinitionCommands
   lsp-latex-experimental-label-reference-prefixes   texlab.experimental.labelReferencePrefixes
   lsp-latex-experimental-label-definition-prefixes  texlab.experimental.labelDefinitionPrefixes


[Texlab official wiki]
<https://github.com/latex-lsp/texlab/wiki/Configuration>


4 Build
=======

4.1 `lsp-latex-build'
~~~~~~~~~~~~~~~~~~~~~

  Request texlab to build `.tex' files.  It use [`latexmk'] by default,
  so add `.latexmkrc' if you want to customize latex commands or
  options.  You can change build command and option to other such as
  `make', by changing `lsp-latex-build-executable' and
  `lsp-latex-build-args'.

  This command build asynchronously by default, while it build
  synchronously with prefix argument(`C-u').


[`latexmk'] <https://personal.psu.edu/~jcc8/software/latexmk/>


5 Workspace commands
====================

  These commands are connected to Texlab Workspace commands.  See also
  [Texlab official wiki].

   Custom variable in Emacs         Configuration provided by Texlab
  -------------------------------------------------------------------
   lsp-latex-clean-auxiliary        texlab.cleanAuxiliary
   lsp-latex-clean-artifacts        texlab.cleanArtifacts
   lsp-latex-change-environment     texlab.changeEnvironment
   lsp-latex-find-environments      texlab.findEnvironments
   lsp-latex-show-dependency-graph  texlab.showDependencyGraph
   lsp-latex-cancel-build           texlab.cancelBuild


[Texlab official wiki]
<https://github.com/latex-lsp/texlab/wiki/Workspace-commands>

5.1 `lsp-latex-clean-auxiliary'
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  This command removes LaTeX auxiliary files.  It will run `latexmk -c'
  in the project.


5.2 `lsp-latex-clean-artifacts'
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  This command removes LaTeX auxiliary files and artifacts It will run
  `latexmk -C' in the project.


5.3 `lsp-latex-change-environment'
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  This command replaces enviroment name to NEW-NAME in current position.
  This edits most-inner environment containing the current position.


5.4 `lsp-latex-find-environments'
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  This function get list of environments containing the current point.
  Each element of the list is `lsp-latex-environment-location' instance.
  See the docstring of `lsp-latex-environment-location'.


5.4.1 `lsp-latex-complete-environment'
--------------------------------------

  This function reads environment name from minibuffer and returns
  `lsp-latex-environment-location' instance.

  It takes three arguments, `BUFFER', `POINT', `PROMPT'.  `PROMPT' is
  used as prompt for `consult--read', which is wrapper of
  `completing-read'.  `BUFFER' and `POINT' specify basis to find
  environments.


5.5 `lsp-latex-show-dependency-graph'
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  Show dependency graph written by DOT format.  [`graphviz-dot-mode'] is
  needed if you needs syntax highlights or a graphical image.


[`graphviz-dot-mode'] <https://ppareit.github.io/graphviz-dot-mode/>


5.6 `lsp-latex-cancel-build'
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  This command request Texlab to cancel the proceeding build.


6 Commands with `lsp-latex-complete-environment'
================================================

  `lsp-latex-find-environments', which is interface for
  `texlab.FindEnvironments', does nothing but returns list of
  environments.  So this package provide some additional commands to
  utilize it.


6.1 `lsp-latex-goto-environment'
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  Go to selected environment containing the current point.


6.2 `lsp-latex-select-and-change-environment'
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  Change name of selected environment to NEW-NAME.


7 Forward/inverse search
========================

  Forward search and inverse search are available.  See also [Texlab
  official wiki].


[Texlab official wiki]
<https://github.com/latex-lsp/texlab/wiki/Previewing>

7.1 Forward search
~~~~~~~~~~~~~~~~~~

  You can move from Emacs to current position on pdf viewer by the
  function `lsp-latex-forward-search'.  To use, you should set
  `lsp-latex-forward-search-executable' and
  `lsp-latex-forward-search-args' according to your pdf viewer.

  You can see [Texlab official wiki], but you should replace some VSCode
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
  PDF file", "%l" with "The current line number", by Texlab (see
  [Forward search arg section in Texlab official wiki]).

  For example of SumatraPDF, write in init.el:
  ,----
  | (setq lsp-latex-forward-search-executable "C:/Users/{User}/AppData/Local/SumatraPDF/SumatraPDF.exe")
  | (setq lsp-latex-forward-search-args '("-reuse-instance" "%p" "-forward-search" "%f" "%l"))
  `----
  while VSCode config with json (see [Texlab official wiki]) is:
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


[Texlab official wiki]
<https://github.com/latex-lsp/texlab/wiki/Previewing>

[Forward search arg section in Texlab official wiki]
<https://github.com/latex-lsp/texlab/wiki/Configuration#texlabforwardsearchargs>

[Texlab official wiki]
<https://github.com/latex-lsp/texlab/wiki/Previewing#forward-search>


7.2 Inverse search
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

  For example of SmatraPDF (see [Texlab official wiki]), "Add the
  following line to your SumatraPDF settings file (Menu -> Settings ->
  Advanced Options):"
  ,----
  | 1  InverseSearchCmdLine = C:\path\to\emacsclient.exe +%l %f
  `----
  Then, "You can execute the search by pressing Alt+DoubleClick in the
  PDF document".


[Texlab official wiki]
<https://github.com/latex-lsp/texlab/wiki/Previewing#inverse-search>


7.3 Examples
~~~~~~~~~~~~

  These examples are according to [Texlab official wiki].  Especially,
  quoted or double-quoted sentences are citation from [Texlab official
  wiki].


[Texlab official wiki]
<https://github.com/latex-lsp/texlab/wiki/Previewing>

7.3.1 SumatraPDF
----------------

        We highly recommend SumatraPDF on Windows because Adobe
        Reader locks the opened PDF file and will therefore
        prevent further builds.


* 7.3.1.1 Forward search

  Write to init.el:
  ,----
  | (setq lsp-latex-forward-search-executable "C:/Users/{User}/AppData/Local/SumatraPDF/SumatraPDF.exe")
  | (setq lsp-latex-forward-search-args '("-reuse-instance" "%p" "-forward-search" "%f" "%l"))
  `----


* 7.3.1.2 Inverse Search

        Add the following line to your [SumatraPDF] settings file
        (Menu -> Settings -> Advanced Options):
  ,----
  | 1  InverseSearchCmdLine = C:\path\to\emacsclient.exe +%l "%f"
  `----
        You can execute the search by pressing `Alt+DoubleClick'
        in the PDF document.


  [SumatraPDF] <https://www.sumatrapdfreader.org/>


7.3.2 Evince
------------

        The SyncTeX feature of [Evince] requires communication via
        D-Bus.  In order to use it from the command line, install
        the [evince-synctex] script.


[Evince] <https://wiki.gnome.org/Apps/Evince>

[evince-synctex] <https://github.com/latex-lsp/evince-synctex>

* 7.3.2.1 Forward search

  Write to init.el:
  ,----
  | (setq lsp-latex-forward-search-executable "evince-synctex")
  | (setq lsp-latex-forward-search-args '("-f" "%l" "%p" "\"emacsclient +%l %f\""))
  `----


* 7.3.2.2 Inverse search

        The inverse search feature is already configured if you
        use `evince-synctex'.  You can execute the search by
        pressing `Ctrl+Click' in the PDF document.


7.3.3 Okular
------------

* 7.3.3.1 Forward search

  Write to init.el:
  ,----
  | (setq lsp-latex-forward-search-executable "okular")
  | (setq lsp-latex-forward-search-args '("--unique" "file:%p#src:%l%f"))
  `----


* 7.3.3.2 Inverse search

        Change the editor of Okular (Settings -> Configure
        Okular... -> Editor) to "Custom Text Editor" and set the
        following command:
  ,----
  | emacsclient +%l "%f"
  `----
  You can execute the search by pressing `Shift+Click' in the PDF
  document.


7.3.4 Zathura
-------------

* 7.3.4.1 Forward search

  Write to init.el:
  ,----
  | (setq lsp-latex-forward-search-executable "zathura")
  | (setq lsp-latex-forward-search-args '("--synctex-forward" "%l:1:%f" "%p"))
  `----


* 7.3.4.2 Inverse search

        Add the following lines to your
        `~/.config/zathura/zathurarc' file:
  ,----
  | 1  set synctex true
  | 2  set synctex-editor-command "emacsclient +%{line} %{input}"
  `----
        You can execute the search by pressing `Alt+Click' in the
        PDF document.


7.3.5 qpdfview
--------------

* 7.3.5.1 Forward search

  Write to init.el:
  ,----
  | (setq lsp-latex-forward-search-executable "qpdfview")
  | (setq lsp-latex-forward-search-args '("--unique" "%p#src:%f:%l:1"))
  `----


* 7.3.5.2 Inverse search

        Change the source editor setting (Edit -> Settings... ->
        Behavior -> Source editor) to:
  ,----
  | 1  emacsclient +%2 "%1"
  `----
        and select a mouse button modifier (Edit -> Settings... ->
        Behavior -> Modifiers -> Mouse button modifiers -> Open in
        Source Editor)of choice.  You can execute the search by
        pressing Modifier+Click in the PDF document.


7.3.6 Skim
----------

        We recommend [Skim] on macOS since it is the only native
        viewer that supports SyncTeX.  Additionally, enable the
        "Reload automatically" setting in the Skim preferences
        (Skim -> Preferences -> Sync -> Check for file changes).


[Skim] <https://skim-app.sourceforge.io/>

* 7.3.6.1 Forward search

  Write to init.el:
  ,----
  | (setq lsp-latex-forward-search-executable "/Applications/Skim.app/Contents/SharedSupport/displayline")
  | (setq lsp-latex-forward-search-args '("%l" "%p" "%f"))
  `----
  "If you want Skim to stay in the background after executing the
  forward search, you can add the `-g' option to"
  `lsp-latex-forward-search-args'.


* 7.3.6.2 Inverse search

  Select Emacs preset "in the Skim preferences (Skim -> Preferences ->
  Sync -> PDF-TeX Sync support).  You can execute the search by pressing
  `Shift+⌘+Click' in the PDF document."


7.3.7 `pdf-tools' integration
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
  Inverse research is not provided by Texlab, so please use
  `pdf-sync-backward-search-mouse'.


8 License
=========

  This package is licensed by GPLv3. See [LICENSE].


[LICENSE] <file:LICENSE>
