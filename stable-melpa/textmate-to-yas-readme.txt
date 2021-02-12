
* Importing A Textmate bundle from the Textmate SVN url
This is done with the command `textmate-import-svn-from-url'.
* Importing from an unzipped Textmate tmBundle
This is done with the command `textmate-import-bundle'.  You need to
specify both the root directory of the bundle ant the parent modes for
importing (like text-mode).
*Example function for importing Sata snippets into Yasnippet

*** textmate-import-svn-get-pkgs
=(textmate-import-svn-get-pkgs)=

 - Gets textmate bundles from svn

*** textmate-import-svn-snippets
=(textmate-import-svn-snippets SNIPPET-URL PLIST TEXTMATE-NAME)=

*Imports snippets based on textmate svn tree.

*** textmate-regexp-to-emacs-regexp
=(textmate-regexp-to-emacs-regexp REXP)=

 - Convert a textmate regular expression to an emacs regular expression (as much as possible)

*** textmate-yas-menu
=(textmate-yas-menu PLIST &optional MODE-NAME)=

 - Builds `yas-define-menu'from info.plist file

*** textmate-yas-menu-get-items
=(textmate-yas-menu-get-items TXT)=

Gets items from TXT and puts them into a list

*** yas---t/
=(yas---t/ TEXTMATE-REG TEXTMATE-REP &optional TEXTMATE-OPTION T-TEXT)=

 - Textmate like mirror.  Uses textmate regular expression and textmate formatting.

*** yas-format-match-?-buf
=(yas-format-match-\?-buf TEXT &optional STRING EMPTY-MISSING
START-POINT STOP-POINT)=

 - Recursive call to temporary buffer to replace conditional formats.

*** yas-getenv
=(yas-getenv VAR)=

 - Gets environment variable or customized variable for Textmate->Yasnippet conversion

*** yas-replace-match
=(yas-replace-match TEXT &optional STRING
TREAT-EMPTY-MATCHES-AS-MISSING-MATCHES SUBEXP)=

 - yas-replace-match is similar to emacs replace-match but using Textmate formats

*** yas-text-on-moving-away
=(yas-text-on-moving-away DEFAULT-TEXT)=

 - Changes text when moving away AND original text has not changed

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
