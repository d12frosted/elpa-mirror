This packages integrates the Coverity `cov-run-desktop' Fast Desktop
Analysis tool with flycheck to automatically detect any new defects in your
code on the fly.

;; Setup

(with-eval-after-load 'flycheck
   (require 'flycheck-coverity)
   (flycheck-coverity-setup)
   ;; chain after cppcheck since this is the last checker in the upstream
   ;; configuration
   (flycheck-add-next-checker 'c/c++-cppcheck '(warning . coverity)))

If you do not use cppcheck then chain after clang / gcc / other C checker
that you use

(flycheck-add-next-checker 'c/c++-clang '(warning . coverity))
