This is extension for Flycheck.

If you're want to write code according to the Google C++ Style Guide,
this will help a great deal.
https://google.github.io/styleguide/cppguide.html

I recommend that the package google-c-style also installed with.
https://melpa.org/#/google-c-style

For more infomations, please check the GitHub
https://github.com/flycheck/flycheck-google-cpplint/

;; Setup

(eval-after-load 'flycheck
  '(progn
     (require 'flycheck-google-cpplint)
     ;; Add Google C++ Style checker.
     ;; In default, syntax checked by Clang and Cppcheck.
     (flycheck-add-next-checker 'c/c++-clang
                                'c/c++-googlelint 'append)))
