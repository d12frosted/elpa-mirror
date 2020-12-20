This is a major mode for composing gnuplot scripts and displaying
their results using gnuplot.  It supports features of recent
Gnuplot versions (4.4 and up), but should also work fine with older
versions.

This version of gnuplot-mode has been tested mostly on GNU Emacs
25.


This mode offers several tools to help you compose your scripts,
including font-lock syntax colorization, a syntax table appropriate
to gnuplot, key bindings, pull-down menus, indentation, keyword
completions and variable customization using the Custom package.
Once the script is composed, there are several function for sending
some or all of the script to gnuplot.  The interaction with the
gnuplot process is within a comint buffer.  Plots can optionally be
displayed within Emacs.

   C-c C-l       send current line to gnuplot
   C-c C-v       send current line to gnuplot and move forward 1 line
   C-c C-r       send current region to gnuplot
   C-c C-b       send entire buffer to gnuplot
   C-c C-f       send a file to gnuplot
   C-c C-i       insert filename at point
   C-c C-n       negate set option on current line
   C-c C-c       comment region
   C-c C-o       set arguments for command at point
  S-mouse-2      set arguments for command under mouse cursor
   C-c C-d       read the gnuplot info file
   C-c C-e       show-gnuplot-buffer
   C-c C-k       kill gnuplot process
   C-c C-u       submit a bug report about gnuplot-mode
   C-c C-z       customize gnuplot-mode
M-tab or M-ret   complete keyword before point
     ret         newline and indent
     tab         indent current line
   C-c M-i       toggle inline plot display in comint buffer

With the exception of the commands for sending commands to Gnuplot,
most of the above commands also work in the Gnuplot comint buffer,
in addition to the following:
    M-C-p        plot the most recent script buffer line-by-line
    M-C-f        save the current script buffer and load that file
   C-c C-e       pop back to most recent script buffer

These two functions are useful for starting up gnuplot-mode:

M-x gnuplot-mode
        start gnuplot-mode in the current buffer

M-x gnuplot-make-buffer
        open a new buffer (which is not visiting a file) and start
        gnuplot-mode in that buffer

Gnuplot-mode now includes context-sensitive support for keyword
completion and, optionally, eldoc-mode help text.  See the
commentary in gnuplot-context.el for more information.  If you
don't find it useful, it can be turned off by customizing
`gnuplot-context-sensitive-mode'.


---------------------------------------------------------------------

Other Lisp files used by gnuplot.el

gnuplot-gui.el (written by Bruce):
  Defines the GUI interface for setting setting arguments to
  gnuplot options.  This uses the widget package extensively.

gnuplot-context.el (written by Jonathan, j.j.oddie@gmail.com)
  Context-sensitive completion, help lookup and eldoc
  strings for gnuplot buffers.  Should be byte-compiled before
  using.

---------------------------------------------------------------------

This mode was inspired by the original gnu-plot-mode by Gershon
Elber, which is distributed with gnuplot itself and which dates
back to the early 90's.  Although this mode encompasses the
functionality of the original, the two share no code and the
current implementation takes advantage of many features of modern
versions of Emacs and adheres (or so I intend) to the major mode
conventions described in the emacs-lisp reference for version 19
and later.

---------------------------------------------------------------------

                        Installation
                        ============

A recent version of this file can be found at
  https://github.com/emacsorphanage/gnuplot/

To autoload gnuplot-mode on any file with gp extension, put this in
your .emacs file
  (autoload 'gnuplot-mode "gnuplot" "gnuplot major mode" t)
  (autoload 'gnuplot-make-buffer "gnuplot" "open a buffer in gnuplot-mode" t)

Something like
  (setq auto-mode-alist (append '(("\\.gp$" . gnuplot-mode))
                                auto-mode-alist))
is useful for having files ending in .gp start up in gnuplot-mode.

Something like
  (global-set-key [(f9)] 'gnuplot-make-buffer)
may be useful.  This binds f9 to the function that opens a scratch
buffer (i.e. one that is not visiting a file) in gnuplot-mode.
This is handy for your quick 'n' dirty plotting chores.

To use the `gnuplot-info-lookup-symbol' function, the file
gnuplot.info MUST be installed somewhere that info can find it.
This means you must either:
  1.  Copy gnuplot.info to the normal info directory or
  2.  Make sure info can find gnuplot.info by putting this in your
      .emacs file:
        (setenv "INFOPATH"
           (concat (getenv "INFOPATH") ":"
                   (expand-file-name "/path/to/file")))
      where "/path/to/file" is the location of gnuplot.info






Acknowledgements:
   David Batty       <DB> (numerous corrections)
   Laurent Bonnaud   <LB> (suggestions regarding font-lock rules)
   Markus Dickebohm  <MD> (suggested `gnuplot-send-line-and-forward')
   Stephen Eglan     <SE> (suggested the use of info-look,
                           contributed a bug fix regarding shutting
                           down the gnuplot process, improvement to
                           `gnuplot-send-line-and-forward')
   Robert Fenk       <RF> (suggested respecting continuation lines)
   Michael Karbach   <MK> (suggested trimming the gnuplot process buffer)
   Alex Chan Libchen <AL> (suggested font-lock for plotting words)
   Kuang-Yu Liu      <KL> (pointed out buggy dependence on font-lock)
   Hrvoje Niksic     <HN> (help with defcustom arguments for insertions)
   Andreas Rechtsteiner <AR> (pointed out problem with C-c C-v)
   Michael Sanders   <MS> (help with the info-look interface)
   Jinwei Shen       <JS> (suggested functionality in comint buffer)
   Michael M. Tung   <MT> (prompted me to add pm3d support)
   Holger Wenzel     <HW> (suggested using `gnuplot-keywords-when')
   Wolfgang Zocher   <WZ> (pointed out problem with gnuplot-mode + speedbar)
   Jon Oddie         <jjo> (indentation, inline images, context mode)
   Maxime F. Treca   <MFT> (package update, XEmacs deprecation)

 and especially to Lars Hecking <LH> for including gnuplot-mode
 with the gnuplot 3.7-beta distribution and for providing me with
 installation materials
