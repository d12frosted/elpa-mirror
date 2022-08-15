This package converts graphemes (characters) present in major modes
of your choice to the stylistic ligatures present in your frame's
font.

For this to work, you must meet several criteria:

 1. You must use Emacs 28.1 or later;

    WARNING: Some issues report crash issues with Emacs versions
             Emacs 28.1. This is fixed in an upstream version
             currently only available in the master branch.

 2. Your Emacs must be built with Harfbuzz enabled -- this is the
    default as of Emacs 28.1, but obscure platforms may not support
    it;

 3. You must have a font that supports the particular typographical
    ligature you wish to display.  Emacs should skip the ones it does
    not recognize, however;

 4. Ideally, your Emacs is built with Cairo support.  Without it,
    you may experience issues;

    a. Older versions of Cairo apparently have some
    issues.  `cairo-version-string' should say "1.16.0" or later.


If you have met these criteria, you can now enable ligature support
per major mode.  Why not globally? Well, you may not want ligatures
intended for one thing to display in a major mode intended for
something else.  The other thing to consider is that without this
flexibility, you would be stuck with whatever style categories the
font was built with; in Emacs, you can pick and choose which ones
you like.  Some fonts ship with rather unfashionable ligatures.  With
this package you will have to tell Emacs which ones you want.



GETTING STARTED
---------------

To install this package you should use `use-package', like so:

(use-package ligature
  :config
  ;; Enable the "www" ligature in every possible major mode
  (ligature-set-ligatures 't '("www"))
  ;; Enable traditional ligature support in eww-mode, if the
  ;; `variable-pitch' face supports it
  (ligature-set-ligatures 'eww-mode '("ff" "fi" "ffi"))
  ;; Enable all Cascadia Code ligatures in programming modes
  (ligature-set-ligatures 'prog-mode '("|||>" "<|||" "<==>" "<!--" "####" "~~>" "***" "||=" "||>"
                                       ":::" "::=" "=:=" "===" "==>" "=!=" "=>>" "=<<" "=/=" "!=="
                                       "!!." ">=>" ">>=" ">>>" ">>-" ">->" "->>" "-->" "---" "-<<"
                                       "<~~" "<~>" "<*>" "<||" "<|>" "<$>" "<==" "<=>" "<=<" "<->"
                                       "<--" "<-<" "<<=" "<<-" "<<<" "<+>" "</>" "###" "#_(" "..<"
                                       "..." "+++" "/==" "///" "_|_" "www" "&&" "^=" "~~" "~@" "~="
                                       "~>" "~-" "**" "*>" "*/" "||" "|}" "|]" "|=" "|>" "|-" "{|"
                                       "[|" "]#" "::" ":=" ":>" ":<" "$>" "==" "=>" "!=" "!!" ">:"
                                       ">=" ">>" ">-" "-~" "-|" "->" "--" "-<" "<~" "<*" "<|" "<:"
                                       "<$" "<=" "<>" "<-" "<<" "<+" "</" "#{" "#[" "#:" "#=" "#!"
                                       "##" "#(" "#?" "#_" "%%" ".=" ".-" ".." ".?" "+>" "++" "?:"
                                       "?=" "?." "??" ";;" "/*" "/=" "/>" "//" "__" "~~" "(*" "*)"
                                       "\\\\" "://"))
  ;; Enables ligature checks globally in all buffers.  You can also do it
  ;; per mode with `ligature-mode'.
  (global-ligature-mode t))


EXAMPLES
--------

Map two ligatures in `web-mode' and `html-mode'.  As they are simple
(meaning, they do not require complex regular expressions to ligate
properly) using their simplified string forms is enough:



This example creates regexp ligatures so that `=' matches against
zero-or-more of `=' characters that may or may not optionally end
with `>' or `<'.

(ligature-set-ligatures 'markdown-mode `(("=" ,(rx (+ "=") (? (| ">" "<"))))
                                         ("-" ,(rx (+ "-")))))

LIMITATIONS
-----------

You can only have one character map to a regexp of ligatures that
must apply.  This is partly a limitation of Emacs's
`set-char-table-range' and also of this package.  No attempt is made
to 'merge' groups of regexp.  This is only really going to cause
issues if you rely on multiple mode entries in
`ligature-composition-table' to fulfill all the desired ligatures
you want in a mode, or if you indiscriminately call
`ligature-set-ligatures' against the same collection of modes with
conflicting ligature maps.

OUTSTANDING BUGS
----------------

Yes, most assuredly so.
