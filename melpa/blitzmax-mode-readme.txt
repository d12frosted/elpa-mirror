This is a major mode for editing BlitzMax files.  It supports syntax
highlighting, keyword capitalization, and automatic indentation.

blitzmax-mode provides the following configuration options:

blitzmax-mode-indent ::
  The number of spaces to indent by.  By default blitzmax-mode indents by 4
  spaces which is converted to a single tab.

blitzmax-mode-capitalize-keywords-p ::
  Disable automatic capitalization of keywords by setting this to =nil=.  =t=
  by default.

blitzmax-mode-smart-indent-p
  Disable smart indentation by setting this to =nil=.  =t= by default.

blitzmax-mode-compiler-pathname
  Full pathname to the BlitzMax compiler bmk.  "bmk" by default.

To enable quickrun integration, add the following code to your Emacs
initialization file.

  (with-eval-after-load 'quickrun
    (blitzmax-mode-quickrun-integration))
