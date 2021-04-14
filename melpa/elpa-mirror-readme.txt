This program will create a local package repository by from all
installed packages.

Please note compile Emacs Lisp file (*.elc) from one version of Emacs
might not work with another version of Emacs.  So you need this program
to compile package from local repository.

This is the ONLY way to have 100% portable Emacs setup.

Usage in Emacs,
Run `elpamr-create-mirror-for-installed'.

CLI program tar is required.  It's already installed on Windows10/Linux/macOS.

Usage in Shell,
  Emacs --batch -l ~/.emacs.d/init.el
        -l ~/any-directory-you-prefer/elpa-mirror.el \
        --eval='(setq elpamr-default-output-directory "~/myelpa")' \
        --eval='(elpamr-create-mirror-for-installed)

Use the repository created by elpa-mirror,
  - Insert `(setq package-archives '(("myelpa" . "~/myelpa/")))` into ~/.emacs
  - Restart Emacs

Tips,
  - `elpamr-exclude-packages' excludes packages
  - `elpamr-tar-command-exclude-patterns' excludes file and directories in
  package directory.
  - You can also setup repositories on Dropbox and Github.
  See https://github.com/redguardtoo/elpa-mirror for details.
