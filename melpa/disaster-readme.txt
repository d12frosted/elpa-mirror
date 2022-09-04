![Screenshot of a C example](screenshot-c.png)

![Screenshot of a Fortran example](screenshot-fortran.png)

Disaster lets you press `C-c d` to see the compiled assembly code for the
C, C++ or Fortran file you're currently editing. It even jumps to and
highlights the line of assembly corresponding to the line beneath your cursor.

It works by creating a `.o` file using `make` (if you have a Makefile), or
`cmake` (if you have a `compile_commands.json` file) or the default system
compiler. It then runs that file through `objdump` to generate the
human-readable assembly.

; Installation:

Make sure to place `disaster.el` somewhere in the `load-path`, then you should
be able to run `M-x disaster`. If you want, you add the following lines to
your `.emacs` file to register the `C-c d` shortcut for invoking `disaster`:

```elisp
(add-to-list 'load-path "/PATH/TO/DISASTER")
(require 'disaster)
(define-key c-mode-map (kbd "C-c d") 'disaster)
(define-key fortran-mode-map (kbd "C-c d") 'disaster)
```

#### Doom Emacs

For Doom Emacs users, you can add this snippet to your `packages.el`.

```elisp
(package! disaster
  :recipe (:host github :repo "jart/disaster"))
```

And this to your `config.el`:

```elisp
(use-package! disaster
  :commands (disaster)
  :init
  ;; If you prefer viewing assembly code in `nasm-mode` instead of `asm-mode`
  (setq disaster-assembly-mode 'nasm-mode)

  (map! :localleader
        :map (c++-mode-map c-mode-map fortran-mode-map)
        :desc "Disaster" "d" #'disaster))
```
