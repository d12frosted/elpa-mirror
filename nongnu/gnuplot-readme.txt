                          ━━━━━━━━━━━━━━━━━━━
                           GNUPLOT FOR EMACS
                          ━━━━━━━━━━━━━━━━━━━


This package allows running [Gnuplot] files from within the [GNU Emacs]
editor. It features:

• Syntax highlighting and indentation for Gnuplot scripts.
• Pull-down menus for common Gnuplot-related tasks.
• Interactive Gnuplot sessions using `comint'.
• Context-sensitive completion.
• Inline display of Gnuplot plots.

It is recommended to use GNU Emacs 28 or above, and Gnuplot version 5.0
or above.


[Gnuplot] <http://www.gnuplot.info/>

[GNU Emacs] <https://www.gnu.org/software/emacs/>


1 Installation
══════════════

  The easiest way to install `gnuplot' is to directly get it from
  [NonGNU ELPA] or [MELPA]. After configuring Emacs to use MELPA, you
  should be able to install `gnuplot' by typing

  ┌────
  │ M-x install-package RET gnuplot RET
  └────


  or do `M-x list-packages' and search for `gnuplot' in the list. Note
  that there is a different [gnuplot-mode] package on MELPA which is
  less featureful.


[NonGNU ELPA] <https://elpa.nongnu.org/>

[MELPA] <http://melpa.org>

[gnuplot-mode] <https://github.com/mkmcc/gnuplot-mode>


2 Configuration
═══════════════

  In order to customize Gnuplot, use `M-x gnuplot-customize' or set the
  respective customizable variables in your user configuration.

  It is recommended to configure `read-extended-command-predicate' in
  your Emacs configuration, such that `M-x' only completes commands
  relevant for the current mode. For example `gnuplot-*' commands are
  only shown in Gnuplot buffers.  Alternatively press the key `M-X'
  instead of `M-x' if you want relevant commands only.

  ┌────
  │ (setq read-extended-command-predicate #'command-completion-default-include-p)
  └────


3 Usage
═══════

  `gnuplot-mode' is enabled automatically for `*.gp' files. These
  functions are useful as entry points:

  • `M-x run-gnuplot' - start `gnuplot-comint-mode' REPL.
  • `M-x gnuplot-mode' - switch to `gnuplot-mode' in the current buffer
  • `M-x gnuplot-make-buffer' - open a new buffer, which is not visiting
    a file, and start `gnuplot-mode' in that buffer.


3.1 Bindings
────────────

  When `gnuplot-mode' is on, the following keybindings are available:

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   `C-c C-l'      send current line to gnuplot                         
   `C-c C-v'      send current line to gnuplot and move forward 1 line 
   `C-c C-r'      send current region to gnuplot                       
   `C-c C-b'      send entire buffer to gnuplot                        
   `C-c C-f'      send a file to gnuplot                               
   `C-c C-i'      insert filename at point                             
   `C-c C-n'      negate set option on current line                    
   `C-c C-c'      comment region                                       
   `C-c C-o'      set arguments for command at point                   
   `S-<mouse-2>'  set arguments for command under mouse cursor         
   `C-c C-d'      read the gnuplot info manual                         
   `C-c C-e'      show gnuplot buffer                                  
   `C-c C-k'      kill gnuplot process                                 
   `C-c C-z'      customize gnuplot-mode                               
   `M-TAB'        complete keyword before point                        
   `TAB'          indent current line                                  
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  With the exception of the commands for sending commands to Gnuplot,
  most of the above commands also work in the Gnuplot comint buffer, in
  addition to the following:

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   `M-C-p'    plot the most recent script buffer line-by-line   
   `M-C-f'    save the current script buffer and load that file 
   `C-c C-e'  pop back to most recent script buffer             
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


3.2 Context-sensitive keyword completion
────────────────────────────────────────

  By default `gnuplot-mode' will try to parse your commands as you type
  and suggest only relevant completion candidates on typing `M-TAB' or
  `TAB'. For example, with point after the `with' of a `plot' command,
  tab completion will suggest only plotting styles. This also enables
  more specific help topic lookup in the Gnuplot info manual.

  If the context-sensitivity annoys you, you can get simple
  non-context-sensitive completion back by toggling
  `gnuplot-context-sensitive-mode'.

  By its nature, the completion code has to know a fair bit about the
  structure of the gnuplot language. If you use it with an outdated
  version of gnuplot it will make mistakes. Most of gnuplot 4.6's
  command language is parsed correctly except for the `set terminal'
  commands.


3.3 Eldoc mode
──────────────

  `gnuplot-mode' shows syntax hints in the modeline when `eldoc-mode' is
  turned on and context sensitivity is enabled. Both are enabled by
  default.


3.4 Inline Images
─────────────────

  Plots are displayed inline in the Gnuplot Comint process buffer. This
  is handy for trying things out without having to switch between Emacs
  and the Gnuplot display. It requires Gnuplot and Emacs to have `png'
  support. Call `gnuplot-external-display-mode' in a gnuplot-mode buffer
  to disable the feature.


4 Common issues
═══════════════

4.1 Usage on Windows
────────────────────

  Multiple users have reported issues when trying to work with
  `gnuplot.el' on Windows. Most notably, the Gnuplot process hangs after
  sending a first line of input (this is a common Emacs issue on
  Windows, see [here]). More information on `gnuplot.el' and Windows can
  be found on these threads [1] and [2]. You currently have two
  solutions:

  1. Experiment using the `gnuplot-program' and `gnuplot-program-args'
     variables. For instance the following setting has been reported to
     work (see [here]).

     ┌────
     │ (setq gnuplot-program "/path/to/cmdproxy.exe"
     │       gnuplot-program-args "/C /path/to/gnuplot.exe")
     └────

  2. Try the simpler [gnuplot-mode] package that sends the entire buffer
     to Gnuplot.  Since no `comint' is involved, it should function
     correctly, but you lose most features of this package.


[here]
<https://www.gnu.org/software/emacs/manual/html_mono/efaq-w32.html#Sub_002dprocesses>

[1] <https://github.com/emacs-gnuplot/gnuplot/issues/15>

[2] <https://github.com/emacs-gnuplot/gnuplot/pull/33>

[here] <https://github.com/emacs-gnuplot/gnuplot/pull/33/files>

[gnuplot-mode] <https://github.com/mkmcc/gnuplot-mode>


4.2 Pause Command
─────────────────

  Gnuplot's `pause -1' command, which waits for the user to press a key,
  is problematic when running under Emacs. Sending `pause -1' to the
  running Gnuplot process will make Emacs appear to freeze. (It isn't
  really crashed: typing `C-g' will unlock it and let you continue). The
  workaround for now is to make Gnuplot output a string before pausing,
  by doing `pause -1 "Hit return"' or similar.


4.3 Issue with Unicode Character Display
────────────────────────────────────────

  Some users have reported [issues when trying to display unicode
  characters]. This issue is likely due to your distribution bundling
  Gnuplot with [editline instead of readline]. Recompiling the source
  with support for Unicode fixes the issue until this issue is fixed
  upstream.


[issues when trying to display unicode characters]
<https://github.com/emacs-gnuplot/gnuplot/issues/39>

[editline instead of readline]
<https://unix.stackexchange.com/questions/496206/unicode-in-gnuplot-terminal/496245#496245>


5 Maintenance of generated files
════════════════════════════════

  The files `gnuplot.texi' and `gnuplot-eldoc.el' are generated from the
  Gnuplot source, which can be obtained from
  <https://packages.debian.org/unstable/gnuplot>.  Run `make' inside the
  `admin' directory to download the source and regenerate the files.
