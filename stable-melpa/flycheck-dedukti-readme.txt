This file defines a flycheck checker based on Dedukti type checker dkcheck.
Dedukti is a type checker for the lambda-Pi-calculus modulo.
It is a free software under the CeCILL-B license.
Dedukti is available at the following url:
<https://www.rocq.inria.fr/deducteam/Dedukti/>
Flycheck is an on-the-fly syntax checker for GNU Emacs 24

; Configuration
To enable this checker in all files visited by dedukti-mode, add
the following code to your Emacs configuration file:

(eval-after-load 'dedukti-mode
  '(add-hook 'dedukti-mode-hook 'flycheck-dedukti-hook))
