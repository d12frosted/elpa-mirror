latex-math-preview creates images of particular region in LaTeX file
and display them in emacs.
latex-math-preview has the following main commands.

M-x `latex-math-preview-expression' previews a mathematical expression pointed
by the cursor in LaTeX files or strings of selected region with transient-mark on.
The result of this command is shown as an image in a popped-up buffer.

M-x `latex-math-preview-insert-symbol' displays the list of LaTeX symbols.
Selecting a LaTeX symbol in the list, you can insert it to a LaTeX file.
Depending on whether the cursor is in a mathematical expression or not,
this command shows an appropriate symbol list.
If you don't want to use the automatic mode selection of symbol list,
alternatively you may use M-x `latex-math-preview-insert-mathematical-symbol'
for mathematical symbols and M-x `latex-math-preview-insert-text-symbol'
and normal text symbols.

M-x `latex-math-preview-save-image-file' makes an image for the same target
as `latex-math-preview-expression' and save it as a file which is png or eps.
When making an image, this command may remove automatically
numberings of mathematical formulas.

latex-math-preview.el automatically search \usepackage in the current buffer
and set the values to the buffer local variable `latex-math-preview-usepackage-cache'.
This values of \usepackage is used to create preview images.
When you add new \usepackage lines, to reload the variable `latex-math-preview-usepackage-cache'.
you can use M-x `latex-math-preview-reload-usepackage'.
If LaTeX source is splitted to multiple files and the current buffer does not include \usepackage lines,
you execute C-u M-x `latex-math-preview-reload-usepackage' and select the file including \usepackage lines.

There are \usepackage lines that are not appropriate to create preview images.
You can also filter such \usepackage lines. The variable `latex-math-preview-usepackage-filter-alist'
is the list of ignored \usepackage lines.
The values of the list `latex-math-preview-usepackage-filter-alist' are
(REGEXP) or (REGEXP . (lambda (line) SOME PROCESSES)).
For the former, matched \usepackage lines are ignored.
For the latter, if the evaluation of the lambda expression is nil
then matched \usepackage lines are ignored
and if the evaluation returns string then the string is added to
the variable `latex-math-preview-usepackage-cache'.

If the automatic search of \usepackage lines does not work,
you can edit directly the variable `latex-math-preview-usepackage-cache'.
To do so, you execute M-x `latex-math-preview-edit-usepackage'.

M-x `latex-math-preview-beamer-frame' makes an image of one frame of beamer,
which is a LaTeX style for presentation.

* Requirements
Because latex-math-preview displays png images in emacs,
it is not work in emacs on terminal, i.e., latex-math-preview needs emacs on X Window System.

** Version of Emacs
latex-math-preview works probably on emacs with the version larger than 22.
The author tested latex-math-preview on Emacs 24.2.1 and Ubuntu 13.04.
Previously, the author confirmed latex-math-preview had no problem on Meadow 3 and Windows XP.

** Image Conversion
latex-math-preview uses some commands to convert tex to png, tex to eps, and so on.
Only for previewing mathematical expressions, latex-math-preview requires
latex and dvipng commands.
According to your environment and your settings of latex-math-preview,
latex-math-preview creates preview images by combining the following commands.

 - dvipng
 - dvips
 - latex
 - platex
 - pdflatex
 - lualatex
 - dvipdf
 - dvipdfm
 - dvipdfmx
 - gs

* Install of Emacs Lisp
** Load latex-math-preview
Put latex-math-preview.el to your load-path of Emacs and
write the following code in ~/.emacs.el.

  (autoload 'latex-math-preview-expression "latex-math-preview" nil t)
  (autoload 'latex-math-preview-insert-symbol "latex-math-preview" nil t)
  (autoload 'latex-math-preview-save-image-file "latex-math-preview" nil t)
  (autoload 'latex-math-preview-beamer-frame "latex-math-preview" nil t)

** Key Bindings
Please set key bindings of your TeX mode if desired.

For example, for YaTeX mode we add the following settings to ~/.emacs.el.

  (add-hook 'yatex-mode-hook
           '(lambda ()
           (YaTeX-define-key "p" 'latex-math-preview-expression)
           (YaTeX-define-key "\C-p" 'latex-math-preview-save-image-file)
           (YaTeX-define-key "j" 'latex-math-preview-insert-symbol)
           (YaTeX-define-key "\C-j" 'latex-math-preview-last-symbol-again)
           (YaTeX-define-key "\C-b" 'latex-math-preview-beamer-frame)))
  (setq latex-math-preview-in-math-mode-p-func 'YaTeX-in-math-mode-p)

This settings uses yatex-specific key binding function `YaTeX-define-key' and
usually binds `latex-math-preview-expression' to "C-c p",
`latex-math-preview-save-image-file' to "C-c C-p",
`latex-math-preview-insert-symbol' to "C-c j",
`latex-math-preview-last-symbol-again' to "C-c C-j",
and `latex-math-preview-beamer-frame' to "C-c C-b".

The last line of the settings for yatex-mode is the function
to distinguish mathematical expressions from normal text.
In yatex-mode the function `YaTeX-in-math-mode-p alternatively' is bettern than
the function `latex-math-preview-in-math-mode-p'.
Therefore, the author recommend that you set the function `YaTeX-in-math-mode-p'
to the variable `latex-math-preview-in-math-mode-p-func'.

Of course, in the other major mode to edit latex files, you use local-set-key to define key bindings.

  (add-hook 'latex-mode-hook
           '(lambda ()
           (local-set-key "\C-cp" 'latex-math-preview-expression)))

** Paths of Programs
latex-math-preview.el uses the commands 'latex', 'dvipng', 'dvips', and so on.
If these commands are not in the load paths of system or
you want to use the different commands from ones of system default,
you need to set the variable `latex-math-preview-command-path-alist'.
For example, you can set the variable as the following:

   (setq latex-math-preview-command-path-alist
         '((latex . "/usr/bin/latex") (dvipng . "/usr/bin/dvipng") (dvips . "/usr/bin/dvips")))

* Usage
** latex-math-preview-expression
If you type M-x `latex-math-preview-expression', a buffer including a preview image pops up.
If the cursor points to a mathematical expression, we can preview the expression.
If a region is selected with transient-mark on, i.e., with usually backgroud-color changed,
we can preview the selected resion.

In the preview buffer, the following binded key is available:
 q: exit window of preview buffer
 Q: delete preview buffer (the behavior is almost same as pressing 'q')
 j: scroll up preview buffer
 k: scroll down preview buffer
 o: maximize window of preview buffer

** latex-math-preview-insert-symbol
You can insert a LaTeX symbol from the list of symbols if you type
M-x `latex-math-preview-insert-symbol'.
In the buffer you can select the symbol pointed by the current cursor by pressing RET.
Key bindings are displayed in the top of the preview buffer.

The images of the symbols are cached in the directory
set by `latex-math-preview-cache-directory-for-insertion'.
If the cache does not exist, you need to wait for finishing making the images for a while.
M-x `latex-math-preview-make-all-cache-images' makes the cache and
M-x `latex-math-preview-clear-cache-for-insertion' delete the cache.

M-x `latex-math-preview-insert-symbol' shows the page last opened.
C-u M-x `latex-math-preview-insert-symbol' asks you the page that you want to open.
M-x `latex-math-preview-last-symbol-again' insert the last inserted symbol.
Inside `latex-math-preview-insert-symbol',
`latex-math-preview-mathematical-symbol-datasets' or `latex-math-preview-insert-text-symbol'
is executed according to the point of the cursor.
If you want to display the list of symbols without dependency on the cursor,
you can use `latex-math-preview-mathematical-symbol-datasets' or
`latex-math-preview-insert-text-symbol' directly.

** latex-math-preview-save-image-file
While `latex-math-preview-expression' displays an images in a buffer,
you can save the images as files.
If you type M-x `latex-math-preview-save-image-file', you are asked
about path of an outputted image.
You must input the path of which extention is 'png' or 'eps'.

** latex-math-preview-beamer-frame
If we type M-x `latex-math-preview-beamer-frame'
with the cursor in \frame{ ... } or \begin{frame} ... \end{frame},
we can preview the page of beamer presentation
same as `latex-math-preview-expression'.

* Settings
** LaTeX template
latex-math-preview.el makes a temporary LaTeX file and convert it to an image
by the commands 'latex', 'dvipng', and so on.
The structure of a temporary latex file is the following.
-------------------------------------------------------------------
  (part of `latex-math-preview-latex-template-header'
   the default value is the following)
  \documentclass{article}
  \pagestyle{empty}

  (part of usepackages
   the values of \usepackage searched from current buffer or
   `latex-math-preview-latex-usepackage-for-not-tex-file')

  \begin{document}
  (some mathematical expressions)
  \par
  \end{document}
-------------------------------------------------------------------

If you want to change the header in the temporary latex files,
you set the customized value to the variable `latex-math-preview-latex-template-header'.
latex-math-preview searches '\usepackage' in the current buffer and
uses its value when making LaTeX files.
But when there is no '\usepackage' strings, alternatively
the variable `latex-math-preview-latex-usepackage-for-not-tex-file' is used.
So you can set your prefered value to
the variable `latex-math-preview-latex-usepackage-for-not-tex-file'.
When we save image files, the variable `latex-math-preview-template-header-for-save-image' is used.

** Conversion Process
The default value of the variable `latex-math-preview-tex-to-png-for-preview' is

  (defvar latex-math-preview-tex-to-png-for-preview
   '(latex dvipng))

This means that to create png images latex-math-preview uses
`latex-math-preview-execute-latex' (tex to dvi) and
`latex-math-preview-execute-dvipng' (dvi to png) in series.
If you use other programs to create png images, please edit this variable.
For example, to use platex (tex to dvi), dvipdfmx (dvi to pdf), and gs (pdf to png),

  (defvar latex-math-preview-tex-to-png-for-preview
   '(platex dvipdfmx gs-to-png))

The variables `latex-math-preview-tex-to-png-for-save', `latex-math-preview-tex-to-eps-for-save',
`latex-math-preview-tex-to-ps-for-save', and `latex-math-preview-beamer-to-png' is similar.
The prepared functions we can uses to convert images are
 - `latex-math-preview-execute-latex'
 - `latex-math-preview-execute-platex'
 - `latex-math-preview-execute-pdflatex-to-dvi'
 - `latex-math-preview-execute-pdflatex-to-pdf'
 - `latex-math-preview-execute-lualatex-to-dvi'
 - `latex-math-preview-execute-lualatex-to-pdf'
 - `latex-math-preview-execute-dvipdf'
 - `latex-math-preview-execute-dvipdfm'
 - `latex-math-preview-execute-dvipdfmx'
 - `latex-math-preview-execute-dvipng'
 - `latex-math-preview-execute-dvips-to-ps'
 - `latex-math-preview-execute-dvips-to-eps'
 - `latex-math-preview-execute-gs-to-png'

For example, we recommend the following settings to Japanese users, i.e., platex command's user:
   (setq-default latex-math-preview-tex-to-png-for-preview '(platex dvipng))
   (setq-default latex-math-preview-tex-to-png-for-save '(platex dvipng))
   (setq-default latex-math-preview-tex-to-eps-for-save '(platex dvips-to-eps))
   (setq-default latex-math-preview-tex-to-ps-for-save '(platex dvips-to-ps))
   (setq-default latex-math-preview-beamer-to-png '(platex dvipdfmx gs-to-png))

** Options of Commands
The options of the commands are specified by
the variable `latex-math-preview-command-option-alist' and
the options for triming margins of images are specified
by teh variable `latex-math-preview-command-trim-option-alist'.
If you configure the commands, please modify these variables.
Because this customize is advanced, the author want you to refer to the source code for details.

The color options of the command 'dvipng' is determined by
`latex-math-preview-image-foreground-color' and
`latex-math-preview-image-background-color', which define
the foreground and background colors of png images respectively.
If these variables are nil, these colors are the same as these of the default face.

** Matching mathematical expression
When you execute the function `latex-math-preview-expression',
the default settings support the following LaTeX mathematical expressions.
 $ ... $
 $$ ... $$
 \[ ... \]
 \begin{math} ... \end{math}
 \begin{displaymath} ... \end{displaymath}
 \begin{equation} ... \end{equation}
 \begin{gather} ... \end{gather}
 \begin{align} ... \end{align}
 \begin{alignat} ... \end{alignat}

If you want to preview other LaTeX mathematical expressions,
please add settings to match them to the variable `latex-math-preview-match-expression'.

** List of symbols for insertion
To change symbol set, you may customize the variable
`latex-math-preview-mathematical-symbol-datasets'.
The preview buffer of symbol list is popped up with the last opend page.
If you always open the same inital page,
you set nil to the `latex-math-preview-restore-last-page-of-symbol-list'
and the string of the initial page name to
the variable `latex-math-preview-initial-page-of-symbol-list'.

This program keep the created images as cache.
These images saved in the variable `latex-math-preview-cache-directory-for-insertion'
of which default value is "~/.emacs.d/latex-math-preview-cache".
If you change the cache directory, please customize this variable.
