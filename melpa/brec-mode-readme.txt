  This package introduces a major mode (`brec-mode`) for editing Breccia.
  Breccia is a lightweight markup language for point-form outlining and drafting.
  For more information, see `http://reluk.ca/project/Breccia/`
  and `http://reluk.ca/project/Breccia/Emacs/`.

Installation

  If you install this package from MELPA using a package manager, then already `brec-mode` should
  activate for any `.brec` file you load.  Alternatively you may want to install the mode manually:

      1. Put a copy of `brec-mode.el` on your load path.
         https://www.gnu.org/software/emacs/manual/html_node/elisp/Library-Search.html

      2. Optionally compile that copy.  E.g. load it into an Emacs buffer and type
         `M-x emacs-lisp-byte-compile`.

      3. Add the following code to your initialization file.
         https://www.gnu.org/software/emacs/manual/html_node/emacs/Init-File.html

            (autoload 'brec-mode "brec-mode" nil t)
            (set 'auto-mode-alist (cons (cons "\\.brec\\'" 'brec-mode) auto-mode-alist))

  For a working example of manual installation, see the relevant lines of the file
  `http://reluk.ca/.config/emacs/lisp/initialization.el`.

Bugs

  If you set a `line-spacing` other than zero, then the `line-spacing` will snap back to zero for any
  line that pushes past the right edge of the window, causing the text to bounce in the buffer as you
  edit it.  [http://reluk.ca/project/Breccia/Emacs/working_notes.brec.xht#bounces,whenever,newline]
  The workaround is to zero the `line-spacing` for your Breccia Mode buffers.  For example,
  put this in your intialization file:

     (add-hook 'brec-mode-hook (lambda () (set 'line-spacing 0)))

Customization

  To see a list of customizeable faces, enter a `brec-mode` buffer (or otherwise load `brec-mode`)
  and type `M-x customize-group <RET> brec <RET>`.  Alternatively, look through the `defface`
  definitions in `brec-mode.el`.

  For reference, a working example of customization is available:

      • The author’s `~/.Xresources` — http://reluk.ca/.Xresources
      • Corresponding screen shot — http://reluk.ca/project/Breccia/Emacs/screen_shot.png
