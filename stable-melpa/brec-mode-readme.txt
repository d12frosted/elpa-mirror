  This package implements Brec Mode, a major mode for editing Breccia.
  Breccia is a lightweight markup language for point-form outlining and drafting.
  For more information, see `http://reluk.ca/project/Breccia/`
  and `http://reluk.ca/project/Breccia/Emacs/`.

Installation

  If you installed this package from MELPA using a package manager, then already Brec Mode should
  activate for any `.brec` file you load.  Alternatively, you may want to install it manually:

      1. Put a copy of the file `brec-mode.el` on your load path.
         https://www.gnu.org/software/emacs/manual/html_node/elisp/Library-Search.html

      2. Optionally compile that copy.  Load it into an Emacs buffer, for example,
         and type `M-x emacs-lisp-byte-compile`.

      3. Add the following code to your Emacs initialization file.

            (autoload 'brec-mode "brec-mode" nil t)
            (set 'auto-mode-alist (cons (cons "\\.brec\\'" 'brec-mode) auto-mode-alist))
            (register-definition-prefixes "brec-mode" '("brec-"))

  For a working example, see the relevant lines of `http://reluk.ca/.config/emacs/initialization.el`.

Bugs

  If you set a `line-spacing` other than zero, then the `line-spacing` will snap back to zero for any
  line that pushes past the right edge of the window, causing the text to bounce in the buffer as you
  edit it.  [http://reluk.ca/project/Breccia/Emacs/notes.brec.xht#bounces,whenever,newline]
  The workaround is to zero the `line-spacing` for your Brec Mode buffers.  For example,
  put this in your initialization file:

     (add-hook 'brec-mode-hook (lambda () (setq line-spacing 0)))

Customization

  To see a list of customizeable faces, enter a Brec Mode buffer, or otherwise load Brec Mode,
  and type `M-x customize-group <RET> brec <RET>`.  Alternatively, look through the `defface`
  definitions of file `brec-mode.el`.

  For a working example, see:

      • The author’s initialization file — http://reluk.ca/.config/emacs/initialization.el
      • The author’s `~/.Xresources` — http://reluk.ca/.Xresources
