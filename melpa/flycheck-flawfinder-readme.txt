This packages integrates flawfinder with flycheck to automatically check for
possible security weaknesses within your C/C++ code on the fly.

;; Setup

(with-eval-after-load 'flycheck
  (require 'flycheck-flawfinder)
  (flycheck-flawfinder-setup)
  ;; chain after cppcheck since this is the last checker in the upstream
  ;; configuration
  (flycheck-add-next-checker 'c/c++-cppcheck '(warning . flawfinder)))

If you do not use cppcheck then chain after clang / gcc / other C checker
that you use

(flycheck-add-next-checker 'c/c++-clang '(warning . flawfinder))
