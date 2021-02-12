This is a major mode for composing gnuplot scripts and displaying
their results using gnuplot. It supports features of recent Gnuplot
versions (5.0 and up), but should also work fine with older
versions.

This version of gnuplot-mode has been tested mostly on GNU Emacs
25.

Gnuplot-mode now includes context-sensitive support for keyword
completion and, optionally, eldoc-mode help text.  See the
commentary in gnuplot-context.el for more information.  If you
don't find it useful, it can be turned off by customizing
`gnuplot-context-sensitive-mode'.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Acknowledgements:
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
