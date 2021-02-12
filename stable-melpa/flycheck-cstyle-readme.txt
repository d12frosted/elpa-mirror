This packages integrates cstyle with flycheck to automatically check the
style of your C/C++ code on the fly.

;; Setup

(eval-after-load 'flycheck
  '(progn
     (require 'flycheck-cstyle)
     (flycheck-cstyle-setup)
     ;; chain after cppcheck since this is the last checker in the upstream
     ;; configuration
     (flycheck-add-next-checker 'c/c++-cppcheck '(warning . cstyle))))

If you do not use cppcheck then chain after clang / gcc / other C checker
that you use

(flycheck-add-next-checker 'c/c++-clang '(warning . cstyle))
