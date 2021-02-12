 Set faces for different file types in dired.
 I use a dark background maybe the default face doesn't meet your request.
 You can:
   M-x customize-group dired-filetype-face  RET
 And maybe:
   M-x customize-group dired-faces  RET
 may do some help for you.

; Installation:

Put `dired-filetype-face.el' in your load-path.
Your load-path might include the directory ~/elisp/, for example.
It's set in your ~/.emacs like this:

  (add-to-list 'load-path (expand-file-name "~/elisp"))

Add the following to your ~/.emacs startup file.

  (with-eval-after-load 'dired  (require 'dired-filetype-face))

If you want to add a new face for new filetype(s):

  (deffiletype-face "mytype" "Chartreuse")

then either:

  (deffiletype-face-regexp mytype
    :extensions '("foo" "bar") :type-for-docstring "my type")

to match all files ending either ".foo" or ".bar", or equivalently:

  (deffiletype-face-regexp mytype
    :regexp "^  -.*\\.\\(foo\\|bar\\)$" :type-for-docstring "my type")

and finally:

  (deffiletype-setup "mytype" "mytype")

The :regexp form allows you to specify other things to match on each line of
the dired buffer than (only) file extensions, such as the permission bits,
the size and the modification times.

No need more.
