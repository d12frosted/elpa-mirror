This program will create a local package repository by from all
installed packages.

Please note compile Emacs Lisp file (*.elc) from one version of Emacs
might not work with another version of Emacs.  So you need this program
to compile package from local repository.

This is the ONLY way to have 100% portable Emacs setup.

Usage in Emacs,
Run `elpamr-create-mirror-for-installed'.

CLI program tar is required.  It's bundled with Windows10/Linux/macOS.

Usage in Shell,
  Emacs --batch -l ~/.emacs.d/init.el
        -l ~/any-directory-you-prefer/elpa-mirror.el \
        --eval='(setq elpamr-default-output-directory "~/myelpa")' \
        --eval='(elpamr-create-mirror-for-installed)

Use the repository created by elpa-mirror,
  - Add `(setq package-archives '(("myelpa" . "~/myelpa/")))` into ~/.emacs
  - Restart Emacs

Tips,
  - `elpamr-exclude-packages' excludes packages

  - `elpamr-tar-command-exclude-patterns' excludes file and directories in
  package directory.

  - `elpamr-exclude-patterns-filter-function' lets users define a function to
    exclude files and directories per package.

    Below setup adds directory "bin/" into package "vagrant-tramp".

    (setq elpamr-exclude-patterns-filter-function
          (lambda (package-dir)
            (let ((patterns elpamr-tar-command-exclude-patterns))
              (when (string-match "vagrant-tramp" package-dir)
                (setq patterns (remove "*/bin" patterns)))
              patterns)))

  - You can also setup repositories on Dropbox and Github.
  See https://github.com/redguardtoo/elpa-mirror for details.
