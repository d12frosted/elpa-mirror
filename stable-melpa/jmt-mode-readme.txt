  This package introduces a derived major mode (`jmt-mode`) that offers better control
  of the Java mode built into Emacs, particularly in regard to syntax highlighting.
  For more information, see `http://reluk.ca/project/Java/Emacs/`.

Installation

  If you install this package from MELPA using a package manager, then already `jmt-mode`
  should activate for any loaded file that has either a `.java` extension or `java` shebang.
  Alternatively you may want to install the mode manually:

      1. Put a copy of `jmt-mode.el` on your load path.
         https://www.gnu.org/software/emacs/manual/html_node/elisp/Library-Search.html

      2. Optionally compile that copy.  E.g. load it into an Emacs buffer and type
         `M-x emacs-lisp-byte-compile`.

      3. Add the following code to your initialization file.
         https://www.gnu.org/software/emacs/manual/html_node/emacs/Init-File.html

            (autoload 'jmt-mode "jmt-mode" nil t)
            (set 'auto-mode-alist (cons (cons "\\.java\\'" 'jmt-mode) auto-mode-alist))
            (set 'interpreter-mode-alist
                 (cons (cons "\\(?:--split-string=\\|-S\\)?java" 'jmt-mode)
                       interpreter-mode-alist))

         The `interpreter-mode-alist` entry is for source-launch files encoded with a shebang. [SLS]

  For a working example of manual installation, see the relevant lines of the file
  `http://reluk.ca/.config/emacs/lisp/initialization.el`.

Customization

  To see a list of customizeable faces, enter a `jmt-mode` buffer (or otherwise load `jmt-mode`)
  and type `M-x customize-group <RET> jmt <RET>`.  Alternatively, look through the `defface`
  definitions in `jmt-mode.el`.

  For reference, a working example of customization is available:

      • The author’s `~/.Xresources` — http://reluk.ca/.Xresources
      • Corresponding screen shots:
           Untamed    — http://reluk.ca/project/Java/Emacs/screen_shot/1_before.png
           Tamed      — http://reluk.ca/project/Java/Emacs/screen_shot/2_after.png
           Customized — http://reluk.ca/project/Java/Emacs/screen_shot/3_after_customization.png

Changes made to Emacs

  This package applies monkey patches to the runtime session that redefine parts of built-in packages
  CC Mode and Font Lock.  The patches are applied on first entrance to `jmt-mode`.  Most of them apply
  to function definitions, in which case they are designed to leave the behaviour of Emacs unchanged
  in all buffers except those running `jmt-mode`.  The patched functions are:

      c-before-change
      c-fontify-recorded-types-and-refs
      c-font-lock-<>-arglists
      c-font-lock-declarations
      c-font-lock-doc-comments
      font-lock-fontify-region-function

  Moreover, one variable is patched:

      javadoc-font-lock-doc-comments - To allow for upper case letters in Javadoc block tags.
