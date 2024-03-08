{{{ Introduction

Preface

     This package provides a minor mode, compatible with all major
     editing modes, for folding (hiding) parts of the edited text
     or program.

     Folding mode handles a document as a tree, where each branch
     is bounded by special markers {{{' and }}}'. A branch can be
     placed inside another branch, creating a complete hierarchical
     structure. The markers:

     o   Are placed at the beginning of the line. No spaces.
     o   Are prefixed by mode comment and space as needed.
         For example, in C++ mode, the beginning marker is: "//
         {{{". See the source code of folding.el and the section
         "Set some useful default fold marks" for a full listing of
         the markers. If you need to customize these markers,
         modify `folding-mode-marks-alist' after loading this
         package (See the my-folding-load-hook example in this
         doc).

     Folding mode can CLOSE a fold, leaving only the initial `{{{'
     and possibly a comment visible.

     It can also ENTER a fold, which means that only the current
     fold will be visible; all text above {{{' and below }}}' will
     be invisible.

     Please note that Folding.el is at its best when it can "chunk"
     large sections of code inside folds. The larger the chunks,
     the more the usable folding will be. Folding.el is not meant
     to hide individual functions: you may be better served by
     other packages like hideshow.el or imenu.el (which can parse
     the function indexes).

}}}
{{{ Installation

 Installation

     To install Folding mode, place this file (folding.el) in your
     Emacs `load-path', such as the directory ~/.emacs.d and
     optionally byte compile it with `M-x' `byte-compile'.

The most efficient way to install folding is to use autoload
installation so that folding is loaded only when
`folding-mode' is turned on. Add these statements to your
Emacs init file. See '(info)Init File' for more information.

         (autoload 'folding-mode          "folding" "Folding mode" t)
         (autoload 'turn-off-folding-mode "folding" "Folding mode" t)
         (autoload 'turn-on-folding-mode  "folding" "Folding mode" t)

     If you always use folding, then perhaps you want folding to
     start automatically when you load a folded file:

         (if (load "folding" 'nomessage 'noerror)
             (folding-mode-add-find-file-hook))

     Add also this at the beginning of file:

          -*- mode: emacs-lisp; mode: folding; folded-file: t; -*-

     To activate folding on load without local variables:
