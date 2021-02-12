This package provide a semantic way of using tab characters in
source code: tabs for indentation, spaces for alignment.

It is derived from <http://www.emacswiki.org/emacs/SmartTabs>
with modifications by the various authors listed above.

Modification history is at <https://github.com/jcsalomon/smarttabs>.

; Installation:

The easiest and preferred way to install smart-tabs-mode is to use
the package available on MELPA.

Manual installation:

Save smart-tabs-mode.el to a a directory on your load-path
(e.g., ~/.emacs.d/elisp), then add the following to your .emacs file:

 (autoload 'smart-tabs-mode "smart-tabs-mode"
   "Intelligently indent with tabs, align with spaces!")
 (autoload 'smart-tabs-mode-enable "smart-tabs-mode")
 (autoload 'smart-tabs-advice "smart-tabs-mode")
 (autoload 'smart-tabs-insinuate "smart-tabs-mode")


; Enabling smart-tabs-mode within language modes:

As of version 1.0 of this package, the easiest and preferred way to
enable smart-tabs-mode is with the smart-tabs-insinuate function;
for example,

 (smart-tabs-insinuate 'c 'c++ 'java 'javascript 'cperl 'python
                       'ruby 'nxml)

will enable smart-tabs-mode with all supported language modes.

(See below for instructions on adding additional language support.)

The old method of manually enabling smart-tabs-mode is still
available, but is no longer recommended; smart-tabs-insinuate
wraps the functionality below in a convenient manner.

For reference, the basic manual method looks like this:

 (add-hook 'MODE-HOOK 'smart-tabs-mode-enable)
 (smart-tabs-advice INDENT-FUNC TAB-WIDTH-VAR)

Note that it might be preferable to delay calling smart-tabs-advice
until after the major mode is loaded and evaluated, so the lines
above would be better written like this:

 (add-hook 'MODE-HOOK (lambda ()
                        (smart-tabs-mode-enable)
                        (smart-tabs-advice INDENT-FUNC TAB-WIDTH-VAR)))

Here are some specific examples for a few popular languages:

 ;; C
 (add-hook 'c-mode-hook 'smart-tabs-mode-enable)
 (smart-tabs-advice c-indent-line c-basic-offset)
 (smart-tabs-advice c-indent-region c-basic-offset)

 ;; JavaScript
 (add-hook 'js2-mode-hook 'smart-tabs-mode-enable)
 (smart-tabs-advice js2-indent-line js2-basic-offset)

 ;; Perl (cperl-mode)
 (add-hook 'cperl-mode-hook 'smart-tabs-mode-enable)
 (smart-tabs-advice cperl-indent-line cperl-indent-level)

 ;; Python
 (add-hook 'python-mode-hook 'smart-tabs-mode-enable)
 (smart-tabs-advice python-indent-line-1 python-indent)

; Adding language support

Language support can be added through the use of the macro
`smart-tabs-add-language-support'. Pass in the symbol you wish
to use to identify the language, the mode hook, and a list
of cons cells containing (indent-line-function . offset-variable).
For example, if C++ mode was not provided by default it could be
added as follows:

(smart-tabs-add-language-support c++ c++-mode-hook
  ((c-indent-line . c-basic-offset)
   (c-indent-region . c-basic-offset)))

NOTE: All language support must be added before the call to
     `smart-tabs-insinuate'.
