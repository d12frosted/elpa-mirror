  This package implements JMT Mode, a major mode that affords better control
  of Emacs’s Java mode, particularly in regard to syntax highlighting.
  For more information, see `http://reluk.ca/project/Java/Emacs/`.

Installation

  If you installed this package from MELPA using a package manager, then already JMT Mode
  should activate for any loaded file that has either a `.java` extension or `java` shebang.
  Alternatively, you may want to install it manually:

      1. Put a copy of the file `jmt-mode.el` on your load path.
         https://www.gnu.org/software/emacs/manual/html_node/elisp/Library-Search.html

      2. Optionally compile that copy.  Load it into an Emacs buffer, for example,
         and type `M-x emacs-lisp-byte-compile`.

      3. Add the following code to your Emacs initialization file.

            (autoload 'jmt-mode "jmt-mode" nil t)
            (set 'auto-mode-alist (cons (cons "\\.java\\'" 'jmt-mode) auto-mode-alist))
            (set 'interpreter-mode-alist; For Java source-launch files encoded with a shebang. [SLS]
                 (cons (cons "\\(?:--split-string=\\|-S\\)?java" 'jmt-mode)
                       interpreter-mode-alist))
            (register-definition-prefixes "jmt-mode" '("jmt-"))

  For a working example, see the relevant lines of `http://reluk.ca/.config/emacs/initialization.el`.

Customization

  To see a list of customizeable faces, enter a JMT Mode buffer, or otherwise load JMT Mode,
  and type `M-x customize-group <RET> jmt <RET>`.  Alternatively, look through the `defface`
  definitions of file `jmt-mode.el`.

  For a working example, see:

      • The author’s initialization file — http://reluk.ca/.config/emacs/initialization.el
      • The author’s `~/.Xresources` — http://reluk.ca/.Xresources

Changes made to Emacs

  This package applies monkey patches to the runtime session that redefine parts of built-in packages
  CC Mode and Font Lock.  The patches are applied on first entrance to JMT Mode.  Most of them apply
  to function definitions, in which case they are designed to leave the behaviour of Emacs unchanged
  in all buffers except those running JMT Mode.  The patched functions are:

      c-before-change
      c-fontify-recorded-types-and-refs
      c-font-lock-<>-arglists
      c-font-lock-declarations
      c-font-lock-doc-comments
      font-lock-fontify-region-function

  Moreover, one variable is patched:

      javadoc-font-lock-doc-comments - To allow for upper case letters in Javadoc block tags.
