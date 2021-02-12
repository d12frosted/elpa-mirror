InnoSetup is an Application Installer for Windows
See: http://www.jrsoftware.org/isinfo.php
This version of iss-mode.el is tested with InnoSetup v5.0

iss-mode provides the following features:
* Syntax coloring for InnoSetup scripts
* Integration of the InnoSetup commandline compiler iscc.exe
  - Compilation via M-x iss-compile
  - Jump to compilation error via M-x next-error
* Start Innosetup help via M-x iss-compiler-help
* Test the installation via M-x iss-run-installer

Of course you can bind this commands to keys (e.g. in the iss-mode-hook)

My initialization for InnoSetup looks like this:
(add-to-list 'auto-mode-alist '(("\\.iss$"  . iss-mode)))
(setq iss-compiler-path "c:/Programme/Inno Setup 5/")
(add-hook 'iss-mode-hook 'xsteve-iss-mode-init)
(defun xsteve-iss-mode-init ()
 (interactive)
 (define-key iss-mode-map [f6] 'iss-compile)
 (define-key iss-mode-map [(meta f6)] 'iss-run-installer)))

The latest version of iss-mode.el can be found at:
  http://www.xsteve.at/prg/emacs/iss-mode.el

Comments / suggestions welcome!
