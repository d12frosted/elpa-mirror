This packages integrates plantuml with flycheck to automatically check the
syntax of your plantuml files on the fly

;; Setup

(with-eval-after-load 'flycheck
  (require 'flycheck-plantuml)
  (flycheck-plantuml-setup))
